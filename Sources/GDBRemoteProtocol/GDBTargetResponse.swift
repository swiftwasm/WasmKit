/// Actions supported in the `vCont` host command.
package enum VContActions: String {
    case `continue` = "c"
    case continueWithSignal = "C"
    case step = "s"
    case stepWithSignal = "S"
    case stop = "t"
    case stepInRange = "r"
}

package struct GDBTargetResponse {
    package enum Kind {
        case ok
        case keyValuePairs(KeyValuePairs<String, String>)
        case vContSupportedActions([VContActions])
        case raw(String)
        case empty
    }

    package let kind: Kind
    package let isNoAckModeActivated: Bool

    package init(kind: Kind, isNoAckModeActivated: Bool) {
        self.kind = kind
        self.isNoAckModeActivated = isNoAckModeActivated
    }
}
