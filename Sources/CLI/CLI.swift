import ArgumentParser

@main
struct CLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WebAssembly Runtime written in Swift.",
        version: "0.0.8",
        subcommands: [Run.self, Explore.self]
    )
}
