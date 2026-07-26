package struct Diagnostic: CustomStringConvertible {
    package enum Severity {
        case warning
        case error
    }

    package let message: String
    package let severity: Severity

    package var description: String {
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

    static func skipStaticField(context: String, field: String) -> Diagnostic {
        .warning("Skipping static field \(context)/\(field): static members are not WIT record fields")
    }

    static func unsupportedDecl(kind: String, name: String) -> Diagnostic {
        .warning("Skipping \(kind) '\(name)': only struct, enum, and top-level function declarations export to WIT")
    }

    static func nameCollision(dropped: String, witName: String, keeping: String) -> Diagnostic {
        .warning("Skipping \(dropped): WIT name \"\(witName)\" is already used by \(keeping)")
    }

    static func skipInlinedType(name: String, reason: String) -> Diagnostic {
        .warning("Skipping inlined dependency type \(name): \(reason)")
    }
}

final class DiagnosticCollection {
    private(set) var diagnostics: [Diagnostic] = []

    func add(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
}
