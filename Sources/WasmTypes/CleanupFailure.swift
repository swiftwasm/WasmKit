/// A failure raised by cleanup that ran while unwinding from another failure. Both stay visible.
package struct CleanupFailure: Error, CustomStringConvertible {
    package let underlying: any Error
    package let cleanup: any Error

    package var description: String {
        // Embedded Swift cannot interpolate `any Error` values.
        #if hasFeature(Embedded)
            return "cleanup failed while unwinding from another error"
        #else
            return "\(underlying) (cleanup also failed: \(cleanup))"
        #endif
    }

    package init(underlying: any Error, cleanup: any Error) {
        self.underlying = underlying
        self.cleanup = cleanup
    }

    package static func preserving(_ error: any Error, cleanup: () throws -> Void) -> any Error {
        do {
            try cleanup()
            return error
        } catch let cleanupError {
            return CleanupFailure(underlying: error, cleanup: cleanupError)
        }
    }

    #if !hasFeature(Embedded)
        package static func preserving(
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
    #endif
}
