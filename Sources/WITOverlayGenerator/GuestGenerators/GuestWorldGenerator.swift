import WIT

struct WorldGenerator: ASTVisitor {
    var printer: SourcePrinter
    let packageUnit: PackageUnit
    let sourceFile: SyntaxNode<SourceFileSyntax>
    let world: SyntaxNode<WorldSyntax>
    let signatureTranslation: SignatureTranslation
    let context: SemanticsContext
    let definitionMapping: DefinitionMapping

    var exportFunctions: [(Identifier, FunctionSyntax)] = []

    mutating func generate() throws {
        try walk(world)
    }

    func visit(_ world: SyntaxNode<WorldSyntax>) throws {}
    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    var protocolName: String {
        get throws {
            try "\(ConvertCase.pascalCase(world.name))Exports"
        }
    }

    mutating func visitPost(_ world: SyntaxNode<WorldSyntax>) throws {
        try printer.write(line: "public protocol \(protocolName) {")
        try printer.indent {
            for (name, function) in exportFunctions {
                try printer.write(
                    line: "static "
                        + signatureTranslation.signature(
                            function: function,
                            name: name.text
                        ).description
                )
            }
        }
        printer.write(line: "}")

        for (name, function) in exportFunctions {
            try GuestExportFunction(
                function: function,
                definitionMapping: definitionMapping,
                name: .world(name.text),
                implementation: "\(protocolName)Impl.\(try ConvertCase.camelCase(name))"
            ).print(
                typeResolver: {
                    try context.resolveType($0, in: world, sourceFile: sourceFile, contextPackage: packageUnit)
                }, printer: printer)
        }
    }

    mutating func visit(_ worldItem: WorldItemSyntax) throws {
        switch worldItem {
        case .use(let use):
            try TypeDefinition(accessLevel: .public)
                .printUse(printer: printer, use: use, contextPackageName: packageUnit.packageName)
        default: break
        }
    }

    mutating func visit(_ typeDef: SyntaxNode<TypeDefSyntax>) throws {
        try TypeDefinition(accessLevel: .public)
            .print(printer: printer, signatureTranslation: signatureTranslation, typeDef: typeDef)
    }

    mutating func visit(_ export: ExportSyntax) throws {
        switch export.kind {
        case .path(.id(let interfaceIdent)):
            let (interface, sourceFile) = try context.lookupInterface(
                name: interfaceIdent.text, contextPackage: packageUnit
            )
            var generator = GuestExportInterface(
                printer: printer,
                packageUnit: packageUnit,
                sourceFile: sourceFile,
                interface: interface,
                signatureTranslation: SignatureTranslation(interfaceContext: (interface, packageUnit)),
                context: context,
                definitionMapping: definitionMapping
            )
            try generator.generate()
        case .function(let name, let function):
            self.exportFunctions.append((name, function))
        default: fatalError()
        }
    }
}
