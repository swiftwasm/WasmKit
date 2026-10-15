import ArgumentParser
import WASI
import WAT
import WasmParser

package struct Wasm2wat: ParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "wasm2wat",
        abstract: "Disassemble a WebAssembly binary into WebAssembly text format",
        discussion: "Every WebAssembly proposal WasmKit can decode is enabled."
    )

    @Argument(help: "Path to a WebAssembly binary (`.wasm`) file to disassemble.")
    var path: String

    @Option(
        name: [.short, .long],
        help: """
            Path to the output WebAssembly Text Format (`.wat`) file.
            If not provided, the text is written to standard output.
            """
    )
    var output: String?

    package init() {}

    package func run() throws {
        let source = try FileHandleStreamSource(filePath: path)
        if let outputPath = output {
            var outputHandle = try CLIFile.createWrite(outputPath)
            try withThrowing {
                try wasm2wat(source, features: .all, to: &outputHandle)
                try outputHandle.flush()
            } defer: {
                try outputHandle.close()
            }
        } else {
            var standardOutput = CLIFile.standardOutput
            try wasm2wat(source, features: .all, to: &standardOutput)
            try standardOutput.flush()
        }
    }
}
