#if os(macOS) || os(Linux)

    import Testing
    import WAT

    @testable import WasmKit

    @Suite struct ThreadInstantiationTests {
        /// Helper: build a ThreadGroup from a parent instance.
        private func makeThreadGroup(
            module: Module,
            parentInstance: Instance,
            engine: Engine
        ) -> ThreadGroup {
            let sharedMemories: [SharedMemoryStorage?] = parentInstance.handle.withValue { inst in
                (0..<inst.memories.count).map { i in
                    inst.memories[i].withValue { $0.sharedStorage }
                }
            }
            return ThreadGroup(
                module: module,
                engineConfiguration: engine.configuration,
                funcTypeInterner: engine.funcTypeInterner,
                sharedMemories: sharedMemories
            )
        }

        @Test func childSharesMemoryButGetsFreshGlobals() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") 1 4 shared)
                      (global (export "g") (mut i32) (i32.const 42))
                    )
                    """),
                features: [.threads]
            )

            let engine = Engine()
            let parentStore = Store(engine: engine)
            let parentInstance = try module.instantiate(store: parentStore)

            // Mutate parent's global to 999
            let parentGlobal = parentInstance.exports[global: "g"]!
            try parentGlobal.assign(.i32(999))
            #expect(parentGlobal.value == .i32(999))

            let group = makeThreadGroup(
                module: module,
                parentInstance: parentInstance,
                engine: engine
            )

            let childEngine = group.makeChildEngine()
            let childStore = Store(engine: childEngine)
            let childInstance = try module.instantiateForThread(
                store: childStore,
                threadGroup: group,
                imports: [:]
            )

            // Child's global should be fresh (42 from initializer), not 999
            let childGlobal = childInstance.exports[global: "g"]!
            #expect(childGlobal.value == .i32(42))

            // Parent's global should still be 999
            #expect(parentGlobal.value == .i32(999))

            // Memory should be shared (same SharedMemoryStorage)
            let parentMemShared = parentInstance.handle.withValue {
                $0.memories[0].withValue { $0.sharedStorage }
            }
            let childMemShared = childInstance.handle.withValue {
                $0.memories[0].withValue { $0.sharedStorage }
            }
            #expect(parentMemShared === childMemShared)
        }

        @Test func childSkipsDataSegmentForSharedMemory() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") 1 4 shared)
                      (data (i32.const 0) "hello")
                    )
                    """),
                features: [.threads]
            )

            let engine = Engine()
            let parentStore = Store(engine: engine)
            let parentInstance = try module.instantiate(store: parentStore)

            // Overwrite the data region with "XXXXX"
            let parentMem = parentInstance.exports[memory: "memory"]!
            let overwrite = Array("XXXXX".utf8)
            parentMem.withUnsafeMutableBufferPointer(offset: 0, count: 5) { buf in
                for (i, byte) in overwrite.enumerated() {
                    buf[i] = byte
                }
            }

            let group = makeThreadGroup(
                module: module,
                parentInstance: parentInstance,
                engine: engine
            )

            let childEngine = group.makeChildEngine()
            let childStore = Store(engine: childEngine)
            _ = try module.instantiateForThread(
                store: childStore,
                threadGroup: group,
                imports: [:]
            )

            // Shared memory should still have "XXXXX", not "hello"
            var buf = [UInt8](repeating: 0, count: 5)
            parentMem.withUnsafeBufferPointer(offset: 0, count: 5) { ptr in
                for i in 0..<5 {
                    buf[i] = ptr.load(fromByteOffset: i, as: UInt8.self)
                }
            }
            #expect(buf == Array("XXXXX".utf8))
        }

        @Test func childAppliesElementSegmentsToFreshTables() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") 1 4 shared)
                      (table (export "table") 10 funcref)
                      (func $f)
                      (elem (i32.const 0) func $f)
                    )
                    """),
                features: [.threads]
            )

            let engine = Engine()
            let parentStore = Store(engine: engine)
            let parentInstance = try module.instantiate(store: parentStore)

            let group = makeThreadGroup(
                module: module,
                parentInstance: parentInstance,
                engine: engine
            )

            let childEngine = group.makeChildEngine()
            let childStore = Store(engine: childEngine)
            let childInstance = try module.instantiateForThread(
                store: childStore,
                threadGroup: group,
                imports: [:]
            )

            // Child's table[0] should contain a function reference (not null)
            let childTable = childInstance.exports[table: "table"]!
            let ref = childTable[0]
            #expect(ref != .function(nil))

            // Child's table[1] should still be null (no element segment for it)
            #expect(childTable[1] == .function(nil))
        }

        @Test func childSkipsStartFunction() throws {
            // Module with a start function that writes 99 to memory offset 0.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") 1 4 shared)
                      (func $init
                        i32.const 0
                        i32.const 99
                        i32.store
                      )
                      (start $init)
                    )
                    """),
                features: [.threads]
            )

            let engine = Engine()
            let parentStore = Store(engine: engine)
            let parentInstance = try module.instantiate(store: parentStore)

            // Verify parent's start function ran (memory[0] == 99)
            let mem = parentInstance.exports[memory: "memory"]!
            var parentBuf = [UInt8](repeating: 0, count: 4)
            mem.withUnsafeBufferPointer(offset: 0, count: 4) { ptr in
                for i in 0..<4 {
                    parentBuf[i] = ptr.load(fromByteOffset: i, as: UInt8.self)
                }
            }
            // 99 in little-endian i32 = [99, 0, 0, 0]
            #expect(parentBuf == [99, 0, 0, 0])

            // Clear memory[0] so we can detect if child re-runs start
            mem.withUnsafeMutableBufferPointer(offset: 0, count: 4) { buf in
                for i in 0..<4 { buf[i] = 0 }
            }

            let group = makeThreadGroup(
                module: module,
                parentInstance: parentInstance,
                engine: engine
            )

            let childEngine = group.makeChildEngine()
            let childStore = Store(engine: childEngine)
            _ = try module.instantiateForThread(
                store: childStore,
                threadGroup: group,
                imports: [:]
            )

            // Memory[0] should still be 0 (child did NOT run start function)
            var childBuf = [UInt8](repeating: 0xFF, count: 4)
            mem.withUnsafeBufferPointer(offset: 0, count: 4) { ptr in
                for i in 0..<4 {
                    childBuf[i] = ptr.load(fromByteOffset: i, as: UInt8.self)
                }
            }
            #expect(childBuf == [0, 0, 0, 0])
        }
    }

#endif
