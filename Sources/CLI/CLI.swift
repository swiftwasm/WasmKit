import ArgumentParser

@main
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WasmKit WebAssembly Runtime",
        version: "0.1.6",
        subcommands: [
            Explore.self,
            Run.self,
            Wat2wasm.self,
        ]
    )
}
