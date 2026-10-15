/// A failure raised by cleanup that ran while unwinding from another failure. Both stay visible.
package struct CleanupFailure: Error, CustomStringConvertible {
    package let underlying: any Error
    package let cleanup: any Error

    package var description: String {
        "\(underlying) (cleanup also failed: \(cleanup))"
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
}
