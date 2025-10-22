import NIOCore

/// Actions supported in the `vCont` host command.
package enum VContActions: String {
    case `continue` = "c"
    case continueWithSignal = "C"
    case step = "s"
    case stepWithSignal = "S"
    case stop = "t"
    case stepInRange = "r"
}

/// A response sent from a debugger target (a device
/// or a virtual machine being debugged) to a debugger host (GDB or LLDB).
/// See GDB remote protocol documentation for more details:
/// * https://sourceware.org/gdb/current/onlinedocs/gdb.html/General-Query-Packets.html
package struct GDBTargetResponse {
    /// Kind of the response sent from the debugger target to the debugger host.
    package enum Kind {
        /// Standard `OK` response.
        case ok

        /// A list of key-value pairs, with keys delimited from values by a colon `:`
        /// character, and pairs in the list delimited by the semicolon `;` character.
        case keyValuePairs(KeyValuePairs<String, String>)

        /// List of ``VContActions`` values delimited by the semicolon `;` character.
        case vContSupportedActions([VContActions])

        /// Raw string included as is in the response.
        case string(String)

        /// Binary buffer hex-encoded in the response.
        case hexEncodedBinary(ByteBufferView)

        /// Standard empty response (no content is sent).
        case empty
    }

    package let kind: Kind

    /// Whether `QStartNoAckMode` is activated and no ack `+` symbol should be sent
    /// before encoding this response.
    /// See https://sourceware.org/gdb/current/onlinedocs/gdb.html/Packet-Acknowledgment.html#Packet-Acknowledgment
    package let isNoAckModeActive: Bool

    /// Member-wise initializer for the debugger response.
    package init(kind: Kind, isNoAckModeActive: Bool) {
        self.kind = kind
        self.isNoAckModeActive = isNoAckModeActive
    }
}
