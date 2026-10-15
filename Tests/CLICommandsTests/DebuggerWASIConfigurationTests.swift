#if WasmDebuggingSupport && (os(macOS) || os(Linux))

    import Foundation
    import GDBRemoteProtocol
    import Testing
    import WAT
    import WasmKit
    import WASI
    import WasmKitGDBHandler
    import WasmKitWASI

    import CLICommands

    @Suite struct DebuggerWASIConfigurationTests {
        @Test func debuggeeSeesMappedPreopenAndOverriddenArgv0() async throws {
            try await PreopenFixture.withProbeDirectory { directory in
                let modulePath = directory.appendingPathComponent("fixture.wasm")
                try Data(wat2wasm(PreopenFixture.fixtureSource())).write(to: modulePath)

                let argv0 = "/cross-build/wasm32/python.wasm"
                let run = try Run.parse([
                    "--dir", "\(directory.path)::/",
                    "--argv0", argv0,
                    modulePath.path,
                    argv0, "/", "probe.txt", PreopenFixture.fixtureContents,
                ])
                let handler = try WasmKitGDBHandler(
                    wasmBinary: [UInt8](try Data(contentsOf: modulePath)),
                    moduleFilePath: modulePath.path,
                    wasiConfiguration: try run.deriveWASIConfiguration(),
                    engineConfiguration: EngineConfiguration(),
                    logger: .disabled
                )
                // The handler is a plain class, so its calls are synchronous
                // and need no @Sendable closure.
                try withThrowing {
                    let response = try handler.handle(
                        command: GDBHostCommand(kind: .continue, arguments: "")
                    )
                    guard case .string(let payload) = response.kind else {
                        Issue.record("unexpected response kind for a finished debuggee")
                        return
                    }
                    #expect(payload == "W00")
                } defer: {
                    try handler.close()
                }
            }
        }
    }
#endif
