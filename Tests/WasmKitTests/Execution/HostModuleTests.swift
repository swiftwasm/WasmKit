import XCTest

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
}
