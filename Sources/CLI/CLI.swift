import ArgumentParser
import CLICommands

@main
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WasmKit WebAssembly Runtime",
        version: "0.4.0",
        subcommands: [
            Explore.self,
            Run.self,
            WAST.self,
            Wat2wasm.self,
        ]
    )
}
