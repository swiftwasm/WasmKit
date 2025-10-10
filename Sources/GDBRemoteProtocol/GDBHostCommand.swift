/// See GDB and LLDB remote protocol documentation for more details:
/// * https://sourceware.org/gdb/current/onlinedocs/gdb.html/General-Query-Packets.html
/// * https://lldb.llvm.org/resources/lldbgdbremote.html
package struct GDBHostCommand: Equatable {
    package enum Kind: String, Equatable {
        // Currently listed in the order that LLDB sends them in.
        case startNoAckMode
        case supportedFeatures
        case isThreadSuffixSupported
        case listThreadsInStopReply
        case hostInfo
        case vContSupportedActions
        case isVAttachOrWaitSupported
        case enableErrorStrings
        case processInfo
        case currentThreadID
        case firstThreadInfo
        case subsequentThreadInfo
        case targetStatus

        case generalRegisters

        package init?(rawValue: String) {
            switch rawValue {
            case "g":
                self = .generalRegisters
            case "QStartNoAckMode":
                self = .startNoAckMode
            case "qSupported":
                self = .supportedFeatures
            case "QThreadSuffixSupported":
                self = .isThreadSuffixSupported
            case "QListThreadsInStopReply":
                self = .listThreadsInStopReply
            case "qHostInfo":
                self = .hostInfo
            case "vCont?":
                self = .vContSupportedActions
            case "qVAttachOrWaitSupported":
                self = .isVAttachOrWaitSupported
            case "QEnableErrorStrings":
                self = .enableErrorStrings
            case "qProcessInfo":
                self = .processInfo
            case "qC":
                self = .currentThreadID
            case "qfThreadInfo":
                self = .firstThreadInfo
            case "qsThreadInfo":
                self = .subsequentThreadInfo
            case "?":
                self = .targetStatus

            default:
                return nil
            }
        }
    }

    package let kind: Kind

    package let arguments: String

    package init(kind: Kind, arguments: String) {
        self.kind = kind
        self.arguments = arguments
    }
}
