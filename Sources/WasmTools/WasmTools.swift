import Foundation
import WASI
import WasmKit
import WasmKitWASI

#if os(Windows)
    import ucrt
#endif

/// Default path to wasm-tools.wasm in the Vendor directory
package let defaultWasmToolsPath: String = {
    let sourceFileURL = URL(fileURLWithPath: #filePath)
    let rootPath =
        sourceFileURL
        .deletingLastPathComponent()  // WasmTools
        .deletingLastPathComponent()  // Sources
        .deletingLastPathComponent()  // Root
    let vendorPath = rootPath.appendingPathComponent("Vendor")
    return
        vendorPath
        .appendingPathComponent("wasm-tools-prebuilt/wasm-tools-1.244.0-wasm32-wasip1/wasm-tools.wasm")
        .path
}()

// MARK: - Input/Output Types

/// Input file for wasm-tools execution
package struct WasmToolsInputFile {
    package let guestPath: String
    package let content: [UInt8]

    package init(guestPath: String, content: [UInt8]) {
        self.guestPath = guestPath
        self.content = content
    }

    package init(guestPath: String, content: String) {
        self.guestPath = guestPath
        self.content = Array(content.utf8)
    }
}

/// Output file from wasm-tools execution
package struct WasmToolsOutputFile {
    package let guestPath: String
    package let content: [UInt8]

    package init(guestPath: String, content: [UInt8]) {
        self.guestPath = guestPath
        self.content = content
    }
}

/// Result of running wasm-tools with in-memory filesystem
package struct WasmToolsResult {
    package let stdout: [UInt8]
    package let stderr: [UInt8]
    package let exitCode: Int32
    package let outputFiles: [WasmToolsOutputFile]

    package var stdoutString: String {
        String(decoding: stdout, as: UTF8.self)
    }

    package var stderrString: String {
        String(decoding: stderr, as: UTF8.self)
    }
}

/// Context for running wasm-tools with full control over the memory filesystem
package final class WasmToolsContext {
    package let memoryFS: MemoryFileSystem

    package init() throws {
        self.memoryFS = try MemoryFileSystem()
    }

    /// Adds an input file to the virtual filesystem
    package func addInputFile(_ file: WasmToolsInputFile) throws {
        try memoryFS.addFile(at: file.guestPath, content: file.content)
    }

    /// Retrieves a file from the virtual filesystem
    package func getFile(at path: String) throws -> [UInt8] {
        let content = try memoryFS.getFile(at: path)
        switch content {
        case .bytes(let bytes):
            return bytes
        case .handle:
            throw WasmToolsError.fileNotFound(path: path)
        }
    }
}

package func runWasmTools(
    wasmToolsPath: String = defaultWasmToolsPath,
    args: [String],
    inputFiles: [WasmToolsInputFile],
    outputPaths: [String] = []
) throws -> WasmToolsResult {
    let context = try WasmToolsContext()

    for inputFile in inputFiles {
        try context.addInputFile(inputFile)
    }

    return try runWasmTools(
        wasmToolsPath: wasmToolsPath,
        args: args,
        context: context,
        outputPaths: outputPaths
    )
}

/// Runs wasm-tools.wasm with an existing context
package func runWasmTools(
    wasmToolsPath: String = defaultWasmToolsPath,
    args: [String],
    context: WasmToolsContext,
    outputPaths: [String] = []
) throws -> WasmToolsResult {
    guard FileManager.default.fileExists(atPath: wasmToolsPath) else {
        throw WasmToolsError.wasmToolsNotFound(path: wasmToolsPath)
    }

    let stdoutPipe = try CapturePipe()
    let stderrPipe = try CapturePipe()

    defer {
        stdoutPipe.closeRead()
        stdoutPipe.closeWrite()
        stderrPipe.closeRead()
        stderrPipe.closeWrite()
    }

    let fileSystemOptions = WASIBridgeToHost.FileSystemOptions.memory(context.memoryFS)
        .withStdio(
            stdin: 0,
            stdout: stdoutPipe.writeDescriptor,
            stderr: stderrPipe.writeDescriptor
        )
        .withPreopens([.init(guestPath: "/", hostPath: "/")])

    let wasi = try WASIBridgeToHost(
        args: ["wasm-tools"] + args,
        environment: [:],
        fileSystem: fileSystemOptions
    )

    let exitCode = try wasi.runAndClose { wasi in
        let engine = Engine()
        let store = Store(engine: engine)
        var imports = Imports()
        wasi.link(to: &imports, store: store)

        let module = try parseWasm(filePath: wasmToolsPath)
        let instance = try module.instantiate(store: store, imports: imports)
        return try wasi.start(instance)
    }

    stdoutPipe.closeWrite()
    stderrPipe.closeWrite()

    let stdoutBytes = try stdoutPipe.readToEnd()
    let stderrBytes = try stderrPipe.readToEnd()

    var outputFiles: [WasmToolsOutputFile] = []
    for path in outputPaths {
        if let bytes = try? context.getFile(at: path) {
            outputFiles.append(WasmToolsOutputFile(guestPath: path, content: bytes))
        }
    }

    return WasmToolsResult(
        stdout: stdoutBytes,
        stderr: stderrBytes,
        exitCode: Int32(exitCode),
        outputFiles: outputFiles
    )
}

/// A host pipe used to capture the guest's stdout/stderr as a raw file
/// descriptor. Foundation's `Pipe` is not usable for this on Windows, where
/// `FileHandle.fileDescriptor` is unavailable; use the CRT's `_pipe` there.
private final class CapturePipe {
    #if os(Windows)
        private let readEnd: CInt
        private let writeEnd: CInt
        private var readClosed = false
        private var writeClosed = false

        init() throws {
            var fds: [CInt] = [-1, -1]
            guard _pipe(&fds, 4096, _O_BINARY) == 0 else {
                throw WasmToolsError.pipeCreationFailed
            }
            self.readEnd = fds[0]
            self.writeEnd = fds[1]
        }

        var writeDescriptor: CInt { writeEnd }

        func closeRead() {
            guard !readClosed else { return }
            readClosed = true
            _ = _close(readEnd)
        }

        func closeWrite() {
            guard !writeClosed else { return }
            writeClosed = true
            _ = _close(writeEnd)
        }

        func readToEnd() throws -> [UInt8] {
            var bytes: [UInt8] = []
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = buffer.withUnsafeMutableBytes {
                    _read(readEnd, $0.baseAddress, 4096)
                }
                guard count > 0 else { break }
                bytes.append(contentsOf: buffer.prefix(Int(count)))
            }
            return bytes
        }
    #else
        private let pipe = Pipe()
        private var readClosed = false
        private var writeClosed = false

        init() throws {}

        var writeDescriptor: CInt { pipe.fileHandleForWriting.fileDescriptor }

        func closeRead() {
            guard !readClosed else { return }
            readClosed = true
            try? pipe.fileHandleForReading.close()
        }

        func closeWrite() {
            guard !writeClosed else { return }
            writeClosed = true
            try? pipe.fileHandleForWriting.close()
        }

        func readToEnd() throws -> [UInt8] {
            [UInt8](try pipe.fileHandleForReading.readToEnd() ?? Data())
        }
    #endif
}

/// Errors that can occur when running wasm-tools
package enum WasmToolsError: Error, CustomStringConvertible {
    case wasmToolsNotFound(path: String)
    case executionFailed(exitCode: Int32, stderr: String)
    case fileNotFound(path: String)
    case pipeCreationFailed

    package var description: String {
        switch self {
        case .wasmToolsNotFound(let path):
            return "wasm-tools.wasm not found at \(path)"
        case .executionFailed(let exitCode, let stderr):
            return "wasm-tools failed with exit code \(exitCode): \(stderr)"
        case .fileNotFound(let path):
            return "File not found at \(path)"
        case .pipeCreationFailed:
            return "Failed to create a pipe for capturing wasm-tools output"
        }
    }
}

// MARK: - JSON Types for wast2json output

package struct WAST2JSONOutput: Codable {
    package let sourceFilename: String
    package let commands: [WAST2JSONCommand]

    enum CodingKeys: String, CodingKey {
        case sourceFilename = "source_filename"
        case commands
    }
}

/// A command from the wast2json output
package struct WAST2JSONCommand: Codable {
    package let type: String
    package let line: Int
    package let filename: String?
    package let name: String?
    package let text: String?
    package let moduleType: String?

    enum CodingKeys: String, CodingKey {
        case type
        case line
        case filename
        case name
        case text
        case moduleType = "module_type"
    }
}

package func wast2json(
    wasmToolsPath: String = defaultWasmToolsPath,
    wastContent: [UInt8],
    wastFileName: String = "input.wast"
) throws -> (json: WAST2JSONOutput, wasmFiles: [String: [UInt8]]) {
    let inputPath = "/input/\(wastFileName)"
    let outputDir = "/output"

    let context = try WasmToolsContext()
    try context.addInputFile(WasmToolsInputFile(guestPath: inputPath, content: wastContent))
    try context.memoryFS.ensureDirectory(at: outputDir)

    let result = try runWasmTools(
        wasmToolsPath: wasmToolsPath,
        args: ["json-from-wast", inputPath, "--wasm-dir", outputDir],
        context: context,
        outputPaths: []
    )

    guard result.exitCode == 0 else {
        throw WasmToolsError.executionFailed(exitCode: result.exitCode, stderr: result.stderrString)
    }

    let jsonOutput = try JSONDecoder().decode(WAST2JSONOutput.self, from: Data(result.stdout))

    var wasmFiles: [String: [UInt8]] = [:]
    for command in jsonOutput.commands {
        if let filename = command.filename {
            let filePath = "\(outputDir)/\(filename)"
            if let bytes = try? context.getFile(at: filePath) {
                wasmFiles[filename] = bytes
            }
        }
    }

    return (jsonOutput, wasmFiles)
}

package func wasm2wat(
    wasmToolsPath: String = defaultWasmToolsPath,
    wasmContent: [UInt8]
) throws -> String {
    let inputPath = "/input.wasm"

    let result = try runWasmTools(
        wasmToolsPath: wasmToolsPath,
        args: ["print", inputPath],
        inputFiles: [WasmToolsInputFile(guestPath: inputPath, content: wasmContent)],
        outputPaths: []
    )

    guard result.exitCode == 0 else {
        throw WasmToolsError.executionFailed(exitCode: result.exitCode, stderr: result.stderrString)
    }

    return result.stdoutString
}

package func wat2wasm(
    wasmToolsPath: String = defaultWasmToolsPath,
    watContent: [UInt8]
) throws -> [UInt8] {
    let inputPath = "/input.wat"
    let outputPath = "/output.wasm"

    let context = try WasmToolsContext()
    try context.addInputFile(WasmToolsInputFile(guestPath: inputPath, content: watContent))

    let result = try runWasmTools(
        wasmToolsPath: wasmToolsPath,
        args: ["parse", inputPath, "-o", outputPath],
        context: context,
        outputPaths: [outputPath]
    )

    guard result.exitCode == 0 else {
        throw WasmToolsError.executionFailed(exitCode: result.exitCode, stderr: result.stderrString)
    }

    guard let outputFile = result.outputFiles.first else {
        throw WasmToolsError.fileNotFound(path: outputPath)
    }

    return outputFile.content
}

/// Normalizes WAT to canonical form
package func normalizeWat(
    wasmToolsPath: String = defaultWasmToolsPath,
    watContent: [UInt8]
) throws -> String {
    let inputPath = "/input.wat"

    let result = try runWasmTools(
        wasmToolsPath: wasmToolsPath,
        args: ["parse", "-t", inputPath],
        inputFiles: [WasmToolsInputFile(guestPath: inputPath, content: watContent)],
        outputPaths: []
    )

    guard result.exitCode == 0 else {
        throw WasmToolsError.executionFailed(exitCode: result.exitCode, stderr: result.stderrString)
    }

    return result.stdoutString
}
