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
            logger.info("Debugger server listening on port \(port)")

            // A GDB stub serves one client at a time: accept connections
            // sequentially until the client asks the target to shut down.
            serving: while true {
                let connection = try listener.accept()
                defer { connection.close() }

                var decoder = GDBHostCommandDecoder(logger: logger)
                let encoder = GDBTargetResponseEncoder(logger: logger)

                do {
                    while let bytes = try connection.receive() {
                        decoder.feed(bytes)
                        while let packet = try decoder.next() {
                            let response = try await debuggerHandler.handle(command: packet.payload)
                            try connection.send(encoder.encode(data: response))
                        }
                    }
                } catch WasmKitGDBHandler.Error.killRequestReceived {
                    logger.info("Debugger shut down request received")
                    break serving
                } catch {
                    logger.error("Error in GDB remote protocol connection: \(error)")
                }
            }
            try await debuggerHandler.close()
        }
    }

#endif
