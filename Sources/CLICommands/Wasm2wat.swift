import ArgumentParser
import SystemPackage
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

    @OptionGroup var featureOptions: WasmFeatureOptions

    package init() {}

    package func run() throws {
        let filePath = FilePath(path)
        let fileHandle = try FileDescriptor.open(filePath, .readOnly)
        defer { try? fileHandle.close() }

        let stream = try FileHandleStream(fileHandle: fileHandle)

        let wat = try wasm2wat(stream, features: featureOptions.wasmFeatures)

        if let outputPath = output {
            let outPath = FilePath(outputPath)
            let outHandle = try FileDescriptor.open(
                outPath,
                .writeOnly,
                options: [.create, .truncate],
                permissions: [.ownerReadWrite, .groupRead, .otherRead]
            )
            defer { try? outHandle.close() }
            try outHandle.writeAll(Array(wat.utf8))
        } else {
            print(wat)
        }
    }
}
