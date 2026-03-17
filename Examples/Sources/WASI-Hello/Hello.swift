// This example demonstrates WASI support in WasmKit.

import WasmKit
import WasmKitWASI
import Foundation

@main
struct Example {
    static func main() throws {
        // Parse a WASI-compliant WebAssembly module from a file.
        let module = try parseWasm(filePath: "wasm/hello.wasm")

        // Create a WASI instance forwarding to the host environment,
        // run the module, and clean up file descriptors automatically.
        let exitCode = try WASIBridgeToHost.withBridge { wasi in
            let engine = Engine()
            let store = Store(engine: engine)
            var imports = Imports()
            wasi.link(to: &imports, store: store)
            let instance = try module.instantiate(store: store, imports: imports)
            return try wasi.start(instance)
        }
        // Exit the Swift program with the WASI exit code.
        exit(Int32(exitCode))
    }
}
