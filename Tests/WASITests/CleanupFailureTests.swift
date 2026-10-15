import Testing
import WASI

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
}
