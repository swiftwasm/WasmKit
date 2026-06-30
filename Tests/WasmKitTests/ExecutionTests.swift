import Testing
import WAT

@testable import WasmKit

@Suite
struct ExecutionTests {

    @Test
    func dropWithRelinkingOptimization() throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (func (export "_start") (result i32) (local $x i32)
                        (i32.const 42)
                        (i32.const 0)
                        (i32.eqz)
                        (drop)
                        (local.set $x)
                        (local.get $x)
                    )
                )
                """
            )
        )
        let engine = Engine()
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    @Test
    func updateCurrentMemoryCacheOnGrow() throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (memory 0)
                    (func (export "_start") (result i32)
                        (drop (memory.grow (i32.const 1)))
                        (i32.store (i32.const 1) (i32.const 42))
                        (i32.load (i32.const 1))
                    )
                )
                """
            )
        )
        let engine = Engine()
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    @Test
    func runtimeTraceRecordsFunctionAndMemoryUse() throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (memory 1)
                    (data (i32.const 24) "xy")
                    (data "abcdef")
                    (func (export "_start")
                        (i32.store (i32.const 8) (i32.const 42))
                        (drop (i32.load (i32.const 8)))
                        (memory.init 1 (i32.const 16) (i32.const 1) (i32.const 3))
                    )
                    (func (export "unused")
                        unreachable
                    )
                )
                """,
                options: EncodeOptions(nameSection: true)
            )
        )
        let traceRecorder = WasmExecutionTraceRecorder()
        let engine = Engine(interceptor: traceRecorder)
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])

        try _start()

        let trace = traceRecorder.snapshot()
        #expect(trace.executedFunctions.map(\.name) == ["_start"])
        #expect(trace.memoryWrites == [.init(memory: 0, offset: 8, length: 4)])
        #expect(trace.memoryReads == [.init(memory: 0, offset: 8, length: 4)])
        #expect(trace.dataSegmentsInitialized == [
            .init(segment: 0, sourceOffset: 0, destinationOffset: 24, length: 2),
            .init(segment: 1, sourceOffset: 1, destinationOffset: 16, length: 3),
        ])
        #expect(!trace.jsonString.contains("unused"))
    }

    func expectTrap(_ wat: String, assertTrap: (Trap) throws -> Void) throws {
        let module = try parseWasm(
            bytes: wat2wasm(wat, options: EncodeOptions(nameSection: true))
        )

        let engine = Engine()
        let store = Store(engine: engine)
        var imports = Imports()
        for importEntry in module.imports {
            guard case .function(let type) = importEntry.descriptor else { continue }
            let function = try Function(
                store: store,
                type: module.resolveFunctionType(type),
                body: { _, _ in
                    return []
                }
            )
            imports.define(importEntry, .function(function))
        }
        let instance = try module.instantiate(store: store, imports: imports)
        let _start = try #require(instance.exports[function: "_start"])

        let trap: Trap
        do {
            let _ = try _start()
            #expect((false), "Expected trap")
            return
        } catch let _trap as Trap {
            trap = _trap
        } catch {
            #expect((false), "Expected trap: \(error)")
            return
        }
        try assertTrap(trap)
    }

    @Test
    func backtraceBasic() throws {
        try expectTrap(
            """
            (module
                (func $foo
                    unreachable
                )
                (func $bar
                    (call $foo)
                )
                (func (export "_start")
                    (call $bar)
                )
            )
            """
        ) { trap in
            #expect(
                trap.backtrace?.symbols.compactMap(\.name) == [
                    "foo",
                    "bar",
                    "_start",
                ])
        }
    }

    @Test
    func backtraceWithImports() throws {
        try expectTrap(
            """
            (module
                (func (import "env" "bar"))
                (func
                    unreachable
                )
                (func $bar
                    (call 1)
                )
                (func (export "_start")
                    (call $bar)
                )
            )
            """
        ) { trap in
            #expect(
                trap.backtrace?.symbols.compactMap(\.name) == [
                    "wasm function[1]",
                    "bar",
                    "_start",
                ])
        }
    }
}
