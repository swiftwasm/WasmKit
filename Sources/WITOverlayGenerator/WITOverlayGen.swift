import WIT

struct GenerationError: Error, CustomStringConvertible {
    var description: String
}

func typeNamespace(packageName: PackageNameSyntax, interface: Identifier) throws -> String {
    return try "\(ConvertCase.pascalCase(packageName.namespace))\(ConvertCase.pascalCase(packageName.name))\(ConvertCase.pascalCase(interface))"
}

public func generateGuest(context: SemanticsContext) throws -> String {
    let printer = SourcePrinter(header: guestPrelude)

    let definitionMapping = GeneratedDefinitionMapping()

    try TypeGenerator(context: context).generate(printer: printer)

    for sourceFile in context.rootPackage.sourceFiles {
        for case .world(let world) in sourceFile.items {
            var generator = WorldGenerator(
                printer: printer,
                packageUnit: context.rootPackage,
                sourceFile: sourceFile,
                world: world,
                signatureTranslation: SignatureTranslation(interfaceContext: nil),
                context: context,
                definitionMapping: definitionMapping
            )
            try generator.generate()
        }
    }
    printer.write(line: "#endif // #if arch(wasm32)")
    return printer.contents
}

public func generateHost(context: SemanticsContext) throws -> String {
    let printer = SourcePrinter(
        header: """
            import WasmKit

            """)

    let definitionMapping = GeneratedDefinitionMapping()

    try TypeGenerator(context: context).generate(printer: printer)

    for sourceFile in context.rootPackage.sourceFiles {
        for case .world(let world) in sourceFile.items {
            var generator = HostWorldGenerator(
                printer: printer,
                context: context,
                world: world,
                sourceFile: sourceFile,
                packageUnit: context.rootPackage,
                signatureTranslation: SignatureTranslation(
                    interfaceContext: nil
                ),
                definitionMapping: definitionMapping
            )
            try generator.generate()
        }
    }
    return printer.contents
}

public func generateGuestExportInterface(
    context: SemanticsContext,
    sourceFile: SyntaxNode<SourceFileSyntax>,
    interface: SyntaxNode<InterfaceSyntax>,
    sourceSummaryProvider: some SourceSummaryProvider
) throws -> String {
    let printer = SourcePrinter(header: guestPrelude)
    let mapping = SourceDefinitionMapping(sourceSummaryProvider: sourceSummaryProvider)
    let typeResolver = {
        try context.resolveType($0, in: interface, sourceFile: sourceFile, contextPackage: context.rootPackage)
    }

    for case .typeDef(let typeDef) in interface.items {
        guard let swiftTypeName = sourceSummaryProvider.qualifiedSwiftTypeName(byWITName: typeDef.name.text) else {
            continue
        }
        switch typeDef.body {
        case .enum(let enumType):
            guard let fieldNames = sourceSummaryProvider.enumCaseNames(byWITName: typeDef.name.text) else {
                continue
            }
            try EnumWitRawValueGetter(
                swiftTypeName: swiftTypeName,
                fieldNames: fieldNames,
                type: enumType
            ).print(printer: printer)
        default: break
        }
    }

    for case .function(let namedFunction) in interface.items {
        let guestExport = GuestExportFunction(
            function: namedFunction.function,
            definitionMapping: mapping,
            name: .interface(
                context.rootPackage.packageName,
                interfaceName: interface.name.text,
                id: namedFunction.name.text
            ),
            implementation: try ConvertCase.camelCase(namedFunction.name)
        )
        try guestExport.print(typeResolver: typeResolver, printer: printer)
    }
    printer.write(line: "#endif // #if arch(wasm32)")
    return printer.contents
}
