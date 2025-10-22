import Testing
import WAT

@testable import WasmKit
@testable import WasmParser

@Suite
struct HostModuleTests {
    @Test
    func importMemory() throws {
        let engine = Engine()
        let store = Store(engine: engine)
        let memoryType = MemoryType(min: 1, max: nil)
        let memory = try WasmKit.Memory(store: store, type: memoryType)
        let imports: Imports = [
            "env": ["memory": memory]
        ]

        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (import "env" "memory" (memory 1))
                )
                """))
        #expect(throws: Never.self) { try module.instantiate(store: store, imports: imports) }
        // Ensure the allocated address is valid
        _ = memory.data
    }

    @Test
    func reentrancy() throws {
        let engine = Engine()
        let store = Store(engine: engine)
        let voidSignature = WasmTypes.FunctionType(parameters: [], results: [])
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (import "env" "bar" (func $bar))
                    (import "env" "qux" (func $qux))
                    (func (export "foo")
                        (call $bar)
                        (call $bar)
                        (call $bar)
                    )
                    (func (export "baz")
                        (call $qux)
                    )
                )
                """)
        )

        var isExecutingFoo = false
        var isQuxCalled = false
        let imports: Imports = [
            "env": [
                "bar": Function(store: store, type: voidSignature) { caller, _ in
                    // Ensure "invoke" executes instructions under the current call
                    #expect(isExecutingFoo == false, "bar should not be called recursively")
                    isExecutingFoo = true
                    defer { isExecutingFoo = false }
                    let foo = try #require(caller.instance?.exportedFunction(name: "baz"))
                    _ = try foo()
                    return []
                },
                "qux": Function(store: store, type: voidSignature) { caller, _ in
                    #expect(isExecutingFoo == true)
                    isQuxCalled = true
                    return []
                },
            ]
        ]
        let instance = try module.instantiate(store: store, imports: imports)
        // Check foo(wasm) -> bar(host) -> baz(wasm) -> qux(host)
        let foo = try #require(instance.exports[function: "foo"])
        try foo()
        #expect(isQuxCalled == true)
    }
}

