/// This example demonstrates how to call a function exported by a WebAssembly module.

import WasmKit
import WAT
import Foundation

@main
struct exampleExec {
    static func main() throws {
        // Convert a WAT file to a Wasm binary, then parse it.
        let module = try parseWasm(
            bytes: try wat2wasm(String(contentsOfFile: "wasm/factorial.wat"))
        )

        // Create a module instance from the parsed module.
        let runtime = Runtime()
        let instance = try runtime.instantiate(module: module)
        let input: UInt64 = 5
        // Invoke the exported function "fac" with a single argument.
        let result = try runtime.invoke(instance, function: "fac", with: [.i64(input)])
        print("fac(\(input)) = \(result[0].i64)")
    }
}
