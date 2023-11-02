private struct ValidationRequest: EvaluationRequest {
    let unit: PackageUnit
    let packageResolver: PackageResolver

    func evaluate(evaluator: Evaluator) throws -> [String: [Diagnostic]] {
        var diagnostics: [String: [Diagnostic]] = [:]
        for sourceFile in unit.sourceFiles {
            var validator = PackageValidator(
                packageUnit: unit,
                packageResolver: packageResolver,
                evaluator: evaluator,
                sourceFile: sourceFile
            )
            try validator.walk(sourceFile.syntax)
            diagnostics[sourceFile.fileName] = validator.diagnostics
        }
        return diagnostics
    }
}

private struct PackageValidator: ASTVisitor {
    let packageUnit: PackageUnit
    let packageResolver: PackageResolver
    let evaluator: Evaluator
    let sourceFile: SyntaxNode<SourceFileSyntax>
    var diagnostics: [Diagnostic] = []
    var contextStack: [DeclContext] = []
    var declContext: DeclContext? { contextStack.last }

    init(
        packageUnit: PackageUnit,
        packageResolver: PackageResolver,
        evaluator: Evaluator,
        sourceFile: SyntaxNode<SourceFileSyntax>
    ) {
        self.packageUnit = packageUnit
        self.packageResolver = packageResolver
        self.evaluator = evaluator
        self.sourceFile = sourceFile
    }

    mutating func addDiagnostic(_ diagnostic: Diagnostic) {
        self.diagnostics.append(diagnostic)
    }

    mutating func pushContext(_ context: DeclContext) {
        self.contextStack.append(context)
    }
    mutating func popContext() {
        _ = self.contextStack.popLast()
    }

    // No-op for unhandled nodes
    func visit<T>(_: T) throws {}
    func visitPost<T>(_: T) throws {}

    mutating func visit(_ topLevelUse: SyntaxNode<TopLevelUseSyntax>) throws {
        _ = try validate(usePath: topLevelUse.item)
    }

    mutating func visit(_ world: SyntaxNode<WorldSyntax>) throws {
        // Enter world context
        pushContext(.init(kind: .world(world, sourceFile: sourceFile), packageUnit: packageUnit, packageResolver: packageResolver))
    }
    mutating func visitPost(_ world: SyntaxNode<WorldSyntax>) throws {
        popContext()  // Leave world context
    }

    mutating func visit(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        // Enter interface context
        let context: InterfaceDefinitionContext
        switch declContext?.kind {
        case .interface, .inlineInterface:
            fatalError("Interface cannot be defined under other interface")
        case .world(let world, _): context = .world(world.name)
        case nil: context = .package(packageUnit.packageName)
        }
        pushContext(
            .init(
                kind: .interface(interface, sourceFile: sourceFile, context: context),
                packageUnit: packageUnit, packageResolver: packageResolver
            ))
    }
    mutating func visitPost(_ interface: SyntaxNode<InterfaceSyntax>) throws {
        popContext()  // Leave interface context
    }

    mutating func visit(_ importItem: ImportSyntax) throws {
        try visitExternKind(importItem.kind)
    }
    mutating func visitPost(_ importItem: ImportSyntax) throws {
        try visitPostExternKind(importItem.kind)
    }
    mutating func visit(_ export: ExportSyntax) throws {
        try visitExternKind(export.kind)
    }
    mutating func visitPost(_ export: ExportSyntax) throws {
        try visitPostExternKind(export.kind)
    }

    private mutating func visitExternKind(_ externKind: ExternKindSyntax) throws {
        guard case .world(let world, _) = declContext?.kind else {
            fatalError("WorldItem should not be appeared in non-world context")
        }
        switch externKind {
        case .interface(let name, let items):
            // Just set context. validation for inner items are handled by each visit methods
            pushContext(
                .init(
                    kind: .inlineInterface(
                        name: name,
                        items: items,
                        sourceFile: sourceFile,
                        parentWorld: world.name
                    ),
                    packageUnit: packageUnit,
                    packageResolver: packageResolver
                ))
        case .path(let path):
            _ = try validate(usePath: path)
        case .function: break  // Handled by visit(_: FunctionSyntax)
        }
    }
    private mutating func visitPostExternKind(_ externKind: ExternKindSyntax) throws {
        switch externKind {
        case .interface: self.popContext()  // Leave inline interface context
        default: break
        }
    }

    // MARK: Validate types

    mutating func visit(_ alias: TypeAliasSyntax) throws {
        _ = try validate(typeRepr: alias.typeRepr, textRange: nil)
    }

    mutating func visitPost(_ function: FunctionSyntax) throws {
        for param in function.parameters {
            _ = try validate(typeRepr: param.type, textRange: param.textRange)
        }
        switch function.results {
        case .named(let parameterList):
            for result in parameterList {
                _ = try validate(typeRepr: result.type, textRange: function.textRange)
            }
        case .anon(let typeRepr):
            _ = try validate(typeRepr: typeRepr, textRange: function.textRange)
        }
    }

    mutating func visit(_ record: RecordSyntax) throws {
        var fieldNames: Set<String> = []
        for field in record.fields {
            let name = field.name.text
            guard fieldNames.insert(name).inserted else {
                addDiagnostic(.invalidRedeclaration(of: name, textRange: field.name.textRange))
                continue
            }
            _ = try validate(typeRepr: field.type, textRange: field.textRange)
        }
    }

    mutating func visit(_ variant: VariantSyntax) throws {
        var caseNames: Set<String> = []
        for variantCase in variant.cases {
            let name = variantCase.name
            guard caseNames.insert(name.text).inserted else {
                addDiagnostic(.invalidRedeclaration(of: name.text, textRange: name.textRange))
                continue
            }
            guard let payloadType = variantCase.type else { continue }
            _ = try validate(typeRepr: payloadType, textRange: variantCase.textRange)
        }
    }

    mutating func visit(_ union: UnionSyntax) throws {
        for unionCase in union.cases {
            _ = try validate(typeRepr: unionCase.type, textRange: unionCase.textRange)
        }
    }

    mutating func visit(_ use: SyntaxNode<UseSyntax>) throws {
        guard let (interface, sourceFile, packageUnit) = try validate(usePath: use.from) else {
            return  // Skip rest of checks if interface reference is invalid
        }
        // Lookup within the found interface again.
        for useName in use.names {
            let request = TypeNameLookupRequest(
                context: .init(
                    kind: .interface(interface, sourceFile: sourceFile, context: .package(packageUnit.packageName)),
                    packageUnit: packageUnit,
                    packageResolver: packageResolver
                ),
                name: useName.name.text
            )
            try catchingDiagnostic { [evaluator] in
                _ = try evaluator.evaluate(request: request)
            }
        }
    }

    mutating func catchingDiagnostic<R>(textRange: TextRange? = nil, _ body: () throws -> R) throws -> R? {
        do {
            return try body()
        } catch let error as DiagnosticError {
            var diagnostic = error.diagnostic
            if diagnostic.textRange == nil {
                diagnostic.textRange = textRange
            }
            addDiagnostic(diagnostic)
            return nil
        }
    }

    mutating func validate(typeRepr: TypeReprSyntax, textRange: TextRange?) throws -> WITType? {
        guard let declContext else {
            fatalError("TypeRepr outside of declaration context!?")
        }
        let request = TypeResolutionRequest(context: declContext, typeRepr: typeRepr)
        return try self.catchingDiagnostic(textRange: textRange) { [evaluator] in
            try evaluator.evaluate(request: request)
        }
    }

    mutating func validate(usePath: UsePathSyntax) throws -> (
        interface: SyntaxNode<InterfaceSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>,
        packageUnit: PackageUnit
    )? {
        // Check top-level use refers a valid interface
        let request = LookupInterfaceForUsePathRequest(
            use: usePath,
            packageResolver: packageResolver,
            packageUnit: packageUnit,
            sourceFile: declContext?.parentSourceFile
        )
        return try self.catchingDiagnostic { [evaluator] in
            try evaluator.evaluate(request: request)
        }
    }
}

extension PackageUnit {
    func validate(evaluator: Evaluator, packageResolver: PackageResolver) throws -> [String: [Diagnostic]] {
        try evaluator.evaluate(request: ValidationRequest(unit: self, packageResolver: packageResolver))
    }
}

extension SemanticsContext {
    /// Semantically validate this package.
    public func validate(package: PackageUnit) throws -> [String: [Diagnostic]] {
        try package.validate(evaluator: evaluator, packageResolver: packageResolver)
    }
}
