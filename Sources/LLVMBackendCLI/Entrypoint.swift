import ArgumentParser
import Foundation
import LLVMBackend
import SystemPackage

@main
struct Entrypoint: AsyncParsableCommand {
    @Argument(help: "Path to a `.wasm` file to operate on.")
    var path: String

    @Flag(name: [.long, .short])
    var verbose: Bool = false

    func run() async throws {
        let wasmPath =
            if FilePath(self.path).isAbsolute {
                FilePath(self.path)
            } else {
                FilePath(FileManager.default.currentDirectoryPath).appending(path)
            }

        print("wasmPath is \(wasmPath)")
        var context = CodegenContext(isVerbose: verbose)
        let objectFilePath = try context.emitObjectFile(wasmPath: wasmPath)
        let libraryFilePath = try await Linker.link(objectFilePath: objectFilePath)

        print("Linked library is at \(libraryFilePath.string)")

        let result = try Loader(memory: nil).load(
            library: libraryFilePath,
            entrypointSymbol: "1",
            arguments: U32Args2Result1(42, 24)
        )

        print("invocation result: \(result)")
    }
}
