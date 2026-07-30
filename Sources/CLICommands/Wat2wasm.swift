import ArgumentParser
import Foundation
import WAT
import WasmTypes

#if ComponentModel
    private let wat2wasmDiscussion = """
        Parse a file in WebAssembly Text Format (`.wat`), \
        assemble it into a binary, and write the result to a given \
        file path.

        Supports both core modules and Component Model components.
        """
#else
    private let wat2wasmDiscussion = """
        Parse a file in WebAssembly Text Format (`.wat`), \
        assemble it into a binary, and write the result to a given \
        file path.
        """
#endif

package struct Wat2wasm: ParsableCommand {
    package static let configuration = CommandConfiguration(
        abstract: "Assemble WebAssembly text into a WebAssembly binary",
        discussion: wat2wasmDiscussion
    )

    enum Error: Swift.Error, CustomStringConvertible {
        case unknownFileExtension(String?)
        case fileAlreadyExists(String)

        var description: String {
            switch self {
            case .unknownFileExtension(let ext):
                if let ext {
                    """
                    File extension `\(ext)` is not supported. Provide a file \
                    with `.wat` extension.
                    """
                } else {
                    "Provide a file with `.wat` extension."
                }

            case .fileAlreadyExists(let path):
                """
                File at path `\(path)` already exists. Remove the file or provide \
                an output path explicitly.
                """
            }
        }
    }

    @Argument(help: "Path to a WebAssembly Text Format (`.wat`) file to parse.")
    var path: String

    @Option(
        name: [.short, .long],
        help: """
            Path to a WebAssembly Binary (`.wasm`) output file path. If already exists, \
            previous content of this file is replaced with a new WebAssembly binary.

            If output file path is not provided via this option, output is written to a \
            file with the same base name as the input text file, but with `.wasm` extension.

            E.g. `fib.wat` is assembled into a peer `fib.wasm` in the same directory as \
            `fib.wat` if output path is not provided. If `fib.wasm` already exists, an \
            error is thrown. Specify the output file path explicitly via this option \
            to replace the existing file.
            """
    )
    var output: String?

    @Flag(
        inversion: .prefixedEnableDisable,
        help: "Include the name section in the output binary."
    )
    var nameSection: Bool = true

    package init() {}

    package func run() throws {
        let fileURL = URL(fileURLWithPath: path)
        guard fileURL.pathExtension == "wat" else { throw Error.unknownFileExtension(fileURL.pathExtension) }
        let wat = try String(contentsOfFile: path, encoding: .utf8)

        let wasm = try wat2wasm(wat, options: EncodeOptions(nameSection: nameSection))

        let outputPath: String

        if let output {
            outputPath = output
        } else {
            outputPath = fileURL.deletingPathExtension().appendingPathExtension("wasm").path

            guard !FileManager.default.fileExists(atPath: outputPath) else {
                throw Error.fileAlreadyExists(outputPath)
            }
        }

        let outputHandle = try CLIFile.createWrite(outputPath)
        try withThrowing {
            try outputHandle.write(contentsOf: wasm)
        } defer: {
            try outputHandle.close()
        }
    }
}
