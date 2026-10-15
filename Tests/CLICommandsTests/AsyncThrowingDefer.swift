import WASI

/// Async counterpart of ``withThrowing(do:defer:)`` for tests.
///
/// `WASI` itself has no async callers, so this deliberately lives in the test
/// target rather than shipping as package API. It mirrors the synchronous
/// helper's semantics: `deferred` runs exactly once, and when both closures
/// throw the failure surfaces as a ``CleanupFailure``.
@discardableResult
func withAsyncThrowing<T: Sendable>(
    do work: @Sendable () async throws -> T,
    defer deferred: @Sendable () async throws -> Void
) async throws -> T {
    let result: T
    do {
        result = try await work()
    } catch {
        throw await preservingError(error, cleanup: deferred)
    }
    try await deferred()
    return result
}

private func preservingError(
    _ error: any Error,
    cleanup: () async throws -> Void
) async -> any Error {
    do {
        try await cleanup()
        return error
    } catch let cleanupError {
        return CleanupFailure(underlying: error, cleanup: cleanupError)
    }
}
