import SwiftSyntax

extension AttributeListSyntax {
    /// Matches the spelled name, not the resolved macro, so it works when the marker is out of scope.
    var hasWITMarker: Bool {
        contains {
            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "WIT"
        }
    }
}

extension DeclModifierListSyntax {
    var isPublic: Bool {
        contains { $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) }
    }

    var hasStaticModifier: Bool {
        contains { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }
    }
}

extension ExtensionDeclSyntax {
    var extendedTypePath: [String]? {
        ExtensionDeclSyntax.namePath(of: extendedType)
    }

    /// Skips children of an unscopable extension so its body is not walked under the wrong scope.
    func pushExtendedScope(onto scopeStack: inout [String]) -> SyntaxVisitorContinueKind {
        guard let path = extendedTypePath else { return .skipChildren }
        scopeStack.append(contentsOf: path)
        return .visitChildren
    }

    /// Recomputes the path from the node so push and pop balance without a parallel stack.
    func popExtendedScope(from scopeStack: inout [String]) {
        if let path = extendedTypePath { scopeStack.removeLast(path.count) }
    }

    private static func namePath(of type: TypeSyntax) -> [String]? {
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return [identifier.name.text]
        }
        if let member = type.as(MemberTypeSyntax.self) {
            guard let base = namePath(of: member.baseType) else { return nil }
            return base + [member.name.text]
        }
        return nil
    }
}
