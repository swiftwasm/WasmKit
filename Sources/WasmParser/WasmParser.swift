import struct SystemPackage.FileDescriptor
import struct SystemPackage.FilePath

#if os(Windows)
    import ucrt
#endif

extension Parser where Stream == FileHandleStream {

    /// Initialize a new parser with the given file handle
    ///
    /// - Parameters:
    ///   - fileHandle: The file handle to the WebAssembly binary file to parse
    ///   - features: Enabled WebAssembly features for parsing
    public init(fileHandle: FileDescriptor, features: WasmFeatureSet = .default) throws {
        self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
    }

    /// Initialize a new parser with the given file path
    ///
    /// - Parameters:
    ///   - filePath: The file path to the WebAssembly binary file to parse
    ///   - features: Enabled WebAssembly features for parsing
    public init(filePath: FilePath, features: WasmFeatureSet = .default) throws {
        #if os(Windows)
            // TODO: Upstream `O_BINARY` to `SystemPackage
            let accessMode = FileDescriptor.AccessMode(
                rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
            )
        #else
            let accessMode: FileDescriptor.AccessMode = .readOnly
        #endif
        let fileHandle = try FileDescriptor.open(filePath, accessMode)
        self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
    }
}

/// Detect the type of a WebAssembly binary file by reading its header.
///
/// This function reads the 8-byte WebAssembly header to determine whether
/// the file contains a core module or a component. Uses stack allocation
/// only (no heap allocation for the header bytes).
///
/// - Parameter filePath: Path to the WebAssembly binary file
/// - Returns: The detected file type
/// - Throws: If the file cannot be opened or read
public func detectWasmFileType(filePath: FilePath) throws -> WasmFileType {
    let fileHandle = try FileDescriptor.open(filePath, .readOnly)
    defer { try? fileHandle.close() }

    // Use a tuple to avoid heap allocation - 8 bytes on stack
    // TODO: needs a `SmallArray` abstraction until `InlineArray` becomes available after dropping support for macOS 15.
    var header: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0)
    let bytesRead = try withUnsafeMutableBytes(of: &header) { buffer in
        try fileHandle.read(into: buffer)
    }

    // Need at least 8 bytes for a valid header
    guard bytesRead >= 8 else {
        return .unknown
    }

    // Check magic number: \0asm (uses WASM_MAGIC as source of truth)
    guard
        header.0 == WASM_MAGIC[0] && header.1 == WASM_MAGIC[1]
            && header.2 == WASM_MAGIC[2] && header.3 == WASM_MAGIC[3]
    else {
        return .unknown
    }

    // Check version and layer bytes:
    // - Core module: version=0x01, 0x00 and layer=0x00, 0x00
    // - Component:   version=0x0d, 0x00 and layer=0x01, 0x00
    switch (header.4, header.5, header.6, header.7) {
    case (0x01, 0x00, 0x00, 0x00):
        return .coreModule
    case (0x0d, 0x00, 0x01, 0x00):
        return .component
    default:
        return .unknown
    }
}
