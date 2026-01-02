import ArgumentParser
import SystemPackage
import WAT
import WasmKit

struct Assemble: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Assemble WebAssembly text into a WebAssembly binary",
        discussion: """
            This command parses a file in WebAssembly Text Format (`.wat`), \
            assembles it into a binary, and writes the result to a given \
            file path.
            """
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

    func run() throws {
        let filePath = FilePath(path)
        guard filePath.extension == "wat" else { throw Error.unknownFileExtension(filePath.extension) }
        let fileHandle = try FileDescriptor.open(filePath, .readOnly)
        defer { try? fileHandle.close() }

        let size = try fileHandle.seek(offset: 0, from: .end)

        let wat = try String(unsafeUninitializedCapacity: Int(size)) {
            try fileHandle.read(fromAbsoluteOffset: 0, into: .init($0))
        }

        let wasm = try wat2wasm(wat)
        var outputPath: FilePath

        if let output {
            outputPath = FilePath(output)
        } else {
           outputPath = filePath
           outputPath.extension = "wasm"

           guard (try? FileDescriptor.open(outputPath, .readOnly)) == nil else {
               throw Error.fileAlreadyExists(outputPath.string)
           }
        }

        let outputHandle = try FileDescriptor.open(
            outputPath,
            .writeOnly,
            options: [.create],
            permissions: [.ownerReadWrite, .groupRead, .otherRead]
        )
        defer { try? outputHandle.close() }

        try outputHandle.writeAll(wasm)

        print("✅ Wasm binary successfully assembled and written to `\(outputPath.string)`.")
    }
}
