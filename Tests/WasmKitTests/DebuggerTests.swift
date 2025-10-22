#if WasmDebuggingSupport

import Testing
import WAT
@testable import WasmKit

private let trivialModuleWAT = """
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

@Suite
struct DebuggerTests {
    @Test
    func stopAtEntrypoint() throws {
        let store = Store(engine: Engine())
        let bytes = try wat2wasm(trivialModuleWAT)
        print(bytes.count)
        let module = try parseWasm(bytes: bytes)
        var debugger = try Debugger(module: module, store: store, imports: [:])

        try debugger.stopAtEntrypoint()

        #expect(throws: Execution.Breakpoint.self) {
            try debugger.run()
        }
    }
}

#endif
