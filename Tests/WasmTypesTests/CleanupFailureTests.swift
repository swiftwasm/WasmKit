import WasmTypes
import Testing

@Suite struct CleanupFailureTests {
    @Test func successfulCleanupPreservesTheOriginalError() throws {
        let result = CleanupFailure.preserving(ProbeError.body) {}
        #expect(result as? ProbeError == .body)
    }

    @Test func failedCleanupSurfacesBothErrors() throws {
        let result = CleanupFailure.preserving(ProbeError.body) { throw ProbeError.cleanup }
        let combined = try #require(result as? CleanupFailure)
        #expect(combined.underlying as? ProbeError == .body)
        #expect(combined.cleanup as? ProbeError == .cleanup)
        #expect(combined.description.contains("body"))
        #expect(combined.description.contains("cleanup"))
    }

    @Test func successfulAsyncCleanupPreservesTheOriginalError() async throws {
        let cleanup: () async throws -> Void = {}
        let result = await CleanupFailure.preserving(ProbeError.body, cleanup: cleanup)
        #expect(result as? ProbeError == .body)
    }

    @Test func failedAsyncCleanupSurfacesBothErrors() async throws {
        let cleanup: () async throws -> Void = { throw ProbeError.cleanup }
        let result = await CleanupFailure.preserving(ProbeError.body, cleanup: cleanup)
        let combined = try #require(result as? CleanupFailure)
        #expect(combined.underlying as? ProbeError == .body)
        #expect(combined.cleanup as? ProbeError == .cleanup)
    }
}
