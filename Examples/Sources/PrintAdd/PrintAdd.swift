/// This example demonstrates how to import a function from the host environment and call it from a WebAssembly module.

import WasmKit
import WAT

@main
struct exampleExec {
    static func main() throws {
        // Convert a WAT file to a Wasm binary, then parse it.
        let module = try parseWasm(
            bytes: try wat2wasm(
                """
                (module
                  (import "printer" "print_i32" (func $print_i32 (param i32)))
                  (func (export "print_add") (param $x i32) (param $y i32)
                    (call $print_i32 (i32.add (local.get $x) (local.get $y)))
                  )
                )
                """
            )
        )

        // Define a host function that prints an i32 value.
        let hostPrint = HostFunction(type: FunctionType(parameters: [.i32])) { _, args in
            // This function is called from "print_add" in the WebAssembly module.
            print(args[0])
            return []
        }
        // Create a runtime importing the host function.
        let runtime = Runtime(hostModules: [
            "printer": HostModule(functions: ["print_i32": hostPrint])
        ])
        let instance = try runtime.instantiate(module: module)
        // Invoke the exported function "print_add"
        _ = try runtime.invoke(instance, function: "print_add", with: [.i32(42), .i32(3)])
    }
}
