public struct Diagnostic: CustomStringConvertible {
    public enum Severity {
        case warning
        case error
    }

    public let message: String
    public let severity: Severity

    public var description: String {
        "\(severity):\(message)"
    }

    static func warning(_ messaage: String) -> Diagnostic {
        return Diagnostic(message: messaage, severity: .warning)
    }
}

extension Diagnostic {
    static func skipField(context: String, field: String, missingType: String) -> Diagnostic {
        .warning("Skipping \(context)/\(field) field due to missing corresponding WIT type for \"\(missingType)\"")
    }
}

final class DiagnosticCollection {
    private(set) var diagnostics: [Diagnostic] = []

    func add(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
}
