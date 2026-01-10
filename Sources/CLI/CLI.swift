import ArgumentParser
import CLICommands

@main
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WasmKit WebAssembly Runtime",
        version: "0.2.0",
        subcommands: [
            Explore.self,
            Run.self,
            Wat2wasm.self,
        ]
    )
}
