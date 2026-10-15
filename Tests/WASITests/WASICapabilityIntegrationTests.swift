import Foundation
import Testing
import WasmKit
import WasmKitWASI

// The guests come from `Vendor/wasi-testsuite`, which the Android job does not
// check out: it runs the suite on an emulator without the repository tree.
// `IntegrationTests` skips itself on Android for the same reason.
#if !os(Android)

    /// End-to-end checks that selective linking actually runs real guests, and --
    /// just as importantly -- that leaving a capability out is observable. A
    /// subset that silently behaved like a full link would pass every functional
    /// test while defeating the entire point of the API.
    @Suite struct WASICapabilityIntegrationTests {
        /// Imports exactly environ_get, environ_sizes_get, fd_write and proc_exit,
        /// so it spans `.environment`, `.stdio` and `.process`.
        static let environGuest = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(
                "Vendor/wasi-testsuite/tests/assemblyscript/testsuite/environ_get-multiple-variables.wasm")

        private static let environment = ["a": "text", "b": "escap \" ing", "c": "new\nline"]

        private func run(
            _ path: URL,
            capabilities: [WASICapability],
            stubUnlinked: Bool = true
        ) throws -> UInt32 {
            let wasi = try WASIBridgeToHost(
                args: [path.path],
                environment: Self.environment,
                fileSystem: .host().withStdio()
            )
            return try wasi.runAndClose { wasi in
                let store = Store(engine: Engine())
                var imports = Imports()
                wasi.link(to: &imports, store: store, capabilities: capabilities, stubUnlinked: stubUnlinked)
                let module = try parseWasm(filePath: path.path)
                let instance = try module.instantiate(store: store, imports: imports)
                return try wasi.start(instance)
            }
        }

        @Test func aSubsetCoveringTheGuestRunsIt() throws {
            let exitCode = try run(Self.environGuest, capabilities: [.environment, .stdio, .process])
            #expect(exitCode == 0)
        }

        @Test func theSameGuestStillRunsUnderAFullLink() throws {
            let exitCode = try run(Self.environGuest, capabilities: WASICapability.all)
            #expect(exitCode == 0)
        }

        /// The load-bearing negative: dropping `.environment` must actually change
        /// behaviour. If this passes with exit code 0, capabilities are not
        /// restricting anything.
        @Test func omittingANeededCapabilityIsObservable() throws {
            // Guard against a vacuous pass: this must fail for want of
            // .environment, not because the fixture moved.
            #expect(FileManager.default.fileExists(atPath: Self.environGuest.path))

            let outcome = Result {
                try run(Self.environGuest, capabilities: [.stdio, .process])
            }
            switch outcome {
            case .success(let exitCode):
                // environ_get is stubbed to ENOSYS, so the guest cannot succeed.
                #expect(exitCode != 0, "the guest should not succeed without .environment")
            case .failure:
                break  // trapping is an equally valid observation
            }
        }

        /// Guests import a fixed list regardless of what they call, so stubbing is
        /// what makes a subset usable at all.
        @Test func stubbingSatisfiesImportsNoCapabilityProvides() throws {
            let store = Store(engine: Engine())
            let wasi = try WASIBridgeToHost(fileSystem: .host().withStdio())
            try wasi.runAndClose { wasi in
                var imports = Imports()
                wasi.link(to: &imports, store: store, capabilities: [.stdio], stubUnlinked: true)
                let module = try parseWasm(filePath: Self.environGuest.path)
                // environ_get/environ_sizes_get come from stubs, not .stdio.
                _ = try module.instantiate(store: store, imports: imports)
            }
        }

        @Test func withoutStubbingAnUnprovidedImportFailsToInstantiate() throws {
            let store = Store(engine: Engine())
            let wasi = try WASIBridgeToHost(fileSystem: .host().withStdio())
            try wasi.runAndClose { wasi in
                var imports = Imports()
                wasi.link(to: &imports, store: store, capabilities: [.stdio], stubUnlinked: false)
                let module = try parseWasm(filePath: Self.environGuest.path)
                #expect(throws: (any Error).self) {
                    _ = try module.instantiate(store: store, imports: imports)
                }
            }
        }
    }

#endif
