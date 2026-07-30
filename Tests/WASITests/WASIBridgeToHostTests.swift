import Foundation
import Testing

@_spi(WASIPlatform) @testable import WASI

enum BridgeProbeError: Error, Equatable {
    case body
}

@Suite struct WASIBridgeToHostTests {
    @Test func failedPreopenThrowsInsteadOfTrippingTheCloseCheck() throws {
        // `HostFileSystem.preopenDirectory` reports a bad path as `WASIError` everywhere except Windows,
        // where `FileDescriptor.open` fails with a translated WASI errno first.
        #if os(Windows)
            #expect(throws: (any Error).self) {
                _ = try WASIBridgeToHost(
                    preopens: [WASIBridgeToHost.Preopen(guestPath: "/", hostPath: "/definitely-not-here")]
                )
            }
        #else
            #expect(throws: WASIError.self) {
                _ = try WASIBridgeToHost(
                    preopens: [WASIBridgeToHost.Preopen(guestPath: "/", hostPath: "/definitely-not-here")]
                )
            }
        #endif
    }

    #if os(macOS) || os(Linux)
        // Windows opens a preopen `.readWrite`, which fails for a directory, so the first preopen
        // cannot succeed there and the second would not be the failure under test.
        @Test func failedPreopenAfterASuccessfulOneReleasesTheFirst() throws {
            let directory = try TestSupport.TemporaryDirectory()
            let resolvedPath = try TestSupport.realPath(directory.path)

            let error = #expect(throws: (any Error).self) {
                _ = try WASIBridgeToHost(
                    preopens: [
                        WASIBridgeToHost.Preopen(guestPath: "/tmp", hostPath: directory.path),
                        WASIBridgeToHost.Preopen(guestPath: "/", hostPath: "/definitely-not-here"),
                    ]
                )
            }

            // A `CleanupFailure` here would mean the release itself failed.
            let thrown = try #require(error)
            #expect(thrown is WASIError)
            #expect(!(try TestSupport.openDescriptorPaths().contains(resolvedPath)))
        }
    #endif

    @Test func runAndCloseSurfacesTheBodyErrorUnwrapped() throws {
        let bridge = try WASIBridgeToHost()
        let error = #expect(throws: (any Error).self) {
            try bridge.runAndClose { _ in throw BridgeProbeError.body }
        }
        let thrown = try #require(error)
        #expect(thrown as? BridgeProbeError == .body)
    }
}
