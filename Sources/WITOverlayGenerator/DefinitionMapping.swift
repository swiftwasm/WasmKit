import WIT

protocol DefinitionMapping {
    func lookupSwiftName(record: WITRecord) throws -> String
    func lookupSwiftName(enum: WITEnum) throws -> String
    func lookupSwiftName(flags: WITFlags) throws -> String
    func lookupSwiftName(variant: WITVariant) throws -> String

    func enumCaseSwiftNames(enumType: WITEnum) throws -> [String]
    func enumCaseSwiftNames(variantType: WITVariant) throws -> [String]
}

struct SourceDefinitionMapping: DefinitionMapping {
    let sourceSummaryProvider: any SourceSummaryProvider

    enum Error: Swift.Error {
        case missingSource(String)
    }

    private func lookupSwiftName(witType: String) throws -> String {
        guard let swiftTypeName = sourceSummaryProvider.qualifiedSwiftTypeName(byWITName: witType) else {
            throw Error.missingSource(witType)
        }
        return swiftTypeName
    }

    func lookupSwiftName(record: WITRecord) throws -> String {
        try lookupSwiftName(witType: record.name)
    }

    func lookupSwiftName(enum: WITEnum) throws -> String {
        try lookupSwiftName(witType: `enum`.name)
    }

    func lookupSwiftName(flags: WITFlags) throws -> String {
        try lookupSwiftName(witType: flags.name)
    }

    func lookupSwiftName(variant: WITVariant) throws -> String {
        try lookupSwiftName(witType: variant.name)
    }

    func enumCaseSwiftNames(enumType: WITEnum) throws -> [String] {
        guard let cases = sourceSummaryProvider.enumCaseNames(byWITName: enumType.name) else {
            throw Error.missingSource(enumType.name)
        }
        return cases
    }

    func enumCaseSwiftNames(variantType: WITVariant) throws -> [String] {
        guard let cases = sourceSummaryProvider.enumCaseNames(byWITName: variantType.name) else {
            throw Error.missingSource(variantType.name)
        }
        return cases
    }
}

struct GeneratedDefinitionMapping: DefinitionMapping {
    func lookupSwiftName(record: WITRecord) throws -> String {
        return try record.qualifiedSwiftName
    }

    func lookupSwiftName(enum: WITEnum) throws -> String {
        return try `enum`.qualifiedSwiftName
    }

    func lookupSwiftName(flags: WITFlags) throws -> String {
        return try flags.qualifiedSwiftName
    }

    func lookupSwiftName(variant: WITVariant) throws -> String {
        return try variant.qualifiedSwiftName
    }

    func enumCaseSwiftNames(enumType: WITEnum) throws -> [String] {
        enumType.cases.map { SwiftName.makeName(kebab: $0.name) }
    }

    func enumCaseSwiftNames(variantType: WITVariant) throws -> [String] {
        variantType.cases.map { SwiftName.makeName(kebab: $0.name) }
    }
}

private func deriveQualifiedSwiftName(
    parent: TypeDefinitionContext, name: String
) throws -> String {
    switch parent {
    case let .interface(id, .package(packageName)):
        return try typeNamespace(packageName: packageName, interface: id) + "." + ConvertCase.pascalCase(kebab: name)
    case .interface(let id, parent: .world):
        return id.text + ConvertCase.pascalCase(kebab: name)
    case .world:
        return ConvertCase.pascalCase(kebab: name)
    }
}

extension WITRecord {
    fileprivate var qualifiedSwiftName: String {
        get throws { try deriveQualifiedSwiftName(parent: parent, name: name) }
    }
}

extension WITEnum {
    fileprivate var qualifiedSwiftName: String {
        get throws { try deriveQualifiedSwiftName(parent: parent, name: name) }
    }
}

extension WITVariant {
    fileprivate var qualifiedSwiftName: String {
        get throws { try deriveQualifiedSwiftName(parent: parent, name: name) }
    }
}

extension WITFlags {
    fileprivate var qualifiedSwiftName: String {
        get throws { try deriveQualifiedSwiftName(parent: parent, name: name) }
    }
}
