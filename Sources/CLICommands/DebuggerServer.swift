#if WasmDebuggingSupport && !os(Windows)

    import Foundation
    import GDBRemoteProtocol
    import WasmKit
    import WasmKitGDBHandler
    import WasmKitWASI

    struct DebuggerServer {
        var host = "127.0.0.1"
        var port: Int
        var logLevel = GDBLogLevel.info
        let wasmModulePath: String
        let engineConfiguration: EngineConfiguration
        let wasiConfiguration: WASIConfiguration

        func run() async throws {
            let logger = GDBLogger(logLevel: self.logLevel) { level, message in
                FileHandle.standardError.write(Data("[\(level)] \(message)\n".utf8))
            }

            guard let wasmBinary = FileManager.default.contents(atPath: self.wasmModulePath) else {
                throw CLIFile.Error(description: "Failed to read module: \(self.wasmModulePath)")
            }

            let debuggerHandler = try WasmKitGDBHandler(
                wasmBinary: [UInt8](wasmBinary),
                moduleFilePath: self.wasmModulePath,
                wasiConfiguration: self.wasiConfiguration,
                engineConfiguration: self.engineConfiguration,
                logger: logger
            )

            let listener = try TCPListener(host: self.host, port: self.port)
            defer { listener.close() }
            logger.trace("Debugger server listening on port \(port)")

            // A GDB stub serves one client. The guest advances only through that client's
            // packets and cannot be restarted, so a second one has nothing to attach to.
            let connection = try listener.accept()
            defer { connection.close() }

            var decoder = GDBHostCommandDecoder(logger: logger)
            let encoder = GDBTargetResponseEncoder(logger: logger)

            do {
                while let bytes = try connection.receive() {
                    decoder.feed(bytes)
                    while let packet = try decoder.next() {
                        let response = try debuggerHandler.handle(command: packet.payload)
                        try connection.send(encoder.encode(data: response))
                    }
                }
                logger.trace("Debugger disconnected")
                if debuggerHandler.detachesOnDisconnect {
                    try debuggerHandler.detach()
                }
            } catch WasmKitGDBHandler.Error.killRequestReceived {
                logger.trace("Debugger shut down request received")
            } catch {
                logger.error("Error in GDB remote protocol connection: \(error)")
            }
            try debuggerHandler.close()
        }
    }

#endif
