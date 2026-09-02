#if WasmDebuggingSupport

    import WasmKitWASI

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    /// Runs `body` against a handler debugging `wasmBinary`, stopped at its entrypoint.
    ///
    /// Closes on both paths because WASIBridgeToHost's deinit preconditions on close() having run.
    func withDebuggedHandler(debugging wasmBinary: [UInt8], _ body: (WasmKitGDBHandler) throws -> Void) throws {
        let handler = try WasmKitGDBHandler(
            wasmBinary: wasmBinary,
            moduleFilePath: "/tmp/test.wasm",
            wasiConfiguration: WASIConfiguration(arguments: [], environment: [:], preopens: []),
            engineConfiguration: EngineConfiguration(),
            logger: .disabled
        )
        do {
            try body(handler)
            try handler.close()
        } catch {
            try handler.close()
            throw error
        }
    }

#endif
