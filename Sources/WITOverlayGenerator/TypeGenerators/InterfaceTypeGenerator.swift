import WIT

/// Generate Swift type definitions from WIT types defined under `interface`
struct InterfaceTypeGenerator: ASTVisitor {
    var printer: SourcePrinter
    let packageUnit: PackageUnit
    let interface: SyntaxNode<InterfaceSyntax>
    let signatureTranslation: SignatureTranslation

    mutating func generate() throws {
        try walk(interface)
    }

    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    func visit(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        let packageName = packageUnit.packageName
        try printer.write(line: "public enum \(typeNamespace(packageName: packageName, interface: interface.name)) {")
        printer.indent()
    }
    func visitPost(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        printer.unindent()
        printer.write(line: "}")
    }

    mutating func visit(_ typeDef: SyntaxNode<TypeDefSyntax>) throws {
        try TypeDefinition(accessLevel: .public)
            .print(printer: printer, signatureTranslation: signatureTranslation, typeDef: typeDef)
    }
}
