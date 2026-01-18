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
