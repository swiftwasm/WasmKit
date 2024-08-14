import func Foundation.exit

var arguments = CommandLine.arguments

struct Subcommand {
    let name: String
    let description: String
    let handler: ([String]) throws -> Void
}

func main() throws {

    let subcommands: [Subcommand] = [
        Subcommand(name: "generate-internal-instruction", description: "Generate internal instruction code", handler: GenerateInternalInstruction.main),
        Subcommand(name: "generate-wasm-instruction", description: "Generate wasm instruction code", handler: GenerateWasmInstruction.main),
    ]

    func printAvailableSubcommands() {
        print("Available subcommands:")
        for subcommand in subcommands {
            print("  \(subcommand.name): \(subcommand.description)")
        }
    }

    guard arguments.count > 1 else {
        for subcommand in subcommands {
            try subcommand.handler([subcommand.name])
        }
        return
    }

    let subcommandName = arguments[1]
    guard let subcommand = subcommands.first(where: { $0.name == subcommandName }) else {
        print("Unknown subcommand: \(subcommandName)")
        printAvailableSubcommands()
        exit(1)
    }

    try subcommand.handler(Array(arguments.dropFirst(1)))

}

try main()
