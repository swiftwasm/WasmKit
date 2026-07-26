#if os(macOS) || os(Linux)

    import Testing
    import WasmKit
    import WasmKitWASI

    import CLICommands

    @Suite struct RunWASIConfigurationTests {
        private func runFixture(arguments: [String]) throws -> UInt32 {
            let run = try Run.parse(arguments)
            let bridge = try WASIBridgeToHost(configuration: run.deriveWASIConfiguration())
            return try bridge.runAndClose { wasi in
                let store = Store(engine: Engine())
                var imports = Imports()
                wasi.link(to: &imports, store: store)
                let instance = try PreopenFixture.fixtureModule().instantiate(store: store, imports: imports)
                return try wasi.start(instance)
            }
        }

        @Test func guestSeesMappedPreopenAndOverriddenArgv0() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let argv0 = "/cross-build/wasm32/python.wasm"
                let exitCode = try runFixture(arguments: [
                    "--dir", "\(directory.path)::/",
                    "--argv0", argv0,
                    PreopenFixture.fixturePath,
                    argv0, "/", "probe.txt", PreopenFixture.fixtureContents,
                ])
                #expect(exitCode == 0)
            }
        }

        @Test func guestSeesIdentityPreopenAndModulePathArgv0() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let exitCode = try runFixture(arguments: [
                    "--dir", directory.path,
                    PreopenFixture.fixturePath,
                    PreopenFixture.fixturePath, directory.path, "probe.txt", PreopenFixture.fixtureContents,
                ])
                #expect(exitCode == 0)
            }
        }
    }
#endif
