import ArgumentParser

@main
struct CLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WasmKit WebAssembly Runtime",
        version: "0.1.6",
        subcommands: [Run.self, Explore.self]
    )
}
