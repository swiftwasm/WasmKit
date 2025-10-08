package struct TargetResponse {
    package enum Kind {
        case ok
        case raw(String)
        case empty
    }

    package let kind: Kind
    package let isNoAckModeActive: Bool

    package init(kind: Kind, isNoAckModeActive: Bool) {
        self.kind = kind
        self.isNoAckModeActive = isNoAckModeActive
    }
}
