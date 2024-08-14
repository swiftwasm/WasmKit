import WIT

struct HostExportInterface: ASTVisitor {
    var printer: SourcePrinter
    let context: SemanticsContext
    let sourceFile: SyntaxNode<SourceFileSyntax>
    let packageUnit: PackageUnit
    let interface: SyntaxNode<InterfaceSyntax>
    let signatureTranslation: SignatureTranslation
    let definitionMapping: DefinitionMapping

    var structName: String {
        get throws {
            return try ConvertCase.pascalCase(interface.name)
        }
    }

    mutating func generate() throws {
        try walk(interface)
    }

    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    func visit(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        try printer.write(line: "struct \(structName) {")
        printer.indent()
        printer.write(line: "let instance: WasmKit.Instance")
    }

    func visitPost(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        printer.unindent()
        printer.write(line: "}")
    }

    func resolveType(_ type: TypeReprSyntax) throws -> WITType {
        try context.resolveType(type, in: interface, sourceFile: sourceFile, contextPackage: packageUnit)
    }

    mutating func visit(_ namedFunction: SyntaxNode<NamedFunctionSyntax>) throws {
        let exportFunction = HostExportFunction(
            function: namedFunction.function,
            name: .interface(
                packageUnit.packageName,
                interfaceName: interface.name.text,
                id: namedFunction.name.text
            ),
            signatureTranslation: signatureTranslation,
            definitionMapping: definitionMapping
        )
        try exportFunction.print(typeResolver: resolveType(_:), printer: printer)
    }
}
