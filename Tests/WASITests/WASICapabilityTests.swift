import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

@Suite struct WASICapabilityTests {
    private typealias Capability = WASICapability<TestSupport.TestGuestMemory>

    /// The bridge asserts it was closed before deallocation.
    private func withBridge<T>(_ body: (WASIBridgeToHost) throws -> T) throws -> T {
        let bridge = try WASIBridgeToHost(fileSystem: .memory(MemoryFileSystem()))
        return try withThrowing {
            try body(bridge)
        } defer: {
            try bridge.close()
        }
    }

    private func functions(
        _ capabilities: [Capability],
        stubUnlinked: Bool
    ) throws -> [String: WASIHostFunction<TestSupport.TestGuestMemory>] {
        try withBridge { $0.hostFunctions(capabilities: capabilities, stubUnlinked: stubUnlinked) }
    }

    /// Names every preview1 function, so a new one cannot be added to a
    /// capability without also being given a signature for stubbing.
    @Test func everyCapabilityFunctionHasASignature() throws {
        let all = try functions(Capability.all, stubUnlinked: false)
        let known = Set(preview1Signatures.map(\.name))
        #expect(Set(all.keys).subtracting(known).isEmpty)
    }

    @Test func stubbingFillsInEveryDeclaredImport() throws {
        let subset = try functions([.stdio], stubUnlinked: true)
        #expect(Set(subset.keys) == Set(preview1Signatures.map(\.name)))
    }

    @Test func aSubsetLinksOnlyWhatItAsksFor() throws {
        let subset = try functions([.clocks, .random], stubUnlinked: false)
        #expect(Set(subset.keys) == ["clock_res_get", "clock_time_get", "random_get"])
    }

    @Test func stubsReportENOSYSRatherThanTrapping() throws {
        let subset = try functions([.random], stubUnlinked: true)
        let stub = try #require(subset["sock_recv"])
        let result = try stub.implementation(TestSupport.TestGuestMemory(), [])
        #expect(result == [.i32(UInt32(WASIAbi.Errno.ENOSYS.rawValue))])
    }

    /// `all` must stay in sync with the capabilities that exist.
    @Test func allCoversEveryImplementedFunction() throws {
        let all = try functions(Capability.all, stubUnlinked: false)
        // The four unimplemented preview1 entries only ever exist as stubs.
        let stubOnly: Set<String> = ["proc_raise", "sock_accept", "sock_recv", "sock_send"]
        #expect(Set(preview1Signatures.map(\.name)).subtracting(all.keys) == stubOnly)
    }
}
