#if WasmDebuggingSupport

    import WAT
    import WasmKitWASI

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    /// Runs `body` against a handler debugging `wat`, stopped at its entrypoint.
    ///
    /// Closes on both paths because WASIBridgeToHost's deinit preconditions on close() having run.
    func withHandler<R>(debugging wat: String, _ body: (WasmKitGDBHandler) throws -> R) throws -> R {
        let handler = try WasmKitGDBHandler(
            wasmBinary: try wat2wasm(wat),
            moduleFilePath: "/tmp/test.wasm",
            wasiConfiguration: WASIConfiguration(arguments: [], environment: [:], preopens: []),
            engineConfiguration: EngineConfiguration(),
            logger: .disabled
        )
        do {
            let result = try body(handler)
            try handler.close()
            return result
        } catch {
            try handler.close()
            throw error
        }
    }

#endif
