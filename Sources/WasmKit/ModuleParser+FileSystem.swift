#if FileSystem
    import WasmParser
    import SystemExtras
    import SystemPackage

    #if os(Windows)
        import ucrt
    #endif

    /// Parse a given file as a WebAssembly binary format file
    /// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
    public func parseWasm(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module {
        #if os(Windows)
            // TODO: Upstream `O_BINARY` to `SystemPackage
            let accessMode = FileDescriptor.AccessMode(
                rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
            )
        #else
            let accessMode: FileDescriptor.AccessMode = .readOnly
        #endif
        let fileHandle = try FileDescriptor.open(filePath, accessMode)
        return try withThrowing {
            try parseWasm(fileHandle: fileHandle, features: features)
        } defer: {
            try fileHandle.close()
        }
    }

    /// Parse a WebAssembly binary file from a caller-owned file descriptor.
    ///
    /// The descriptor is consumed from its current offset and is not closed by
    /// this function.
    public func parseWasm(fileHandle: FileDescriptor, features: WasmFeatureSet = .default) throws -> Module {
        let stream = try FileHandleStream(fileHandle: fileHandle)
        let module = try parseModule(stream: stream, features: features)
        return module
    }
#endif
