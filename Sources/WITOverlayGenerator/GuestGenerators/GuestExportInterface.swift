import WIT

struct GuestExportInterface: ASTVisitor {
    var printer: SourcePrinter
    let packageUnit: PackageUnit
    var packageName: PackageNameSyntax { packageUnit.packageName }
    let sourceFile: SyntaxNode<SourceFileSyntax>
    let interface: SyntaxNode<InterfaceSyntax>
    let signatureTranslation: SignatureTranslation
    var exportFunctions: [NamedFunctionSyntax] = []
    let context: SemanticsContext
    let definitionMapping: DefinitionMapping

    mutating func generate() throws {
        try walk(interface)
    }

    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    var protocolName: String {
        get throws {
            try "\(ConvertCase.pascalCase(packageName.namespace))\(ConvertCase.pascalCase(packageName.name))\(ConvertCase.pascalCase(interface.name))Exports"
        }
    }

    func visit(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        try printer.write(line: "public protocol \(protocolName) {")
        printer.indent()
    }

    func visitPost(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        printer.unindent()
        printer.write(line: "}")

        for namedFunction in exportFunctions {
            let function = namedFunction.function
            try GuestExportFunction(
                function: function,
                definitionMapping: definitionMapping,
                name: .interface(
                    packageName,
                    interfaceName: interface.name.text,
                    id: namedFunction.name.text
                ),
                implementation: "\(protocolName)Impl.\(try ConvertCase.camelCase(namedFunction.name))"
            ).print(
                typeResolver: {
                    try context.resolveType($0, in: interface, sourceFile: sourceFile, contextPackage: packageUnit)
                }, printer: printer)
        }
    }

    mutating func visit(_ namedFunction: SyntaxNode<NamedFunctionSyntax>) throws {
        exportFunctions.append(namedFunction.syntax)
        try printer.write(
            line: "static "
                + signatureTranslation.signature(
                    function: namedFunction.function,
                    name: namedFunction.name.text
                ).description
        )
    }
}
