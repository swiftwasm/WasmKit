import ArgumentParser

@main
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WebAssembly Runtime written in Swift.",
        version: "0.0.7",
        subcommands: [Run.self]
    )
}
