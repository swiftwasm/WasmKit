#if os(macOS) || os(Linux)

    import Testing
    import WAT

    @testable import WasmKit

    private let sharedMemorySupported = SharedMemoryStorage.isSupported(
        engineConfiguration: Engine(configuration: .init(features: [.threads])).configuration,
        isMemory64: false
    )

    @Suite(.enabled(if: sharedMemorySupported)) struct ThreadInstantiationTests {
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

            // Fresh from the initializer, not the parent's 999.
            let childGlobal = childInstance.exports[global: "g"]!
            #expect(childGlobal.value == .i32(42))

            #expect(parentGlobal.value == .i32(999))

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

            // Still "XXXXX": the child did not re-apply the "hello" data segment.
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

            let childTable = childInstance.exports[table: "table"]!
            let ref = childTable[0]
            #expect(ref != .function(nil))

            // No element segment covers index 1.
            #expect(childTable[1] == .function(nil))
        }

        @Test func childSkipsStartFunction() throws {
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

            // The parent's start function ran.
            let mem = parentInstance.exports[memory: "memory"]!
            var parentBuf = [UInt8](repeating: 0, count: 4)
            mem.withUnsafeBufferPointer(offset: 0, count: 4) { ptr in
                for i in 0..<4 {
                    parentBuf[i] = ptr.load(fromByteOffset: i, as: UInt8.self)
                }
            }
            #expect(parentBuf == [99, 0, 0, 0])

            // Clear it so a re-run of start would be visible.
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

            // Still 0: the child did not run the start function.
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
