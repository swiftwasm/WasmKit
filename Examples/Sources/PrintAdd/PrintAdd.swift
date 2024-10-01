/// This example demonstrates how to import a function from the host environment and call it from a WebAssembly module.

import WasmKit
import WAT

@main
struct Example {
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

        // Create engine and store
        let engine = Engine()
        let store = Store(engine: engine)

        // Instantiate a parsed module with importing a host function
        let instance = try module.instantiate(
            store: store,
            // Import a host function that prints an i32 value.
            imports: [
                "printer": [
                    "print_i32": Function(store: store, parameters: [.i32]) { _, args in
                        // This function is called from "print_add" in the WebAssembly module.
                        print(args[0])
                        return []
                    }
                ]
            ]
        )
        // Invoke the exported function "print_add"
        let printAdd = instance.exports[function: "print_add"]!
        try printAdd([.i32(42), .i32(3)])
    }
}
