import ArgumentParser
import WAT
import WasmParser

package struct Wasm2wat: ParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "wasm2wat",
        abstract: "Disassemble a WebAssembly binary into WebAssembly text format"
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
            try CLIFile.write(to: outputPath) { outputHandle in
                try wasm2wat(source, features: .all, to: &outputHandle)
            }
        } else {
            var standardOutput = CLIFile.standardOutput
            try wasm2wat(source, features: .all, to: &standardOutput)
            try standardOutput.flush()
        }
    }
}
