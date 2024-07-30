import WAT
import XCTest

@testable import WasmKit
@testable import WasmParser

final class HostModuleTests: XCTestCase {
    func testImportMemory() throws {
        let runtime = Runtime()
        let memoryType = MemoryType(min: 1, max: nil)
        let memoryAddr = runtime.store.allocate(memoryType: memoryType)
        try runtime.store.register(HostModule(memories: ["memory": memoryAddr]), as: "env")

        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (import "env" "memory" (memory 1))
                )
                """))
        XCTAssertNoThrow(try runtime.instantiate(module: module))
        // Ensure the allocated address is valid
        _ = runtime.store.memory(at: memoryAddr)
    }

    func testReentrancy() throws {
        let runtime = Runtime()
        let voidSignature = WasmParser.FunctionType(parameters: [], results: [])
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
        let hostModule = HostModule(
            functions: [
                "bar": HostFunction(type: voidSignature) { caller, _ in
                    // Ensure "invoke" executes instructions under the current call
                    XCTAssertFalse(isExecutingFoo, "bar should not be called recursively")
                    isExecutingFoo = true
                    defer { isExecutingFoo = false }
                    let foo = try XCTUnwrap(caller.instance?.exportedFunction(name: "baz"))
                    _ = try foo.invoke([], runtime: caller.runtime)
                    return []
                },
                "qux": HostFunction(type: voidSignature) { _, _ in
                    XCTAssertTrue(isExecutingFoo)
                    isQuxCalled = true
                    return []
                },
            ]
        )
        try runtime.store.register(hostModule, as: "env")
        let instance = try runtime.instantiate(module: module)
        // Check foo(wasm) -> bar(host) -> baz(wasm) -> qux(host)
        _ = try runtime.invoke(instance, function: "foo")
        XCTAssertTrue(isQuxCalled)
    }
}
