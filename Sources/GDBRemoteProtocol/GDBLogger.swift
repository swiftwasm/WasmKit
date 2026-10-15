/// Verbosity level for ``GDBLogger`` messages.
package enum GDBLogLevel: Int, Comparable, Sendable {
    case trace = 0
    case debug = 1
    case info = 2
    case error = 3

    package static func < (lhs: GDBLogLevel, rhs: GDBLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A minimal logging seam for the GDB remote protocol stack.
///
/// The debugger stack is meant to run on embedded systems, so it avoids
/// depending on a full logging framework; hosts route messages wherever they
/// want (a terminal, a UART, nowhere).
package struct GDBLogger: Sendable {
    /// The minimum level a message must have to be passed to `sink`.
    package let logLevel: GDBLogLevel
    private let sink: @Sendable (GDBLogLevel, String) -> Void

    package init(logLevel: GDBLogLevel, sink: @escaping @Sendable (GDBLogLevel, String) -> Void) {
        self.logLevel = logLevel
        self.sink = sink
    }

    /// A logger that discards all messages.
    package static var disabled: GDBLogger {
        GDBLogger(logLevel: .error) { _, _ in }
    }

    package func log(_ level: GDBLogLevel, _ message: @autoclosure () -> String) {
        guard level >= logLevel else { return }
        sink(level, message())
    }

    package func trace(_ message: @autoclosure () -> String) { log(.trace, message()) }
    package func debug(_ message: @autoclosure () -> String) { log(.debug, message()) }
    package func info(_ message: @autoclosure () -> String) { log(.info, message()) }
    package func error(_ message: @autoclosure () -> String) { log(.error, message()) }
}
