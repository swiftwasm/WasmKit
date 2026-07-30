import WasmTypes
import Testing

@Suite struct ThrowingDeferTests {
    private actor Counter {
        private(set) var value = 0
        func increment() { value += 1 }
    }

    @Test func bodyErrorSurvivesAFailingCleanup() throws {
        let error = #expect(throws: (any Error).self) {
            try withThrowing {
                throw ProbeError.body
            } defer: {
                throw ProbeError.cleanup
            }
        }
        let thrown = try #require(error)
        let combined = try #require(thrown as? CleanupFailure)
        #expect(combined.underlying as? ProbeError == .body)
        #expect(combined.cleanup as? ProbeError == .cleanup)
    }

    @Test func cleanupRunsOnceWhenTheBodySucceedsAndCleanupFails() throws {
        var attempts = 0
        let error = #expect(throws: ProbeError.self) {
            try withThrowing {
                ()
            } defer: {
                attempts += 1
                throw ProbeError.cleanup
            }
        }
        #expect(attempts == 1)
        #expect(error == .cleanup)
    }

    @Test func cleanupRunsOnceWhenBothFail() throws {
        var attempts = 0
        _ = #expect(throws: CleanupFailure.self) {
            try withThrowing {
                throw ProbeError.body
            } defer: {
                attempts += 1
                throw ProbeError.cleanup
            }
        }
        #expect(attempts == 1)
    }

    @Test func resultAndCleanupBothRunOnSuccess() throws {
        var attempts = 0
        let value = try withThrowing {
            7
        } defer: {
            attempts += 1
        }
        #expect(value == 7)
        #expect(attempts == 1)
    }

    @Test func asyncBodyErrorSurvivesAFailingCleanup() async throws {
        let error = await #expect(throws: (any Error).self) {
            try await withAsyncThrowing {
                throw ProbeError.body
            } defer: {
                throw ProbeError.cleanup
            }
        }
        let thrown = try #require(error)
        let combined = try #require(thrown as? CleanupFailure)
        #expect(combined.underlying as? ProbeError == .body)
    }

    @Test func asyncCleanupRunsOnceWhenTheBodySucceedsAndCleanupFails() async throws {
        let attempts = Counter()
        let error = await #expect(throws: ProbeError.self) {
            try await withAsyncThrowing {
                ()
            } defer: {
                await attempts.increment()
                throw ProbeError.cleanup
            }
        }
        #expect(await attempts.value == 1)
        #expect(error == .cleanup)
    }
}
