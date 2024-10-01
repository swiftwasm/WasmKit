import WAT
import XCTest

@testable import WasmKit
@testable import WasmParser

final class HostModuleTests: XCTestCase {
    func testImportMemory() throws {
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
        XCTAssertNoThrow(try module.instantiate(store: store, imports: imports))
        // Ensure the allocated address is valid
        _ = memory.data
    }

    func testReentrancy() throws {
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
                    XCTAssertFalse(isExecutingFoo, "bar should not be called recursively")
                    isExecutingFoo = true
                    defer { isExecutingFoo = false }
                    let foo = try XCTUnwrap(caller.instance?.exportedFunction(name: "baz"))
                    _ = try foo()
                    return []
                },
                "qux": Function(store: store, type: voidSignature) { caller, _ in
                    XCTAssertTrue(isExecutingFoo)
                    isQuxCalled = true
                    return []
                },
            ]
        ]
        let instance = try module.instantiate(store: store, imports: imports)
        // Check foo(wasm) -> bar(host) -> baz(wasm) -> qux(host)
        let foo = try XCTUnwrap(instance.exports[function: "foo"])
        try foo()
        XCTAssertTrue(isQuxCalled)
    }
}
