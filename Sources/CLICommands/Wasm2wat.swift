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
                try wasm2wat(source, features: .all) { text throws(WasmParserError) in
                    try Self.write { try outputHandle.writeAll(Array(text.utf8)) }
                }
            } catch {
                // Report the conversion error rather than a failure to close.
                try? outputHandle.close()
                throw error
            }
            try outputHandle.close()
        } else {
            try wasm2wat(source, features: .all) { text throws(WasmParserError) in
                try Self.write { try FileHandle.standardOutput.write(contentsOf: Data(text.utf8)) }
            }
        }
    }

    /// Runs `write`, reporting its failure as an I/O error the way WasmParser reports failed reads.
    private static func write(_ write: () throws -> Void) throws(WasmParserError) {
        do {
            try write()
        } catch {
            throw WasmParserError("I/O error: \(error)")
        }
    }
}
