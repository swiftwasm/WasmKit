import ArgumentParser
import Foundation
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
        if let output {
            let outputHandle = try CLIFile.createWrite(output)
            do {
                try wasm2wat(source, features: .all) { try outputHandle.writeAll(Array($0.utf8)) }
            } catch {
                // Report the conversion error rather than a failure to close.
                try? outputHandle.close()
                throw error
            }
            try outputHandle.close()
        } else {
            try wasm2wat(source, features: .all) { try FileHandle.standardOutput.write(contentsOf: Data($0.utf8)) }
        }
    }
}
