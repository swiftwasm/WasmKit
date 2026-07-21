import SwiftSyntax

struct WITSymbolTable {
    typealias QualifiedName = [String]

    /// Holds the whole decl node to collect members on demand when inlining.
    enum NominalNode {
        case structDecl(StructDeclSyntax)
        case enumDecl(EnumDeclSyntax)
    }

    enum Entry {
        case nominal(module: String, node: NominalNode)
        case typeAlias(rhs: TypeSyntax)
    }

    private(set) var entries: [QualifiedName: Entry] = [:]

    mutating func insert(_ qualifiedName: QualifiedName, _ entry: Entry) {
        entries[qualifiedName] = entry
    }

    func entry(_ qualifiedName: QualifiedName) -> Entry? {
        entries[qualifiedName]
    }

    func contains(_ qualifiedName: QualifiedName) -> Bool {
        entries[qualifiedName] != nil
    }

    /// Innermost-scope-first. Returned `qualifiedName` is the matched table key, not `reference`.
    func resolve(_ reference: QualifiedName, inScope scope: QualifiedName)
        -> (qualifiedName: QualifiedName, entry: Entry)?
    {
        guard !reference.isEmpty else { return nil }
        for prefixLength in stride(from: scope.count, through: 0, by: -1) {
            let candidate = Array(scope.prefix(prefixLength)) + reference
            if let entry = entries[candidate] { return (candidate, entry) }
        }
        return nil
    }
}

extension WITSymbolTable.NominalNode {
    var isPublic: Bool {
        switch self {
        case .structDecl(let structDecl): return structDecl.modifiers.isPublic
        case .enumDecl(let enumDecl): return enumDecl.modifiers.isPublic
        }
    }
}
