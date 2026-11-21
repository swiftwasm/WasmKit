// This example demonstrates WASI support in WasmKit.

import WasmKit
import WasmKitWASI
import Foundation

@main
struct Example {
    static func main() throws {
        // Create an engine, and parse a WASI-compliant WebAssembly module from a file with it.
        let engine = Engine()
        let module = try parseWasm(filePath: "wasm/hello.wasm", engine: engine)

        // Create a WASI instance forwarding to the host environment.
        let wasi = try WASIBridgeToHost()
        // Start the WASI command-line application and close the bridge.
        let exitCode = try wasi.runAndClose { wasi in
            // Create a store of the module's engine
            let store = Store(engine: engine)
            // Instantiate a parsed module importing WASI
            var imports = Imports()
            try wasi.link(to: &imports, store: store)
            let instance = try module.instantiate(store: store, imports: imports)
            return try wasi.start(instance)
        }
        // Exit the Swift program with the WASI exit code.
        exit(Int32(exitCode))
    }
}
