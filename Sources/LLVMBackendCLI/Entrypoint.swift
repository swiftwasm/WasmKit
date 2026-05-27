import ArgumentParser
import CLICommands
import Foundation
import LLVMBackend
import SystemPackage

@main
struct Entrypoint: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wasmkit",
        abstract: "WasmKit LLVM Backend",
        subcommands: [
            Run.self,
            Wat2wasm.self,
        ]
    )
}

struct Run: AsyncParsableCommand {
    @Argument(help: "Path to a `.wasm` file to operate on.")
    var path: String

    @Flag(name: [.long, .short])
    var verbose: Bool = false

    @Argument(
        parsing: .captureForPassthrough,
        help: ArgumentHelp(
            "Name of an exported function to call with space-separated function arguments encoded as `<type>:<value>`, e.g. `i32:42`",
            valueName: "arguments"
        )
    )
    var arguments: [String] = []

    func run() async throws {
        let wasmPath =
            if FilePath(self.path).isAbsolute {
                FilePath(self.path)
            } else {
                FilePath(FileManager.default.currentDirectoryPath).appending(path)
            }

        var context = CodegenContext(isVerbose: verbose)
        let objectFilePath = try context.emitObjectFile(wasmPath: wasmPath)
        let libraryFilePath = try await Linker.link(objectFilePath: objectFilePath)

        let (functionName, functionArguments) = CLICommands.Run.parseInvocation(arguments: self.arguments)

        guard let functionName, functionArguments.count == 1, case .i64(let functionArgument) = functionArguments.first else {
            fatalError("Only single-parameter i64 entrypoint functions are currently supported. Arguments passed: \(functionArguments)")
        }

        let result = try Loader(memory: nil).load(
            library: libraryFilePath,
            entrypointSymbol: functionName,
            arguments: U64Args1Result1(functionArgument)
        )

        print(result)
    }
}
