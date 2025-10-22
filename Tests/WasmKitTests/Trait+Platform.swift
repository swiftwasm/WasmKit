import Testing

enum TargetPlatform {
    case android

    func isCurrentPlatform() -> Bool {
        switch self {
        case .android:
            #if os(Android)
                return true
            #else
                return false
            #endif
        }
    }
}

extension Trait where Self == ConditionTrait {
    static func disabled(
        _ comment: Comment? = nil,
        sourceLocation: SourceLocation = #_sourceLocation,
        platforms: [TargetPlatform]
    ) -> Self {
        return .disabled(comment, sourceLocation: sourceLocation) {
            platforms.contains { $0.isCurrentPlatform() }
        }
    }
}

