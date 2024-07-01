import XCTest
@testable import WasmParser

@testable import WasmKit

final class HostModuleTests: XCTestCase {
    func testImportMemory() throws {
        let runtime = Runtime()
        let memoryType = MemoryType(min: 1, max: nil)
        let memoryAddr = runtime.store.allocate(memoryType: memoryType)
        try runtime.store.register(HostModule(memories: ["memory": memoryAddr]), as: "env")

        let module = Module(
            imports: [
                Import(module: "env", name: "memory", descriptor: .memory(memoryType))
            ]
        )
        XCTAssertNoThrow(try runtime.instantiate(module: module))
        // Ensure the allocated address is valid
        _ = runtime.store.memory(at: memoryAddr)
    }

    func testReentrancy() throws {
        let runtime = Runtime()
        let voidSignature = WasmParser.FunctionType(parameters: [], results: [])
        let module = Module(
            types: [voidSignature],
            functions: [
                // [0] (import "env" "bar" func)
                // [1] (import "env" "qux" func)
                // [2] "foo"
                GuestFunction(
                    type: 0, locals: [],
                    body: {
                        [
                            .call(functionIndex: 0),
                            .call(functionIndex: 0),
                            .call(functionIndex: 0),
                        ]
                    }),
                // [3] "bar"
                GuestFunction(
                    type: 0, locals: [],
                    body: {
                        [
                            .call(functionIndex: 1)
                        ]
                    }),
            ],
            imports: [
                Import(module: "env", name: "bar", descriptor: .function(0)),
                Import(module: "env", name: "qux", descriptor: .function(0)),
            ],
            exports: [
                Export(name: "foo", descriptor: .function(2)),
                Export(name: "baz", descriptor: .function(3)),
            ]
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
                    let foo = try XCTUnwrap(caller.instance.exportedFunction(name: "baz"))
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
