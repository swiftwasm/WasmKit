#if FileSystem
    import WasmParser

    /// Parse a given file as a WebAssembly binary format file
    ///
    /// Registers the module's types in `engine`. The module can only be instantiated in a ``Store`` of `engine`.
    ///
    /// - Throws: `WasmKitError` if the binary is malformed, if a type refers to a type defined in a later recursion
    ///   group or declares an invalid supertype, or if `engine` would hold more than
    ///   ``EngineConfiguration/maxTypeCount`` types.
    ///
    /// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
    public func parseWasm(filePath: String, engine: Engine, features: WasmFeatureSet = .default) throws -> Module {
        let parser = try WasmParser.Parser(filePath: filePath, features: features)
        return try parseModule(parser: parser, engine: engine, features: features)
    }

    @available(*, unavailable, renamed: "parseWasm(filePath:engine:features:)")
    public func parseWasm(filePath: String, features: WasmFeatureSet = .default) throws -> Module {
        fatalError()
    }

    /// Parse a WebAssembly binary from a caller-owned platform file descriptor.
    ///
    /// The descriptor must be opened for reading in binary mode. This function
    /// *borrows* it: ownership stays with the caller, who must close it after
    /// the call returns. Bytes are consumed starting from the descriptor's
    /// current offset.
    ///
    /// Registers the module's types in `engine`. The module can only be instantiated in a ``Store`` of `engine`.
    ///
    /// - Throws: `WasmKitError` if the binary is malformed, if a type refers to a type defined in a later recursion
    ///   group or declares an invalid supertype, or if `engine` would hold more than
    ///   ``EngineConfiguration/maxTypeCount`` types.
    public func parseWasm(fileHandle: CInt, engine: Engine, features: WasmFeatureSet = .default) throws -> Module {
        let parser = try WasmParser.Parser(fileHandle: fileHandle, features: features)
        let module = try parseModule(parser: parser, engine: engine, features: features)
        return module
    }

    @available(*, unavailable, renamed: "parseWasm(fileHandle:engine:features:)")
    public func parseWasm(fileHandle: CInt, features: WasmFeatureSet = .default) throws -> Module {
        fatalError()
    }
#endif
