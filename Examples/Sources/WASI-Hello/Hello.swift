// This example demonstrates WASI support in WasmKit.

import WasmKit
import WasmKitWASI
import Foundation

@main
struct Example {
    static func main() throws {
        // Parse a WASI-compliant WebAssembly module from a file.
        let module = try parseWasm(filePath: "wasm/hello.wasm")

        // Create a WASI instance forwarding to the host environment.
        let wasi = try WASIBridgeToHost()
        // Create a runtime with WASI host modules.
        let runtime = Runtime(hostModules: wasi.hostModules)
        let instance = try runtime.instantiate(module: module)

        // Start the WASI command-line application.
        let exitCode = try wasi.start(instance, runtime: runtime)
        // Exit the Swift program with the WASI exit code.
        exit(Int32(exitCode))
    }
}
