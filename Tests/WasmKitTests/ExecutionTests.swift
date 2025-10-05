#if canImport(Testing)
    import WAT
    import Testing

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

            guard let trap: Trap = (#expect(throws: Trap.self) { try _start() }) else {
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
                    trap.backtrace?.symbols.compactMap(\.?.name) == [
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
                    trap.backtrace?.symbols.compactMap(\.?.name) == [
                        "wasm function[1]",
                        "bar",
                        "_start",
                    ])
            }
        }
    }

#endif
