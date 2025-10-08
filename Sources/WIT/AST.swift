public struct SourceFileSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public var fileName: String
    public var packageId: PackageNameSyntax?
    public var items: [ASTItemSyntax]
}

struct Version: Equatable, Hashable, CustomStringConvertible {
    var major: Int
    var minor: Int
    var patch: Int
    var prerelease: String?
    var buildMetadata: String?

    var textRange: TextRange

    /// Returns true if the version is the same as the other version.
    ///
    /// NOTE: This ignores the `textRange` property to allow for
    /// comparing versions that were parsed from different places.
    func isSameVersion(as other: Version) -> Bool {
        major == other.major && minor == other.minor && patch == other.patch && prerelease == other.prerelease && buildMetadata == other.buildMetadata
    }

    var description: String {
        var text = "\(major).\(minor).\(patch)"
        if let prerelease {
            text += "-\(prerelease)"
        }
        if let buildMetadata {
            text += "+\(buildMetadata)"
        }
        return text
    }
}

public enum ASTItemSyntax: Equatable, Hashable, Sendable {
    case interface(SyntaxNode<InterfaceSyntax>)
    case world(SyntaxNode<WorldSyntax>)
    case use(SyntaxNode<TopLevelUseSyntax>)
}

public struct PackageNameSyntax: Equatable, Hashable, CustomStringConvertible, Sendable {
    public var namespace: Identifier
    public var name: Identifier
    var version: Version?
    var textRange: TextRange

    /// Returns true if the package name is the same as the other package name.
    ///
    /// NOTE: This ignores the `textRange` property to allow for
    /// comparing package names that were parsed from different places.
    func isSamePackage(as other: PackageNameSyntax) -> Bool {
        guard namespace.text == other.namespace.text && name.text == other.name.text else { return false }
        if let version = version, let otherVersion = other.version {
            return version.isSameVersion(as: otherVersion)
        } else {
            return version == nil && other.version == nil
        }
    }

    public var description: String {
        if let version {
            return "\(namespace.text):\(name.text)@\(version)"
        } else {
            return "\(namespace.text):\(name.text)"
        }
    }
}

public struct TopLevelUseSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    var attributes: [AttributeSyntax]
    var item: UsePathSyntax
    var asName: Identifier?
}

public struct WorldSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public typealias Parent = SourceFileSyntax
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var name: Identifier
    public var items: [WorldItemSyntax]
}

public enum WorldItemSyntax: Equatable, Hashable, Sendable {
    case `import`(ImportSyntax)
    case export(ExportSyntax)
    case use(SyntaxNode<UseSyntax>)
    case type(SyntaxNode<TypeDefSyntax>)
    case include(IncludeSyntax)
}

public struct ImportSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var kind: ExternKindSyntax
}

public struct ExportSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var kind: ExternKindSyntax
}

public enum ExternKindSyntax: Equatable, Hashable, Sendable {
    case interface(Identifier, [InterfaceItemSyntax])
    case path(UsePathSyntax)
    case function(Identifier, FunctionSyntax)
}

public struct InterfaceSyntax: Equatable, Hashable, CustomStringConvertible, SyntaxNodeProtocol {
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var name: Identifier
    public var items: [InterfaceItemSyntax]

    public var description: String {
        "Interface(\(name), items: \(items))"
    }
}

public enum InterfaceItemSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    case typeDef(SyntaxNode<TypeDefSyntax>)
    case function(SyntaxNode<NamedFunctionSyntax>)
    case use(SyntaxNode<UseSyntax>)
}

public struct TypeDefSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var name: Identifier
    public var body: TypeDefBodySyntax
}

public enum TypeDefBodySyntax: Equatable, Hashable, Sendable {
    case flags(FlagsSyntax)
    case resource(ResourceSyntax)
    case record(RecordSyntax)
    case variant(VariantSyntax)
    case union(UnionSyntax)
    case `enum`(EnumSyntax)
    case alias(TypeAliasSyntax)
}

public struct TypeAliasSyntax: Equatable, Hashable, Sendable {
    public let typeRepr: TypeReprSyntax
}

public indirect enum TypeReprSyntax: Equatable, Hashable, Sendable {
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
    case name(Identifier)
    case list(TypeReprSyntax)
    case handle(HandleSyntax)
    case tuple([TypeReprSyntax])
    case option(TypeReprSyntax)
    case result(ResultSyntax)
    case future(TypeReprSyntax?)
    case stream(StreamSyntax)
}

public enum HandleSyntax: Equatable, Hashable, Sendable {
    case own(resource: Identifier)
    case borrow(resource: Identifier)

    var id: Identifier {
        switch self {
        case .own(let resource): return resource
        case .borrow(let resource): return resource
        }
    }
}

public struct ResourceSyntax: Equatable, Hashable, Sendable {
    var functions: [ResourceFunctionSyntax]
}

public enum ResourceFunctionSyntax: Equatable, Hashable, Sendable {
    case method(SyntaxNode<NamedFunctionSyntax>)
    case `static`(SyntaxNode<NamedFunctionSyntax>)
    case constructor(SyntaxNode<NamedFunctionSyntax>)
}

public struct RecordSyntax: Equatable, Hashable, Sendable {
    public var fields: [FieldSyntax]
}

public struct FieldSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var name: Identifier
    public var type: TypeReprSyntax
    var textRange: TextRange
}

public struct FlagsSyntax: Equatable, Hashable, Sendable {
    public var flags: [FlagSyntax]
}

public struct FlagSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var name: Identifier
}

public struct VariantSyntax: Equatable, Hashable, Sendable {
    public var cases: [CaseSyntax]
    var textRange: TextRange
}

public struct CaseSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var name: Identifier
    public var type: TypeReprSyntax?
    var textRange: TextRange
}

public struct EnumSyntax: Equatable, Hashable, Sendable {
    public var cases: [EnumCaseSyntax]
    var textRange: TextRange
}

public struct EnumCaseSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var name: Identifier
    var textRange: TextRange
}

public struct ResultSyntax: Equatable, Hashable, Sendable {
    public let ok: TypeReprSyntax?
    public let error: TypeReprSyntax?
}

public struct StreamSyntax: Equatable, Hashable, Sendable {
    var element: TypeReprSyntax?
    var end: TypeReprSyntax?
}

public struct NamedFunctionSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public var documents: DocumentsSyntax
    public var attributes: [AttributeSyntax]
    public var name: Identifier
    public var function: FunctionSyntax
}

public struct UnionSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public var cases: [UnionCaseSyntax]
    var textRange: TextRange
}

public struct UnionCaseSyntax: Equatable, Hashable, Sendable {
    public var documents: DocumentsSyntax
    public var type: TypeReprSyntax
    var textRange: TextRange
}

public struct ParameterSyntax: Equatable, Hashable, Sendable {
    public var name: Identifier
    public var type: TypeReprSyntax
    var textRange: TextRange
}
public typealias ParameterList = [ParameterSyntax]

public enum ResultListSyntax: Equatable, Hashable, Sendable {
    case named(ParameterList)
    case anon(TypeReprSyntax)

    public var types: [TypeReprSyntax] {
        switch self {
        case .anon(let type): return [type]
        case .named(let named): return named.map(\.type)
        }
    }
}

public struct FunctionSyntax: Equatable, Hashable, Sendable {
    public var parameters: ParameterList
    public var results: ResultListSyntax
    var textRange: TextRange
}

public struct UseSyntax: Equatable, Hashable, SyntaxNodeProtocol {
    public var attributes: [AttributeSyntax]
    public var from: UsePathSyntax
    public var names: [UseNameSyntax]
}

public enum UsePathSyntax: Equatable, Hashable, Sendable {
    case id(Identifier)
    case package(id: PackageNameSyntax, name: Identifier)

    var name: Identifier {
        switch self {
        case .id(let identifier): return identifier
        case .package(_, let name): return name
        }
    }
}

public struct UseNameSyntax: Equatable, Hashable, Sendable {
    public var name: Identifier
    public var asName: Identifier?
}

public struct IncludeSyntax: Equatable, Hashable, Sendable {
    var attributes: [AttributeSyntax]
    var from: UsePathSyntax
    var names: [IncludeNameSyntax]
}

public struct IncludeNameSyntax: Equatable, Hashable, Sendable {
    var name: Identifier
    var asName: Identifier
}

public struct Identifier: Equatable, Hashable, CustomStringConvertible, Sendable {
    public var text: String
    var textRange: TextRange

    public var description: String {
        return "\"\(text)\""
    }
}

public struct DocumentsSyntax: Equatable, Hashable, Sendable {
    var comments: [String]
}

public enum AttributeSyntax: Equatable, Hashable, Sendable {
    case since(SinceAttributeSyntax)
    case unstable(UnstableAttributeSyntax)
    case deprecated(DeprecatedAttributeSyntax)
}

public struct SinceAttributeSyntax: Equatable, Hashable, Sendable {
    let version: Version
    let feature: Identifier?
    let textRange: TextRange
}

public struct UnstableAttributeSyntax: Equatable, Hashable, Sendable {
    let textRange: TextRange
    let feature: Identifier
}

public struct DeprecatedAttributeSyntax: Equatable, Hashable, Sendable {
    let textRange: TextRange
    let version: Version
}
