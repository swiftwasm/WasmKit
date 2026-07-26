import SwiftParser
import SwiftSyntax

/// Performs no type resolution.
final class WITDeclCollector: SyntaxVisitor {
    private var scopeStack: [String] = []
    private(set) var inventory = DeclInventory()
    let diagnostics: DiagnosticCollection

    init(diagnostics: DiagnosticCollection) {
        self.diagnostics = diagnostics
        super.init(viewMode: .sourceAccurate)
    }

    static func collect(source: String) -> (inventory: DeclInventory, diagnostics: DiagnosticCollection) {
        let diagnostics = DiagnosticCollection()
        return (collect(parsed: [Parser.parse(source: source)], into: diagnostics), diagnostics)
    }

    static func collect(parsed sources: [SourceFileSyntax], into diagnostics: DiagnosticCollection) -> DeclInventory {
        let collector = WITDeclCollector(diagnostics: diagnostics)
        for source in sources { collector.walk(source) }
        return collector.inventory
    }

    static func collect(sources: [String], into diagnostics: DiagnosticCollection) -> DeclInventory {
        collect(parsed: sources.map { Parser.parse(source: $0) }, into: diagnostics)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributes.hasWITMarker {
            inventory.types.append(
                TypeEntry(
                    kind: .structType, scopePath: scopeStack, name: node.name.text,
                    fields: collectFields(node.memberBlock, owner: node.name.text), cases: [],
                    swiftQualifiedName: (scopeStack + [node.name.text]).joined(separator: ".")))
        }
        scopeStack.append(node.name.text)  // push unmarked scopes too, so nested @WIT types qualify
        return .visitChildren
    }
    override func visitPost(_ node: StructDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributes.hasWITMarker {
            let cases = collectCases(node.memberBlock)
            if !cases.isEmpty {  // caseless enum is a namespace, not a WIT type
                inventory.types.append(
                    TypeEntry(
                        kind: .enumType, scopePath: scopeStack, name: node.name.text,
                        fields: [], cases: cases,
                        swiftQualifiedName: (scopeStack + [node.name.text]).joined(separator: ".")))
            }
        }
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: EnumDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributes.hasWITMarker {
            if scopeStack.isEmpty {
                inventory.functions.append(
                    FunctionEntry(
                        name: node.name.text,
                        parameters: node.signature.parameterClause.parameters.map { param in
                            // With a `secondName`, `firstName` is the external label; otherwise it is
                            // both label and internal name. `_` in either position means anonymous.
                            let first = param.firstName.text
                            let second = param.secondName?.text
                            return FunctionEntry.Parameter(
                                externalLabel: first == "_" ? nil : first,
                                internalName: (second == "_" ? nil : second) ?? (first == "_" ? nil : first),
                                type: param.type)
                        },
                        returnClause: node.signature.returnClause))
            } else {
                diagnostics.add(.unsupportedDecl(kind: "method", name: node.name.text))
            }
        }
        return .skipChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        diagnoseIfMarked(node.attributes, kind: "class", name: node.name.text)
        scopeStack.append(node.name.text)
        return .visitChildren
    }
    override func visitPost(_ node: ClassDeclSyntax) { scopeStack.removeLast() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        diagnoseIfMarked(node.attributes, kind: "actor", name: node.name.text)
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

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        diagnoseIfMarked(node.attributes, kind: "protocol", name: node.name.text)
        return .skipChildren
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        diagnoseIfMarked(node.attributes, kind: "typealias", name: node.name.text)
        return .skipChildren
    }

    private func diagnoseIfMarked(_ attributes: AttributeListSyntax, kind: String, name: String) {
        if attributes.hasWITMarker {
            diagnostics.add(.unsupportedDecl(kind: kind, name: name))
        }
    }

    func collectFields(_ members: MemberBlockSyntax, owner: String) -> [FieldEntry] {
        var fields: [FieldEntry] = []
        for member in members.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                varDecl.modifiers.isPublic
            else { continue }
            if varDecl.modifiers.hasStaticModifier {
                // A static member is never a record field.
                if varDecl.attributes.hasWITMarker {
                    for name in bindingNames(varDecl) {
                        diagnostics.add(.skipStaticField(context: owner, field: name))
                    }
                }
                continue
            }
            // In `var a, b: Int` the annotation-less binding `a` shares `b`'s type. Walk in reverse so
            // the last-seen type carries back to `a`.
            var carriedType: TypeSyntax?
            var collected: [FieldEntry] = []
            for binding in varDecl.bindings.reversed() {
                if let annotated = binding.typeAnnotation?.type { carriedType = annotated }
                guard binding.accessorBlock == nil,
                    let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                    let type = carriedType
                else { continue }
                let name = pattern.identifier.identifier?.name ?? pattern.identifier.text  // unescape `static`
                collected.append(FieldEntry(name: name, type: type))
            }
            fields.append(contentsOf: collected.reversed())
        }
        return fields
    }

    private func bindingNames(_ varDecl: VariableDeclSyntax) -> [String] {
        varDecl.bindings.compactMap {
            $0.pattern.as(IdentifierPatternSyntax.self).map {
                $0.identifier.identifier?.name ?? $0.identifier.text
            }
        }
    }

    func collectCases(_ members: MemberBlockSyntax) -> [CaseEntry] {
        var cases: [CaseEntry] = []
        for member in members.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                cases.append(
                    CaseEntry(
                        name: element.name.text,
                        payload: element.parameterClause?.parameters.map(\.type) ?? []))
            }
        }
        return cases
    }
}

extension WITDeclCollector {
    /// `owner` is the type's module-qualified name, used only in field-skip diagnostics.
    static func members(of node: WITSymbolTable.NominalNode, owner: String, into diagnostics: DiagnosticCollection)
        -> (fields: [FieldEntry], cases: [CaseEntry])
    {
        let collector = WITDeclCollector(diagnostics: diagnostics)
        switch node {
        case .structDecl(let structDecl):
            return (collector.collectFields(structDecl.memberBlock, owner: owner), [])
        case .enumDecl(let enumDecl):
            return ([], collector.collectCases(enumDecl.memberBlock))
        }
    }
}
