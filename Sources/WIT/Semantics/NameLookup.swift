struct DeclContext: Equatable, Hashable {
    enum Kind: Equatable, Hashable {
        case interface(SyntaxNode<InterfaceSyntax>, sourceFile: SyntaxNode<SourceFileSyntax>, context: InterfaceDefinitionContext)
        case inlineInterface(
            name: Identifier,
            items: [InterfaceItemSyntax],
            sourceFile: SyntaxNode<SourceFileSyntax>,
            parentWorld: Identifier
        )
        case world(SyntaxNode<WorldSyntax>, sourceFile: SyntaxNode<SourceFileSyntax>)
    }

    let kind: Kind
    let packageUnit: PackageUnit
    let packageResolver: PackageResolver

    var parentSourceFile: SyntaxNode<SourceFileSyntax>? {
        switch kind {
        case .inlineInterface(_, _, let sourceFile, _), .world(_, let sourceFile), .interface(_, let sourceFile, _):
            return sourceFile
        }
    }
}

/// Lookup a type with the given name from the given declaration context
struct TypeNameLookup {
    let context: DeclContext
    let name: String
    let evaluator: Evaluator

    func lookup() throws -> WITType {
        switch context.kind {
        case .interface(let interface, _, _):
            return try lookupInterface(interface.items)
        case .inlineInterface(_, let items, _, _):
            return try lookupInterface(items)
        case .world(let world, _):
            return try lookupWorld(world)
        }
    }

    func lookupInterface(_ interfaceItems: [InterfaceItemSyntax]) throws -> WITType {
        for item in interfaceItems {
            switch item {
            case .function: break
            case .typeDef(let typeDef):
                if typeDef.name.text == name {
                    return try typeDef.syntax.asWITType(evaluator: evaluator, context: context)
                }
            case .use(let use):
                if let resolved = try lookupUse(use) {
                    return resolved
                }
            }
        }
        throw DiagnosticError(diagnostic: .cannotFindType(of: name, textRange: nil))
    }

    func lookupWorld(_ world: SyntaxNode<WorldSyntax>) throws -> WITType {
        for item in world.items {
            switch item {
            case .import, .export, .include: break
            case .use(let use):
                if let resolved = try lookupUse(use) {
                    return resolved
                }
            case .type(let typeDef):
                if typeDef.name.text == name {
                    return try typeDef.syntax.asWITType(evaluator: evaluator, context: context)
                }
            }
        }
        throw DiagnosticError(diagnostic: .cannotFindType(of: name, textRange: nil))
    }

    func lookupUse(_ use: SyntaxNode<UseSyntax>) throws -> WITType? {
        for useName in use.names {
            let found: Bool
            if let asName = useName.asName {
                found = name == asName.text
            } else {
                found = name == useName.name.text
            }

            guard found else { continue }

            // If a `use` found, it must be a valid reference
            let (interface, sourceFile, packageUnit) = try evaluator.evaluate(
                request: LookupInterfaceForUsePathRequest(
                    use: use.from,
                    packageResolver: context.packageResolver,
                    packageUnit: context.packageUnit,
                    sourceFile: context.parentSourceFile
                )
            )
            // Lookup within the found interface again.
            return try evaluator.evaluate(
                request: TypeNameLookupRequest(
                    context: .init(
                        kind: .interface(
                            interface,
                            sourceFile: sourceFile,
                            context: .package(packageUnit.packageName)
                        ),
                        packageUnit: packageUnit,
                        packageResolver: context.packageResolver
                    ),
                    name: useName.name.text
                )
            )
        }
        return nil
    }
}

struct TypeNameLookupRequest: EvaluationRequest {
    let context: DeclContext
    let name: String

    func evaluate(evaluator: Evaluator) throws -> WITType {
        let lookup = TypeNameLookup(context: context, name: name, evaluator: evaluator)
        return try lookup.lookup()
    }
}

struct LookupPackageRequest: EvaluationRequest {
    let packageResolver: PackageResolver
    let packageName: PackageNameSyntax

    func evaluate(evaluator: Evaluator) throws -> PackageUnit {
        guard
            let pkgUnit = packageResolver.findPackage(
                namespace: packageName.namespace.text,
                package: packageName.name.text,
                version: packageName.version
            )
        else {
            throw DiagnosticError(diagnostic: .noSuchPackage(packageName, textRange: packageName.textRange))
        }
        return pkgUnit
    }
}

struct LookupInterfaceInPackageRequest: EvaluationRequest {
    let packageUnit: PackageUnit
    let name: String

    func evaluate(evaluator: Evaluator) throws -> (
        interface: SyntaxNode<InterfaceSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>
    ) {
        for sourceFile in packageUnit.sourceFiles {
            for case .interface(let iface) in sourceFile.items {
                if iface.name.text == name { return (iface, sourceFile) }
            }
        }
        throw DiagnosticError(diagnostic: .cannotFindInterface(of: name, textRange: nil))
    }
}

struct LookupInterfaceForUsePathRequest: EvaluationRequest {
    let use: UsePathSyntax
    let packageResolver: PackageResolver
    let packageUnit: PackageUnit
    let sourceFile: SyntaxNode<SourceFileSyntax>?

    func evaluate(evaluator: Evaluator) throws -> (
        interface: SyntaxNode<InterfaceSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>,
        packageUnit: PackageUnit
    ) {
        let packageUnit: PackageUnit
        let interface: SyntaxNode<InterfaceSyntax>
        let sourceFile: SyntaxNode<SourceFileSyntax>
        switch use {
        case .id(let id):
            // Bare form `iface.{type}` refers to an interface defined in the same package.
            packageUnit = self.packageUnit
            (interface, sourceFile) = try evaluator.evaluate(
                request: LookupLocalInterfaceRequest(
                    packageResolver: packageResolver,
                    packageUnit: packageUnit,
                    sourceFile: self.sourceFile, name: id.text
                )
            )
        case .package(let packageName, let id):
            // Fully-qualified type reference `use namespace.pkg.{type}`
            packageUnit = try evaluator.evaluate(
                request: LookupPackageRequest(
                    packageResolver: self.packageResolver,
                    packageName: packageName
                )
            )
            (interface, sourceFile) = try evaluator.evaluate(
                request: LookupInterfaceInPackageRequest(packageUnit: packageUnit, name: id.text)
            )
        }
        return (interface, sourceFile, packageUnit)
    }
}

struct LookupLocalInterfaceRequest: EvaluationRequest {
    let packageResolver: PackageResolver
    let packageUnit: PackageUnit
    let sourceFile: SyntaxNode<SourceFileSyntax>?
    let name: String

    func evaluate(evaluator: Evaluator) throws -> (
        interface: SyntaxNode<InterfaceSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>
    ) {
        if let sourceFile {
            for case .use(let use) in sourceFile.items {
                let found: Bool
                if let asName = use.asName {
                    found = name == asName.text
                } else {
                    found = name == use.item.name.text
                }
                guard found else { continue }

                let (interface, sourceFile, _) = try evaluator.evaluate(
                    request: LookupInterfaceForUsePathRequest(
                        use: use.item,
                        packageResolver: packageResolver,
                        packageUnit: packageUnit,
                        sourceFile: sourceFile
                    )
                )
                return (interface, sourceFile)
            }
        }
        for sourceFile in packageUnit.sourceFiles {
            for case .interface(let iface) in sourceFile.items {
                if iface.name.text == name { return (iface, sourceFile) }
            }
        }
        throw DiagnosticError(diagnostic: .cannotFindInterface(of: name, textRange: nil))
    }
}

extension DeclContext {
    var definitionContext: TypeDefinitionContext {
        switch self.kind {
        case .interface(let interfaceSyntax, _, let context):
            return .interface(id: interfaceSyntax.name, parent: context)
        case .inlineInterface(let name, _, _, let parentWorld):
            return .interface(id: name, parent: .world(parentWorld))
        case .world(let worldSyntax, _):
            return .world(worldSyntax.name)
        }
    }
}

extension TypeDefSyntax {
    fileprivate func asWITType(evaluator: Evaluator, context: DeclContext) throws -> WITType {
        switch body {
        case .flags(let flags):
            return .flags(
                WITFlags(
                    name: self.name.text,
                    flags: flags.flags.map {
                        WITFlags.Flag(name: $0.name.text, syntax: $0)
                    },
                    parent: context.definitionContext
                )
            )
        case .resource(let resource): return .resource(resource)
        case .record(let record):
            return try .record(
                WITRecord(
                    name: self.name.text,
                    fields: record.fields.map {
                        try WITRecord.Field(
                            name: $0.name.text,
                            type: $0.type.resolve(evaluator: evaluator, in: context),
                            syntax: $0
                        )
                    },
                    parent: context.definitionContext
                )
            )
        case .variant(let variant):
            return try .variant(
                WITVariant(
                    name: self.name.text,
                    cases: variant.cases.map {
                        try WITVariant.Case(
                            name: $0.name.text,
                            type: $0.type?.resolve(evaluator: evaluator, in: context),
                            syntax: $0
                        )
                    },
                    parent: context.definitionContext
                )
            )
        case .union(let union):
            return try .union(
                WITUnion(
                    name: self.name.text,
                    cases: union.cases.map {
                        try WITUnion.Case(
                            type: $0.type.resolve(evaluator: evaluator, in: context),
                            syntax: $0
                        )
                    },
                    parent: context.definitionContext
                )
            )
        case .enum(let `enum`):
            return .enum(
                WITEnum(
                    name: self.name.text,
                    cases: `enum`.cases.map {
                        WITEnum.Case(name: $0.name.text, syntax: $0)
                    },
                    parent: context.definitionContext
                )
            )
        case .alias(let alias):
            return try evaluator.evaluate(request: TypeResolutionRequest(context: context, typeRepr: alias.typeRepr))
        }
    }
}

extension SemanticsContext {
    public func lookupInterface(
        name: String,
        contextPackage: PackageUnit,
        sourceFile: SyntaxNode<SourceFileSyntax>? = nil
    ) throws -> (interface: SyntaxNode<InterfaceSyntax>, sourceFile: SyntaxNode<SourceFileSyntax>) {
        try evaluator.evaluate(
            request: LookupLocalInterfaceRequest(
                packageResolver: packageResolver,
                packageUnit: contextPackage, sourceFile: sourceFile, name: name
            )
        )
    }
}
