#if FileSystem
    import WasmParser

    /// Parse a given file as a WebAssembly binary format file
    /// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
    public func parseWasm(filePath: String, features: WasmFeatureSet = .default) throws -> Module {
        let parser = try WasmParser.Parser(filePath: filePath, features: features)
        return try parseModule(parser: parser, features: features)
    }

    /// Parse a WebAssembly binary from a caller-owned platform file descriptor.
    ///
    /// The descriptor must be opened for reading in binary mode. This function
    /// *borrows* it: ownership stays with the caller, who must close it after
    /// the call returns. Bytes are consumed starting from the descriptor's
    /// current offset.
    public func parseWasm(fileHandle: CInt, features: WasmFeatureSet = .default) throws -> Module {
        let parser = try WasmParser.Parser(fileHandle: fileHandle, features: features)
        let module = try parseModule(parser: parser, features: features)
        return module
    }
#endif
