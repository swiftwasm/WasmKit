import ArgumentParser

struct CLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wakit",
        abstract: "WebAssembly Runtime written in Swift.",
        subcommands: [Run.self, Spectest.self]
    )
}

CLI.main()
