import WIT

struct HostWorldGenerator: ASTVisitor {
    let printer: SourcePrinter
    let context: SemanticsContext
    let world: SyntaxNode<WorldSyntax>
    let sourceFile: SyntaxNode<SourceFileSyntax>
    let packageUnit: PackageUnit
    let signatureTranslation: SignatureTranslation
    let definitionMapping: DefinitionMapping

    mutating func generate() throws {
        try walk(world)
    }

    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    func visit(_ world: SyntaxNode<WorldSyntax>) throws {
        try printer.write(
            line: """

                struct \(ConvertCase.pascalCase(world.name)) {
                    let moduleInstance: ModuleInstance

                    static func link(_ hostModules: inout [String: HostModule]) {
                    }
                """)
        // Enter world struct body
        printer.indent()

        for item in world.items {
            switch item {
            case .export(let export):
                switch export.kind {
                case .function(let name, let function):
                    let exportFunction = HostExportFunction(
                        function: function, name: .world(name.text),
                        signatureTranslation: signatureTranslation,
                        definitionMapping: definitionMapping
                    )
                    try exportFunction.print(typeResolver: resolveType(_:), printer: printer)
                case .path(.id(let interfaceIdent)):
                    let (interface, sourceFile) = try context.lookupInterface(
                        name: interfaceIdent.text, contextPackage: packageUnit
                    )
                    var generator = HostExportInterface(
                        printer: printer,
                        context: context,
                        sourceFile: sourceFile,
                        packageUnit: packageUnit,
                        interface: interface,
                        signatureTranslation: SignatureTranslation(interfaceContext: (interface, packageUnit)),
                        definitionMapping: definitionMapping
                    )
                    try generator.generate()
                default: break
                }
            case .type(let typeDef):
                try TypeDefinition(accessLevel: .internal)
                    .print(printer: printer, signatureTranslation: signatureTranslation, typeDef: typeDef)
            case .use(let use):
                try TypeDefinition(accessLevel: .public)
                    .printUse(printer: printer, use: use, contextPackageName: packageUnit.packageName)
            default: break
            }
        }

        // Leave world struct body
        printer.unindent()
        printer.write(line: "}")
    }

    func resolveType(_ type: TypeReprSyntax) throws -> WITType {
        try context.resolveType(type, in: world, sourceFile: sourceFile, contextPackage: packageUnit)
    }
}
