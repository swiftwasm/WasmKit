import Synchronization
import Testing
import WAT

@_spi(Fuzzing) @_spi(OnlyForCLI) @testable import WasmKit

#if os(macOS) || os(Linux)

    extension SharedMemoryStorage {
        /// Test convenience: construct from a `MemoryType`. Production code decomposes these
        /// values at the caller (`MemoryEntity.init`).
        convenience init(memoryType: MemoryType, engineConfiguration: EngineConfiguration) throws(Trap) {
            let maxPages = memoryType.max ?? UInt64(MemoryEntity.maxPageCount(isMemory64: memoryType.isMemory64))
            try self.init(
                initialBytes: Int(memoryType.min) * MemoryEntity.pageSize,
                maxBytes: Int(clamping: maxPages) * MemoryEntity.pageSize,
                isMemory64: memoryType.isMemory64,
                engineConfiguration: engineConfiguration
            )
        }
    }

    private let sharedMemorySupported = SharedMemoryStorage.isSupported(
        engineConfiguration: Engine(configuration: .init(features: [.threads])).configuration,
        isMemory64: false
    )

    @Suite(.enabled(if: sharedMemorySupported)) struct SharedMemoryStorageTests {
        /// Asserts `body` throws a `Trap` whose `reason` equals `expected`, without relying on
        /// `Trap: Equatable`. Closure-based counterpart to `ExecutionTests.expectTrap` (which runs
        /// a WAT module); both capture the trap and assert on its reason rather than comparing
        /// whole `Trap` values, so the per-run backtrace never participates in the check.
        func expectTrap(
            _ expected: TrapReason,
            sourceLocation: SourceLocation = #_sourceLocation,
            _ body: () throws -> Void
        ) {
            do {
                try body()
                Issue.record("expected a trap (\(expected)), but no error was thrown", sourceLocation: sourceLocation)
            } catch let trap as Trap {
                #expect(trap.reason.description == expected.description, sourceLocation: sourceLocation)
            } catch {
                Issue.record("expected a trap (\(expected)), but caught: \(error)", sourceLocation: sourceLocation)
            }
        }

        // MARK: - Unit tests (SharedMemoryStorage directly)

        @Test func initSharedMemory_correctInitialState() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let memType = MemoryType(min: 2, max: 10, shared: true)
            let storage = try SharedMemoryStorage(
                memoryType: memType, engineConfiguration: engine.configuration)

            #expect(storage.currentByteCount.load(ordering: .acquiring) == 2 * 65536)
            #expect(storage.maxByteCount == 10 * 65536)
            // Guard-page backed: reserves the full wasm32 range plus the offset guard region.
            #expect(storage.reservationSize == (1 << 32) + engine.configuration.memoryOffsetGuardSize)
            // Initial region is zero-filled.
            let firstByte = storage.basePointer.load(as: UInt8.self)
            #expect(firstByte == 0)
            let lastByte = storage.basePointer.load(fromByteOffset: 2 * 65536 - 1, as: UInt8.self)
            #expect(lastByte == 0)
        }

        @Test func growSharedMemory_basePointerStable() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 4, shared: true)
            let memory = try Memory(store: store, type: memType)

            let baseBefore = memory.handle.withValue { $0.baseAddress }
            // Grow by 2 pages
            memory.handle.withValue { entity in
                let result = try! entity.grow(by: 2, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(1))  // old page count was 1
            }
            let baseAfter = memory.handle.withValue { $0.baseAddress }
            #expect(baseBefore == baseAfter, "Base pointer must not change on shared memory grow")
            #expect(memory.handle.withValue({ $0.byteCount }) == 3 * 65536)
        }

        @Test func growSharedMemory_returnsPreviousPageCount() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 4, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                let result1 = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
                #expect(result1 == .i32(1))  // was 1 page
                let result2 = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
                #expect(result2 == .i32(2))  // was 2 pages
            }
        }

        @Test func growSharedMemory_exceedsMax_returnsNegative() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 2, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                // Grow by 2 would bring total to 3, exceeding max of 2
                let result = try! entity.grow(by: 2, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(UInt32(bitPattern: -1)))
                // Size unchanged
                #expect(entity.byteCount == 1 * 65536)
            }
        }

        @Test func growSharedMemory_zeroFillsNewPages() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 3, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                // Write a non-zero byte at the end of page 1
                entity.baseAddress!.storeBytes(of: UInt8(0xFF), toByteOffset: 65535, as: UInt8.self)

                let _ = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)

                // Spot-check new page is zero-filled at start, middle, and end
                let newPageStart = entity.baseAddress!.load(fromByteOffset: 65536, as: UInt8.self)
                let newPageMiddle = entity.baseAddress!.load(fromByteOffset: 65536 + 32768, as: UInt8.self)
                let newPageEnd = entity.baseAddress!.load(fromByteOffset: 2 * 65536 - 1, as: UInt8.self)
                #expect(newPageStart == 0)
                #expect(newPageMiddle == 0)
                #expect(newPageEnd == 0)

                // Verify the old data is still intact
                let preserved = entity.baseAddress!.load(fromByteOffset: 65535, as: UInt8.self)
                #expect(preserved == 0xFF)
            }
        }

        // MARK: - WAT-based integration tests

        @Test func sharedMemory_growAndAccess() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 4 shared)
                        (func (export "grow") (result i32)
                            (memory.grow (i32.const 1))
                        )
                        (func (export "store-and-load") (param $addr i32) (param $val i32) (result i32)
                            (i32.store (local.get $addr) (local.get $val))
                            (i32.load (local.get $addr))
                        )
                        (func (export "size") (result i32)
                            (memory.size)
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let grow = try #require(instance.exports[function: "grow"])
            let storeAndLoad = try #require(instance.exports[function: "store-and-load"])
            let size = try #require(instance.exports[function: "size"])

            // Initial size is 1 page
            #expect(try size() == [.i32(1)])

            // Store and load within initial page
            #expect(try storeAndLoad([.i32(0), .i32(42)]) == [.i32(42)])

            // Grow by 1
            #expect(try grow() == [.i32(1)])  // old page count

            // Size should be 2
            #expect(try size() == [.i32(2)])

            // Store and load in the new page
            #expect(try storeAndLoad([.i32(65536), .i32(99)]) == [.i32(99)])
        }

        @Test func sharedMemory_sizeReflectsHostGrow() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (import "env" "mem") 1 4 shared)
                        (func (export "size") (result i32)
                            (memory.size)
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )

            // Create shared memory and import it
            let sharedMem = try Memory(store: store, type: MemoryType(min: 1, max: 4, shared: true))
            let imports: Imports = ["env": ["mem": sharedMem]]
            let instance = try module.instantiate(store: store, imports: imports)
            let size = try #require(instance.exports[function: "size"])

            #expect(try size() == [.i32(1)])

            // Grow from the host side (bypassing wasm memory.grow instruction)
            sharedMem.handle.withValue { entity in
                let _ = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
            }

            // memory.size should see the updated value (reads atomically from SharedMemoryStorage)
            #expect(try size() == [.i32(2)])
        }

        // MARK: - Bounds checking and signal handler tests

        @Test func growSharedMemory_byZero_returnsCurrentPageCount() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 2, max: 4, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                let result = try! entity.grow(by: 0, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(2))  // returns current page count, not -1
                #expect(entity.byteCount == 2 * 65536)  // size unchanged
            }
        }

        @Test func growSharedMemory_toExactMax_succeeds() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 3, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                // Grow to exactly max (1 + 2 = 3)
                let result = try! entity.grow(by: 2, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(1))
                #expect(entity.byteCount == 3 * 65536)

                // One more page should fail
                let fail = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
                #expect(fail == .i32(UInt32(bitPattern: -1)))
                #expect(entity.byteCount == 3 * 65536)  // unchanged
            }
        }

        @Test func growSharedMemory_overflowChecked() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 10, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                // Grow by a huge number that would overflow Int multiplication
                let result = try! entity.grow(by: Int.max / 65536 + 1, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(UInt32(bitPattern: -1)))
                #expect(entity.byteCount == 1 * 65536)  // unchanged
            }
        }

        @Test func sharedMemory_oobBoundary() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "load8") (param $addr i32) (result i32)
                            (i32.load8_u (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let load8 = try #require(instance.exports[function: "load8"])

            // Last byte of page 1: should succeed
            #expect(try load8([.i32(65535)]) == [.i32(0)])

            // First byte beyond committed region: should trap
            expectTrap(.memoryOutOfBounds) {
                _ = try load8([.i32(65536)])
            }
        }

        @Test func sharedMemory_bulkOps() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "fill") (param $dst i32) (param $val i32) (param $len i32)
                            (memory.fill (local.get $dst) (local.get $val) (local.get $len))
                        )
                        (func (export "copy") (param $dst i32) (param $src i32) (param $len i32)
                            (memory.copy (local.get $dst) (local.get $src) (local.get $len))
                        )
                        (func (export "load8") (param $addr i32) (result i32)
                            (i32.load8_u (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let fill = try #require(instance.exports[function: "fill"])
            let copy = try #require(instance.exports[function: "copy"])
            let load8 = try #require(instance.exports[function: "load8"])

            // Fill 4 bytes at offset 0 with value 0xAB
            _ = try fill([.i32(0), .i32(0xAB), .i32(4)])
            #expect(try load8([.i32(0)]) == [.i32(0xAB)])
            #expect(try load8([.i32(3)]) == [.i32(0xAB)])
            #expect(try load8([.i32(4)]) == [.i32(0)])

            // Copy 4 bytes from offset 0 to offset 10
            _ = try copy([.i32(10), .i32(0), .i32(4)])
            #expect(try load8([.i32(10)]) == [.i32(0xAB)])
            #expect(try load8([.i32(13)]) == [.i32(0xAB)])
        }

        @Test func sharedMemory_growViaWasm_failAtMax() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "grow1") (result i32)
                            (memory.grow (i32.const 1))
                        )
                        (func (export "size") (result i32)
                            (memory.size)
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let grow1 = try #require(instance.exports[function: "grow1"])
            let size = try #require(instance.exports[function: "size"])

            #expect(try size() == [.i32(1)])

            // Grow to max (2 pages)
            #expect(try grow1() == [.i32(1)])
            #expect(try size() == [.i32(2)])

            // One more should fail
            #expect(try grow1() == [.i32(UInt32(bitPattern: -1))])
            #expect(try size() == [.i32(2)])
        }

        @Test func sharedMemory_accessAfterGrowInNewRegion() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 4 shared)
                        (func (export "grow1") (result i32)
                            (memory.grow (i32.const 1))
                        )
                        (func (export "store-load") (param $addr i32) (param $val i32) (result i32)
                            (i32.store (local.get $addr) (local.get $val))
                            (i32.load (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let grow1 = try #require(instance.exports[function: "grow1"])
            let storeLoad = try #require(instance.exports[function: "store-load"])

            // Grow into page 2
            #expect(try grow1() == [.i32(1)])

            // Access the newly grown page
            #expect(try storeLoad([.i32(65536), .i32(12345)]) == [.i32(12345)])

            // Grow again, access page 3
            #expect(try grow1() == [.i32(2)])
            #expect(try storeLoad([.i32(131072), .i32(99999)]) == [.i32(99999)])
        }

        @Test func sharedMemory_uncheckedOobTraps() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 2, shared: true)
            let memory = try Memory(store: store, type: memType)

            // An OOB access one page past the committed region must trap (via the software
            // check), not reach the PROT_NONE tail.

            // Run a module that does an OOB access -- must trap, not silently succeed
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (import "env" "mem") 1 2 shared)
                        (func (export "oob_load") (result i32)
                            (i32.load (i32.const 65536))
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let imports: Imports = ["env": ["mem": memory]]
            let instance = try module.instantiate(store: store, imports: imports)
            let oobLoad = try #require(instance.exports[function: "oob_load"])

            expectTrap(.memoryOutOfBounds) {
                _ = try oobLoad()
            }
        }

        // MARK: - Step 1: Large OOB address must trap, not crash

        @Test func sharedMemory_largeOobTraps() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 1, max: 2, shared: true)
            let memory = try Memory(store: store, type: memType)

            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (import "env" "mem") 1 2 shared)
                        (func (export "oob") (param $addr i32) (result i32)
                            (i32.load (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]),
                features: [.threads])
            let instance = try module.instantiate(store: store, imports: ["env": ["mem": memory]])
            let oob = try #require(instance.exports[function: "oob"])

            // Address 999999 is way beyond 2 pages (131072). Must trap, not crash.
            expectTrap(.memoryOutOfBounds) {
                _ = try oob([.i32(999999)])
            }
        }

        // MARK: - Access to grown region + unsupported-mode guard

        @Test func sharedMemory_requiresMprotect_softwareModeThrows() {
            // Shared memory relies on the mprotect guard-page reservation for OOB detection,
            // so creating it under software bounds checking is unsupported and traps.
            let engine = Engine(
                configuration: .init(
                    features: [.threads],
                    memoryBoundsChecking: .software
                ))
            let sharedType = MemoryType(min: 1, max: 4, shared: true)
            #expect(throws: Trap.self) {
                _ = try SharedMemoryStorage(memoryType: sharedType, engineConfiguration: engine.configuration)
            }
        }

        @Test func sharedMemory_accessGrownRegion_atomic() throws {
            // Default engine config (mprotect bounds checking). After a host grow, an atomic
            // load from the newly committed page must succeed: `ms` is the constant guard-page
            // reservation, so the software check passes and the freshly committed pages are
            // accessible.
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)

            let sharedType = MemoryType(min: 1, max: 4, shared: true)
            let sharedStorage = try SharedMemoryStorage(
                memoryType: sharedType, engineConfiguration: engine.configuration)
            let sharedMem = Memory(store: store, type: sharedType, sharedStorage: sharedStorage)

            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (import "test" "memory" (memory 1 4 shared))
                        (import "test" "grow" (func $grow))
                        (func (export "test_staleness") (result i32)
                            call $grow
                            ;; i32.atomic.load always takes the checked path (no unchecked
                            ;; atomic variants). Exercises atomicLoad boundsOk slow path
                            ;; when ms is stale after host grow.
                            (i32.atomic.load (i32.const 65536))
                        )
                    )
                    """,
                    features: [.threads]),
                features: [.threads])

            let growCalled = Atomic<Bool>(false)
            let limiter = store.resourceLimiter
            let growFunc = Function(store: store, type: FunctionType(parameters: [], results: [])) { _, _ in
                _ = try! sharedStorage.grow(by: 1, resourceLimiter: limiter)
                growCalled.store(true, ordering: .releasing)
                return []
            }

            let imports: Imports = ["test": ["memory": sharedMem, "grow": growFunc]]
            let instance = try module.instantiate(store: store, imports: imports)
            let testStaleness = try #require(instance.exports[function: "test_staleness"])

            let result = try testStaleness()
            #expect(result == [.i32(0)])
            let didGrow = growCalled.load(ordering: .acquiring)
            #expect(didGrow, "Host grow function must have been called")
        }

        // MARK: - Step 7: Additional coverage tests

        @Test func sharedMemory_boundaryAfterGrow() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "grow1") (result i32)
                            (memory.grow (i32.const 1))
                        )
                        (func (export "load8") (param $addr i32) (result i32)
                            (i32.load8_u (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]),
                features: [.threads])
            let instance = try module.instantiate(store: store)
            let grow1 = try #require(instance.exports[function: "grow1"])
            let load8 = try #require(instance.exports[function: "load8"])

            // Grow from 1 to 2 pages
            #expect(try grow1() == [.i32(1)])

            // Last byte of page 2: should succeed
            #expect(try load8([.i32(131071)]) == [.i32(0)])

            // First byte beyond 2 pages: should trap
            expectTrap(.memoryOutOfBounds) {
                _ = try load8([.i32(131072)])
            }
        }

        @Test func sharedMemory_dataIntegrityAcrossGrow() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 4 shared)
                        (func (export "grow1") (result i32)
                            (memory.grow (i32.const 1))
                        )
                        (func (export "store32") (param $addr i32) (param $val i32)
                            (i32.store (local.get $addr) (local.get $val))
                        )
                        (func (export "load32") (param $addr i32) (result i32)
                            (i32.load (local.get $addr))
                        )
                    )
                    """,
                    features: [.threads]),
                features: [.threads])
            let instance = try module.instantiate(store: store)
            let grow1 = try #require(instance.exports[function: "grow1"])
            let store32 = try #require(instance.exports[function: "store32"])
            let load32 = try #require(instance.exports[function: "load32"])

            // Store value in page 1
            _ = try store32([.i32(100), .i32(42)])

            // Grow and store in page 2
            #expect(try grow1() == [.i32(1)])
            _ = try store32([.i32(65636), .i32(99)])

            // Read back both values: data in page 1 must survive grow
            #expect(try load32([.i32(100)]) == [.i32(42)])
            #expect(try load32([.i32(65636)]) == [.i32(99)])
        }

        @Test func sharedMemory_minZero() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 0, max: 2, shared: true)
            let memory = try Memory(store: store, type: memType)

            #expect(memory.byteCount == 0)

            // Grow by 1 page
            memory.handle.withValue { entity in
                let result = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
                #expect(result == .i32(0))  // old page count was 0
                #expect(entity.byteCount == 65536)
            }
        }

        @Test func sharedMemory_minEqualsMax() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let memType = MemoryType(min: 2, max: 2, shared: true)
            let memory = try Memory(store: store, type: memType)

            memory.handle.withValue { entity in
                // Grow by 0 returns current page count
                let result0 = try! entity.grow(by: 0, resourceLimiter: store.resourceLimiter)
                #expect(result0 == .i32(2))

                // Grow by 1 must fail (already at max)
                let result1 = try! entity.grow(by: 1, resourceLimiter: store.resourceLimiter)
                #expect(result1 == .i32(UInt32(bitPattern: -1)))

                // Size unchanged
                #expect(entity.byteCount == 2 * 65536)
            }
        }

        // Regression: per the threads spec, `memory.atomic.wait` timeout is a
        // signed i64; `timeout >= 0` expires after that many nanoseconds, and
        // a zero timeout must return immediately with code 2 (timed-out) when
        // the value matches. The original implementation incorrectly treated
        // `timeout == 0` as "wait indefinitely".
        @Test func atomicWait32_zeroTimeoutReturnsImmediately() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "wait_zero") (result i32)
                            i32.const 0       ;; address
                            i32.const 0       ;; expected value (matches initial 0)
                            i64.const 0       ;; timeout = 0 ns (immediate)
                            memory.atomic.wait32
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let waitZero = try #require(instance.exports[function: "wait_zero"])
            // Spec result codes: 0 = ok, 1 = not-equal, 2 = timed-out.
            #expect(try waitZero([]) == [.i32(2)])
        }

        // Regression: per the threads spec, `memory.atomic.wait` timeout is a
        // signed i64; `timeout < 0` means never expires. The original
        // implementation crashed on negative timeouts because it converted the
        // raw UInt64 via `Int64(timeout)`, which traps on values > Int64.max.
        // Use a value-mismatch path so the wait returns immediately with code 1
        // and we don't actually have to wait forever to prove there's no crash.
        @Test func atomicWait32_negativeTimeoutDoesNotCrash() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "wait_mismatch") (result i32)
                            i32.const 0       ;; address
                            i32.const 999     ;; expected value (mismatches initial 0)
                            i64.const -1      ;; timeout < 0 (would be infinite if reached)
                            memory.atomic.wait32
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let waitMismatch = try #require(instance.exports[function: "wait_mismatch"])
            // Value mismatch returns code 1 (not-equal) without entering the wait,
            // but the timeout argument is decoded before the mismatch check in
            // some implementations; this still proves the bit-pattern conversion
            // doesn't crash.
            #expect(try waitMismatch([]) == [.i32(1)])
        }

        // Regression: same fix verified for the i64 variant.
        @Test func atomicWait64_zeroTimeoutReturnsImmediately() throws {
            let engine = Engine(configuration: .init(features: [.threads]))
            let store = Store(engine: engine)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (memory (export "mem") 1 2 shared)
                        (func (export "wait_zero") (result i32)
                            i32.const 0       ;; address
                            i64.const 0       ;; expected value (matches initial 0)
                            i64.const 0       ;; timeout = 0 ns (immediate)
                            memory.atomic.wait64
                        )
                    )
                    """,
                    features: [.threads]
                ),
                features: [.threads]
            )
            let instance = try module.instantiate(store: store)
            let waitZero = try #require(instance.exports[function: "wait_zero"])
            #expect(try waitZero([]) == [.i32(2)])
        }

        // Guards against reintroducing `...Shared` opcode variants: shared and non-shared
        // memory must select the same load/store opcodes.
        @Test func loadStoreOpcodeSelection_byMemoryShared() throws {
            // `dumpFunctions` needs token threading (readable disassembly), but shared memory
            // needs mprotect (direct threading). Dumping only translates, never executes, so for
            // the shared case we create the backing under an mprotect engine and *import* it into
            // the token-threaded dump instance.
            func dumpLoadStore(shared: Bool) throws -> String {
                let dumpEngine = Engine(configuration: .init(threadingModel: .token, features: shared ? [.threads] : []))
                let dumpStore = Store(engine: dumpEngine)

                let memoryDecl: String
                let imports: Imports
                if shared {
                    memoryDecl = #"(import "env" "mem" (memory 1 1 shared))"#
                    let ownerEngine = Engine(configuration: .init(features: [.threads]))
                    let sharedType = MemoryType(min: 1, max: 1, shared: true)
                    let storage = try SharedMemoryStorage(memoryType: sharedType, engineConfiguration: ownerEngine.configuration)
                    imports = ["env": ["mem": Memory(store: dumpStore, type: sharedType, sharedStorage: storage)]]
                } else {
                    memoryDecl = "(memory 1)"
                    imports = [:]
                }

                let module = try parseWasm(
                    bytes: try wat2wasm(
                        """
                        (module
                            \(memoryDecl)
                            (func (export "ld") (param i32) (result i32) (i32.load (local.get 0)))
                            (func (export "st") (param i32 i32) (i32.store (local.get 0) (local.get 1)))
                        )
                        """,
                        features: shared ? [.threads] : []
                    ),
                    features: shared ? [.threads] : []
                )
                let instance = try module.instantiate(store: dumpStore, imports: imports)
                var out = ""
                try instance.dumpFunctions(to: &out, module: module)
                return out
            }

            let plain = try dumpLoadStore(shared: false)
            #expect(plain.contains("i32.load"))
            #expect(plain.contains("i32.store"))
            #expect(!plain.contains("Shared"))

            // Shared memory emits the same opcodes; no `...Shared` variant.
            let shared = try dumpLoadStore(shared: true)
            #expect(shared.contains("i32.load"))
            #expect(shared.contains("i32.store"))
            #expect(!shared.contains("Shared"))
        }

        // SIMD (v128) loads on shared memory must tolerate a stale cached size after a
        // concurrent grow, consistent with scalar loads. After a host grow, the v128.load
        // into the freshly-grown page must succeed (zero-filled), not trap.
        @Test func sharedMemory_accessGrownRegion_simd() throws {
            let engine = Engine(configuration: .init(features: [.threads, .simd]))
            let store = Store(engine: engine)
            let sharedType = MemoryType(min: 1, max: 4, shared: true)
            let sharedStorage = try SharedMemoryStorage(
                memoryType: sharedType, engineConfiguration: engine.configuration)
            let sharedMem = Memory(store: store, type: sharedType, sharedStorage: sharedStorage)
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                        (import "test" "memory" (memory 1 4 shared))
                        (import "test" "grow" (func $grow))
                        (func (export "test_staleness") (result i32)
                            call $grow
                            (i32x4.extract_lane 0 (v128.load (i32.const 65536)))
                        )
                    )
                    """,
                    features: [.threads, .simd]),
                features: [.threads, .simd])
            let growCalled = Atomic<Bool>(false)
            let limiter = store.resourceLimiter
            let growFunc = Function(store: store, type: FunctionType(parameters: [], results: [])) { _, _ in
                _ = try! sharedStorage.grow(by: 1, resourceLimiter: limiter)
                growCalled.store(true, ordering: .releasing)
                return []
            }
            let imports: Imports = ["test": ["memory": sharedMem, "grow": growFunc]]
            let instance = try module.instantiate(store: store, imports: imports)
            let testStaleness = try #require(instance.exports[function: "test_staleness"])
            let result = try testStaleness()
            #expect(result == [.i32(0)])
            let didGrow = growCalled.load(ordering: .acquiring)
            #expect(didGrow, "Host grow function must have been called")
        }
    }

#endif
