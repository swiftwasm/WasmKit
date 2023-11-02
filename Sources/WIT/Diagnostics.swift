struct ParseError: Error, CustomStringConvertible {
    let description: String
}

struct DiagnosticError: Error {
    let diagnostic: Diagnostic
}

public struct Diagnostic {

    public let message: String
    var textRange: TextRange?

    public func location(_ sourceText: String) -> (line: Int, column: Int)? {
        guard let textRange else { return nil }
        let position = textRange.lowerBound
        let linesBeforePos = sourceText[..<position].split(separator: "\n", omittingEmptySubsequences: false)
        let line = linesBeforePos.count
        let column = linesBeforePos.last?.count ?? 0
        return (line, column)
    }
}

extension Diagnostic {
    static func invalidRedeclaration(of identifier: String, textRange: TextRange) -> Diagnostic {
        return Diagnostic(
            message: "Invalid redeclaration of '\(identifier)'",
            textRange: textRange
        )
    }

    static func expectedIdentifier(textRange: TextRange) -> Diagnostic {
        return Diagnostic(message: "Expected identifier", textRange: textRange)
    }

    static func cannotFindType(of identifier: String, textRange: TextRange?) -> Diagnostic {
        return Diagnostic(message: "Cannot find type '\(identifier)' in scope", textRange: textRange)
    }

    static func cannotFindInterface(of identifier: String, textRange: TextRange?) -> Diagnostic {
        return Diagnostic(message: "Cannot find interface '\(identifier)' in scope", textRange: textRange)
    }

    static func expectedResourceType(_ type: WITType, textRange: TextRange?) -> Diagnostic {
        return Diagnostic(message: "Non-resource type \(type)", textRange: textRange)
    }

    static func noSuchPackage(_ packageName: PackageNameSyntax, textRange: TextRange?) -> Diagnostic {
        return Diagnostic(message: "No such package '\(packageName)'", textRange: textRange)
    }

    static func inconsistentPackageName(
        _ packageName: PackageNameSyntax,
        existingName: PackageNameSyntax,
        textRange: TextRange?
    ) -> Diagnostic {
        return Diagnostic(
            message: "package identifier `\(packageName)` does not match previous package name of `\(existingName)`",
            textRange: textRange
        )
    }

    static func noPackageHeader() -> Diagnostic {
        return Diagnostic(message: "no `package` header was found in any WIT file for this package", textRange: nil)
    }
}
