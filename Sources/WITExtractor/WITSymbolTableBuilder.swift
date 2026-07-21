import SwiftParser
import SwiftSyntax

struct ModuleSource {
    let module: String
    let tree: SourceFileSyntax

    init(module: String, tree: SourceFileSyntax) {
        self.module = module
        self.tree = tree
    }

    init(module: String, source: String) {
        self.init(module: module, tree: Parser.parse(source: source))
    }
}

/// Indexes every nominal and `typealias` by qualified name; resolves nothing. Distinct from
/// `WITDeclCollector`, which records only the `@WIT`-selected types.
final class WITSymbolTableBuilder: SyntaxVisitor {
    private var scopeStack: [String] = []
    private let module: String
    private(set) var table = WITSymbolTable()

    init(module: String) {
        self.module = module
        super.init(viewMode: .sourceAccurate)
    }

    /// On a collision at one qualified name, a later insert wins.
    static func build(tagged sources: [ModuleSource]) -> WITSymbolTable {
        var merged = WITSymbolTable()
        for source in sources {
            let builder = WITSymbolTableBuilder(module: source.module)
            builder.walk(source.tree)
            for (name, entry) in builder.table.entries { merged.insert(name, entry) }
        }
        return merged
    }

    /// Tags all sources with the empty (anonymous) module.
    static func build(sources: [String]) -> WITSymbolTable {
        build(tagged: sources.map { ModuleSource(module: "", source: $0) })
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        table.insert(scopeStack + [node.name.text], .nominal(module: module, node: .structDecl(node)))
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: StructDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        table.insert(scopeStack + [node.name.text], .nominal(module: module, node: .enumDecl(node)))
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: EnumDeclSyntax) { scopeStack.removeLast() }

    // Classes/actors are not WIT types, but a nominal can nest inside one, so push scope without recording.
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: ClassDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: ActorDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        node.pushExtendedScope(onto: &scopeStack)
    }
    override func visitPost(_ node: ExtensionDeclSyntax) {
        node.popExtendedScope(from: &scopeStack)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        table.insert(scopeStack + [node.name.text], .typeAlias(rhs: node.initializer.value))
        return .skipChildren
    }
}
