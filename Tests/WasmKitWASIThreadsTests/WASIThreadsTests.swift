#if os(macOS) || os(Linux)
    import Foundation
    import Synchronization
    import Testing
    import WAT
    import WasmKit
    import WasmKitWASIThreads

    private final class SendableFunction: @unchecked Sendable {
        let value: Function

        init(_ value: Function) {
            self.value = value
        }
    }

    @Suite(.enabled(if: Engine().configuration.memoryBoundsChecking == .mprotect)) struct WASIThreadsTests {
        @Test func configurationDefaults() {
            let configuration = WASIThreadsConfiguration()
            #expect(configuration.maximumThreads == 64)
            #expect(configuration.nativeStackSize == nil)
        }

        @Test func sharedMemoryIsVisibleAcrossStoreLocalWrappers() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let shared = try SharedMemory(
                engine: engine, type: .init(min: 1, max: 2, shared: true), resourceLimiter: DefaultResourceLimiter()
            )
            let first = Memory(store: Store(engine: engine), sharedMemory: shared)
            let second = Memory(store: Store(engine: engine), sharedMemory: shared)
            first.withUnsafeMutableBufferPointer(offset: 0, count: 1) { $0[0] = 42 }
            let value = second.withUnsafeBufferPointer(offset: 0, count: 1) { $0[0] }
            #expect(value == 42)

            #expect(try shared.grow(by: 1) == 1)
            #expect(first.byteCount == 2 * 65_536)
            #expect(second.byteCount == 2 * 65_536)
            second.withUnsafeMutableBufferPointer(offset: 65_536, count: 1) { $0[0] = 24 }
            #expect(first.withUnsafeBufferPointer(offset: 65_536, count: 1) { $0[0] } == 24)
        }

        @Test func sharedMemoryAtomicWaitAndNotifyCrossStoreBoundaries() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let shared = try SharedMemory(
                engine: engine, type: .init(min: 1, max: 1, shared: true), resourceLimiter: DefaultResourceLimiter()
            )
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (import "env" "memory" (memory 1 1 shared))
                      (func (export "wait") (result i32)
                        (memory.atomic.wait32 (i32.const 0) (i32.const 0) (i64.const 1000000000)))
                      (func (export "notify") (result i32)
                        (memory.atomic.notify (i32.const 0) (i32.const 1)))
                    )
                    """, features: [.threads]
                ), features: [.threads])
            let waitStore = Store(engine: engine)
            let notifyStore = Store(engine: engine)
            let waitInstance = try module.instantiate(
                store: waitStore,
                imports: ["env": ["memory": Memory(store: waitStore, sharedMemory: shared)]]
            )
            let notifyInstance = try module.instantiate(
                store: notifyStore,
                imports: ["env": ["memory": Memory(store: notifyStore, sharedMemory: shared)]]
            )
            let wait = SendableFunction(try #require(waitInstance.exports[function: "wait"]))
            let notify = try #require(notifyInstance.exports[function: "notify"])
            let outcome = Mutex<UInt32?>(nil)

            Thread.detachNewThread {
                let result = try? wait.value([])
                outcome.withLock { $0 = result?.first?.i32 }
            }

            let deadline = Date().addingTimeInterval(1)
            var woken: UInt32 = 0
            while Date() < deadline && woken == 0 {
                woken = try notify([]).first?.i32 ?? 0
                if woken == 0 { Thread.sleep(forTimeInterval: 0.001) }
            }
            #expect(woken == 1)

            var result: UInt32?
            while Date() < deadline {
                result = outcome.withLock { $0 }
                if result != nil { break }
                Thread.sleep(forTimeInterval: 0.001)
            }
            #expect(result == 0)
        }

        @Test func spawnEntersChildInstanceAndSharesMemory() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (import "env" "memory" (memory 1 1 shared))
                      (import "wasi" "thread-spawn" (func $spawn (param i32) (result i32)))
                      (func (export "wasi_thread_start") (param i32 i32)
                        (i32.atomic.store (i32.const 0) (local.get 1)))
                      (func (export "run") (result i32)
                        (call $spawn (i32.const 42)))
                    )
                    """,
                    features: [.threads]
                ), features: [.threads])
            let threads = try WASIThreads(
                module: module,
                engine: engine,
                processControl: .init(
                    terminateAfterMainReturn: { _ in fatalError("not reached") },
                    terminateAfterWorkerFailure: { error in fatalError("unexpected worker failure: \(error)") }
                ),
                childImports: { _ in Imports() }
            )
            let store = Store(engine: engine)
            let imports = try threads.makeImports(store: store)
            let instance = try module.instantiate(store: store, imports: imports)
            let run = try #require(instance.exports[function: "run"])
            #expect(try run() == [.i32(1)])

            let deadline = Date().addingTimeInterval(1)
            var result: UInt32 = 0
            while Date() < deadline {
                result =
                    threads.sharedMemory.byteCount > 0
                    ? Memory(store: store, sharedMemory: threads.sharedMemory).withUnsafeBufferPointer(offset: 0, count: 4) {
                        $0.baseAddress!.assumingMemoryBound(to: Atomic<UInt32>.self).pointee.load(ordering: .acquiring)
                    }
                    : 0
                if result == 42 { break }
                Thread.sleep(forTimeInterval: 0.001)
            }
            #expect(result == 42)
        }

        @Test func normalWorkersReleaseTheirLiveSlots() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (import "env" "memory" (memory 1 1 shared))
                      (import "wasi" "thread-spawn" (func $spawn (param i32) (result i32)))
                      (func (export "wasi_thread_start") (param i32 i32)
                        (drop (i32.atomic.rmw.add (i32.const 0) (i32.const 1))))
                      (func (export "run") (result i32) (call $spawn (i32.const 0)))
                    )
                    """,
                    features: [.threads]
                ), features: [.threads])
            let threads = try WASIThreads(
                module: module, engine: engine,
                configuration: .init(maximumThreads: 2),
                processControl: .init(
                    terminateAfterMainReturn: { _ in fatalError("not reached") },
                    terminateAfterWorkerFailure: { error in fatalError("unexpected worker failure: \(error)") }
                ), childImports: { _ in Imports() }
            )
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store, imports: threads.makeImports(store: store))
            let run = try #require(instance.exports[function: "run"])
            let memory = Memory(store: store, sharedMemory: threads.sharedMemory)

            for expected in 1...32 {
                let deadline = Date().addingTimeInterval(1)
                var tid = UInt32.max
                while Date() < deadline {
                    tid = try run().first?.i32 ?? UInt32.max
                    if tid != UInt32.max { break }
                    // A normal worker can return between its guest call completing
                    // and its detached pthread releasing the live-thread slot.
                    Thread.sleep(forTimeInterval: 0.001)
                }
                #expect(tid == UInt32(expected))

                var count: UInt32 = 0
                while Date() < deadline {
                    count = memory.withUnsafeBufferPointer(offset: 0, count: 4) {
                        $0.baseAddress!.assumingMemoryBound(to: Atomic<UInt32>.self).pointee.load(ordering: .acquiring)
                    }
                    if count == expected { break }
                    Thread.sleep(forTimeInterval: 0.001)
                }
                #expect(count == expected)
            }
        }

        @Test func missingOrIncompatibleEntryReturnsNegativeOne() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (import "env" "memory" (memory 1 1 shared))
                      (import "wasi" "thread-spawn" (func $spawn (param i32) (result i32)))
                      (func (export "wasi_thread_start") (param i32))
                      (func (export "run") (result i32) (call $spawn (i32.const 0)))
                    )
                    """, features: [.threads]
                ), features: [.threads])
            let threads = try WASIThreads(
                module: module, engine: engine,
                processControl: .init(
                    terminateAfterMainReturn: { _ in fatalError("not reached") },
                    terminateAfterWorkerFailure: { error in fatalError("unexpected worker failure: \(error)") }
                ), childImports: { _ in Imports() }
            )
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store, imports: threads.makeImports(store: store))
            let run = try #require(instance.exports[function: "run"])
            #expect(try run() == [.i32(UInt32.max)])
        }

        @Test func mainThreadConsumesTheOnlyLiveSlot() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (import "env" "memory" (memory 1 1 shared))
                      (import "wasi" "thread-spawn" (func $spawn (param i32) (result i32)))
                      (func (export "wasi_thread_start") (param i32 i32))
                      (func (export "run") (result i32) (call $spawn (i32.const 0)))
                    )
                    """, features: [.threads]
                ), features: [.threads])
            let threads = try WASIThreads(
                module: module, engine: engine, configuration: .init(maximumThreads: 1),
                processControl: .init(
                    terminateAfterMainReturn: { _ in fatalError("not reached") },
                    terminateAfterWorkerFailure: { error in fatalError("unexpected worker failure: \(error)") }
                ), childImports: { _ in Imports() }
            )
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store, imports: threads.makeImports(store: store))
            let run = try #require(instance.exports[function: "run"])
            #expect(try run() == [.i32(UInt32.max)])
        }
    }

#endif
