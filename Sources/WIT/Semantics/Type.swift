public indirect enum WITType: Equatable, Hashable {
    case bool
    case u8
    case u16
    case u32
    case u64
    case s8
    case s16
    case s32
    case s64
    case float32
    case float64
    case char
    case string
    case list(WITType)
    case handleOwn(ResourceSyntax)
    case handleBorrow(ResourceSyntax)
    case tuple([WITType])
    case option(WITType)
    case result(ok: WITType?, error: WITType?)
    case future(WITType?)
    case stream(element: WITType?, end: WITType?)

    case record(WITRecord)
    case flags(WITFlags)
    case `enum`(WITEnum)
    case variant(WITVariant)
    case resource(ResourceSyntax)
    case union(WITUnion)
}

public enum InterfaceDefinitionContext: Equatable, Hashable {
    case world(Identifier)
    case package(PackageNameSyntax)
}
public enum TypeDefinitionContext: Equatable, Hashable {
    case world(Identifier)
    case interface(id: Identifier, parent: InterfaceDefinitionContext)
}

public struct WITRecord: Equatable, Hashable {
    public struct Field: Equatable, Hashable {
        public var name: String
        public var type: WITType
        public var syntax: FieldSyntax
    }
    public var name: String
    public var fields: [Field]
    public var parent: TypeDefinitionContext
}

public struct WITUnion: Equatable, Hashable {
    public struct Case: Equatable, Hashable {
        public var type: WITType
        public var syntax: UnionCaseSyntax
    }
    public var name: String
    public var cases: [Case]
    public var parent: TypeDefinitionContext
}

public struct WITEnum: Equatable, Hashable {
    public struct Case: Equatable, Hashable {
        public var name: String
        public var syntax: EnumCaseSyntax
    }
    public var name: String
    public var cases: [Case]
    public var parent: TypeDefinitionContext
}

public struct WITVariant: Equatable, Hashable {
    public struct Case: Equatable, Hashable {
        public var name: String
        public var type: WITType?
        public var syntax: CaseSyntax
    }
    public var name: String
    public var cases: [Case]
    public var parent: TypeDefinitionContext
}

public struct WITFlags: Equatable, Hashable {
    public struct Flag: Equatable, Hashable {
        public var name: String
        public var syntax: FlagSyntax
    }
    public var name: String
    public var flags: [Flag]
    public var parent: TypeDefinitionContext
}

struct TypeResolutionRequest: EvaluationRequest {
    let context: DeclContext
    let typeRepr: TypeReprSyntax

    func evaluate(evaluator: Evaluator) throws -> WITType {
        switch typeRepr {
        case .bool: return .bool
        case .u8: return .u8
        case .u16: return .u16
        case .u32: return .u32
        case .u64: return .u64
        case .s8: return .s8
        case .s16: return .s16
        case .s32: return .s32
        case .s64: return .s64
        case .float32: return .float32
        case .float64: return .float64
        case .char: return .char
        case .string: return .string
        case .name(let id):
            let name = id.text
            return try evaluator.evaluate(request: TypeNameLookupRequest(context: context, name: name))
        case .list(let elementRepr):
            let elementTy = try evaluator.evaluate(request: self.copy(with: elementRepr))
            return .list(elementTy)
        case .handle(let handle):
            let name = handle.id.text
            let resource = try evaluator.evaluate(
                request: ResourceTypeNameLookupRequest(
                    context: context,
                    name: name
                )
            )
            switch handle {
            case .own: return .handleOwn(resource)
            case .borrow: return .handleBorrow(resource)
            }
        case .tuple(let typeReprs):
            let types = try typeReprs.map { typeRepr in
                try evaluator.evaluate(request: self.copy(with: typeRepr))
            }
            return .tuple(types)
        case .option(let elementRepr):
            let elementTy = try evaluator.evaluate(request: self.copy(with: elementRepr))
            return .option(elementTy)
        case .result(let result):
            let okTy = try result.ok.map { try evaluator.evaluate(request: self.copy(with: $0)) }
            let errorTy = try result.error.map { try evaluator.evaluate(request: self.copy(with: $0)) }
            return .result(ok: okTy, error: errorTy)
        case .future(let elementRepr):
            let elementTy = try elementRepr.map { try evaluator.evaluate(request: self.copy(with: $0)) }
            return .future(elementTy)
        case .stream(let stream):
            let elementTy = try stream.element.map { try evaluator.evaluate(request: self.copy(with: $0)) }
            let endTy = try stream.end.map { try evaluator.evaluate(request: self.copy(with: $0)) }
            return .stream(element: elementTy, end: endTy)
        }
    }

    private func copy(with typeRepr: TypeReprSyntax) -> TypeResolutionRequest {
        return TypeResolutionRequest(context: context, typeRepr: typeRepr)
    }
}

struct ResourceTypeNameLookupRequest: EvaluationRequest {
    let context: DeclContext
    let name: String

    func evaluate(evaluator: Evaluator) throws -> ResourceSyntax {
        let type = try evaluator.evaluate(request: TypeNameLookupRequest(context: context, name: name))
        guard case .resource(let resource) = type else {
            throw DiagnosticError(diagnostic: .expectedResourceType(type, textRange: nil))
        }
        return resource
    }
}

public struct TypeResolutionContext {
    let evaluator: Evaluator
    let packageUnit: PackageUnit
    let packageResolver: PackageResolver
}

extension TypeReprSyntax {
    func resolve(evaluator: Evaluator, in context: DeclContext) throws -> WITType {
        try evaluator.evaluate(
            request: TypeResolutionRequest(context: context, typeRepr: self)
        )
    }
}

extension SemanticsContext {
    public func resolveType(
        _ typeRepr: TypeReprSyntax,
        in interface: SyntaxNode<InterfaceSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>,
        contextPackage: PackageUnit
    ) throws -> WITType {
        try resolve(
            typeRepr, kind: .interface(interface, sourceFile: sourceFile, context: .package(contextPackage.packageName)),
            contextPackage: contextPackage)
    }

    public func resolveType(
        _ typeRepr: TypeReprSyntax,
        in world: SyntaxNode<WorldSyntax>,
        sourceFile: SyntaxNode<SourceFileSyntax>,
        contextPackage: PackageUnit
    ) throws -> WITType {
        try resolve(typeRepr, kind: .world(world, sourceFile: sourceFile), contextPackage: contextPackage)
    }

    func resolve(_ typeRepr: TypeReprSyntax, kind: DeclContext.Kind, contextPackage: PackageUnit) throws -> WITType {
        try evaluator.evaluate(
            request: TypeResolutionRequest(
                context: .init(kind: kind, packageUnit: contextPackage, packageResolver: packageResolver),
                typeRepr: typeRepr
            )
        )
    }
}
