/// An AST node that can be wrapped by ``SyntaxNode`` as a reference
public protocol SyntaxNodeProtocol {}

/// An AST node with reference semantics to provide identity of a node.
@dynamicMemberLookup
public struct SyntaxNode<Syntax: SyntaxNodeProtocol>: Equatable, Hashable {
    class Ref {
        fileprivate let syntax: Syntax
        init(syntax: Syntax) {
            self.syntax = syntax
        }
    }

    private let ref: Ref
    public var syntax: Syntax { ref.syntax }

    internal init(syntax: Syntax) {
        self.ref = Ref(syntax: syntax)
    }

    public subscript<R>(dynamicMember keyPath: KeyPath<Syntax, R>) -> R {
        self.ref.syntax[keyPath: keyPath]
    }

    public static func == (lhs: SyntaxNode<Syntax>, rhs: SyntaxNode<Syntax>) -> Bool {
        return lhs.ref === rhs.ref
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(ref))
    }
}
