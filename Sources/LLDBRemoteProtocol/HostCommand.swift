/// See https://lldb.llvm.org/resources/lldbgdbremote.html for more details.
package struct HostCommand: Equatable {
    package enum Kind: Equatable {
        // Currently listed in the order that LLDB sends them in.
        case generalRegisters
        case startNoAckMode
        case firstThreadInfo
        case supportedFeatures
        case isThreadSuffixSupported
        case listThreadsInStopReply
        case hostInfo

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
