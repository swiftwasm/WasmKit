import WIT

/// A type that represents a WIT type definition
struct TypeDefinition {
    /// A type that represents the Swift declaration access level
    enum AccessLevel: String {
        case `public`, `internal`
    }

    /// The access level of the type definition
    let accessLevel: AccessLevel

    /// Print the type definition in Swift code
    ///
    /// - Parameters:
    ///   - printer: The printer to use.
    ///   - signatureTranslation: The type namespace to be defined.
    func print(printer: SourcePrinter, signatureTranslation: SignatureTranslation, typeDef: SyntaxNode<TypeDefSyntax>) throws {
        switch typeDef.body {
        case .record(let record):
            try printer.write(line: "\(accessLevel) struct \(ConvertCase.pascalCase(typeDef.name)) {")
            try printer.indent {
                for field in record.fields {
                    try printer.write(line: "\(accessLevel) var \(SwiftName.makeName(field.name)): \(signatureTranslation.convertType(field.type))")
                }

                try printer.write(
                    line: "\(accessLevel) init("
                        + record.fields.map { field in
                            try "\(SwiftName.makeName(field.name)): \(signatureTranslation.convertType(field.type))"
                        }.joined(separator: ", ") + ") {")
                try printer.indent {
                    for field in record.fields {
                        try printer.write(line: "self.\(SwiftName.makeName(field.name)) = \(SwiftName.makeName(field.name))")
                    }
                }
                printer.write(line: "}")
            }
            printer.write(line: "}")
        case .alias(let typeAlias):
            try printer.write(line: "\(accessLevel) typealias \(ConvertCase.pascalCase(typeDef.name)) = \(signatureTranslation.convertType(typeAlias.typeRepr))")
        case .enum(let enumType):
            let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(enumType.cases.count))
            try printer.write(line: "\(accessLevel) enum \(ConvertCase.pascalCase(typeDef.name)): \(discriminantType.swiftTypeName) {")
            try printer.indent {
                for enumCase in enumType.cases {
                    try printer.write(line: "case \(SwiftName.makeName(enumCase.name))")
                }

                printer.write(line: "var witRawValue: \(discriminantType.swiftTypeName) {")
                printer.indent {
                    printer.write(line: "return rawValue")
                }
                printer.write(line: "}")
            }
            printer.write(line: "}")
        case .variant(let variant):
            try printer.write(line: "\(accessLevel) enum \(ConvertCase.pascalCase(typeDef.name)) {")
            try printer.indent {
                for variantCase in variant.cases {
                    var caseDef = try "case \(SwiftName.makeName(variantCase.name))"
                    if let typeRepr = variantCase.type {
                        caseDef += try "(\(signatureTranslation.convertType(typeRepr)))"
                    }
                    printer.write(line: caseDef)
                }
            }
            printer.write(line: "}")
        case .flags(let flags):
            let typeName = try ConvertCase.pascalCase(typeDef.name)
            printer.write(line: "\(accessLevel) struct \(typeName): OptionSet {")
            try printer.indent {
                let rawValueType = CanonicalABI.rawType(ofFlags: flags.flags.count)
                let rawSwiftTypes = rawValueType.swiftTypeNames
                if rawSwiftTypes.count > 1 {
                    printer.write(line: "\(accessLevel) struct RawValue: Equatable, Hashable {")
                    printer.indent {
                        for (i, rawSwiftType) in rawSwiftTypes.enumerated() {
                            printer.write(line: "let field\(i): \(rawSwiftType)")
                        }

                        // Explicitly define initializer without labels to simplify
                        // RawValue initialization codegen
                        let initParams = rawSwiftTypes.enumerated().map {
                            "_ field\($0.offset): \($0.element)"
                        }
                        printer.write(line: "\(accessLevel) init(" + initParams.joined(separator: ", ") + ") {")
                        printer.indent {
                            for i in rawSwiftTypes.indices {
                                printer.write(line: "self.field\(i) = field\(i)")
                            }
                        }
                        printer.write(line: "}")
                    }
                    printer.write(line: "}")
                } else {
                    printer.write(line: "\(accessLevel) typealias RawValue = \(rawSwiftTypes[0])")
                }
                printer.write(line: "\(accessLevel) var rawValue: RawValue")

                // The lowest bit indicate the first flag field
                for (bitPosition, flag) in flags.flags.enumerated() {
                    var flagDef = try "\(accessLevel) static let \(SwiftName.makeName(flag.name)) = "
                    var bitPosition = bitPosition
                    var rawValues: [String] = []

                    for (i, bitsSlot) in rawValueType.bitsSlots.enumerated().reversed() {
                        let rawSwiftType = rawSwiftTypes[i]
                        if 0 <= bitPosition && bitPosition < bitsSlot {
                            rawValues.append("\(rawSwiftType)(1 << \(bitPosition))")
                        } else {
                            rawValues.append("\(rawSwiftType)(0)")
                        }
                        bitPosition -= bitsSlot
                    }

                    flagDef += "\(typeName)(rawValue: RawValue(\(rawValues.joined(separator: ", "))))"
                    printer.write(line: flagDef)
                }

                printer.write(line: "\(accessLevel) init(rawValue: RawValue) {")
                printer.indent {
                    printer.write(line: "self.rawValue = rawValue")
                }
                printer.write(line: "}")

                // SetAlgebra conformance
                if rawSwiftTypes.count > 1 {
                    printer.write(line: "\(accessLevel) init() {")
                    printer.indent {
                        printer.write(line: "self.rawValue = RawValue(" + rawSwiftTypes.map { _ in "0" }.joined(separator: ", ") + ")")
                    }
                    printer.write(line: "}")

                    printer.write(line: "\(accessLevel) mutating func formUnion(_ other: __owned \(typeName)) {")
                    printer.indent {
                        printer.write(
                            line: "self.rawValue = RawValue("
                                + rawSwiftTypes.enumerated().map { i, rawSwiftType in
                                    "self.rawValue.field\(i) | other.rawValue.field\(i)"
                                }.joined(separator: ", ") + ")")
                    }
                    printer.write(line: "}")

                    printer.write(line: "\(accessLevel) mutating func formIntersection(_ other: \(typeName)) {")
                    printer.indent {
                        printer.write(
                            line: "self.rawValue = RawValue("
                                + rawSwiftTypes.enumerated().map { i, rawSwiftType in
                                    "self.rawValue.field\(i) & other.rawValue.field\(i)"
                                }.joined(separator: ", ") + ")")
                    }
                    printer.write(line: "}")

                    printer.write(line: "\(accessLevel) mutating func formSymmetricDifference(_ other: __owned \(typeName)) {")
                    printer.indent {
                        printer.write(
                            line: "self.rawValue = RawValue("
                                + rawSwiftTypes.enumerated().map { i, rawSwiftType in
                                    "self.rawValue.field\(i) ^ other.rawValue.field\(i)"
                                }.joined(separator: ", ") + ")")
                    }
                    printer.write(line: "}")
                }
            }
            printer.write(line: "}")
        default: fatalError("TODO: \(typeDef) definition is not supported yet")
        }
    }

    func printUse(printer: SourcePrinter, use: SyntaxNode<UseSyntax>, contextPackageName: PackageNameSyntax) throws {
        let packageName: PackageNameSyntax
        let interfaceName: Identifier
        switch use.from {
        case .id(let identifier):
            packageName = contextPackageName
            interfaceName = identifier
        case .package(let id, let name):
            packageName = id
            interfaceName = name
        }
        for name in use.names {
            let newName = try ConvertCase.pascalCase(name.asName ?? name.name)
            try printer.write(line: "\(accessLevel) typealias \(newName) = \(typeNamespace(packageName: packageName, interface: interfaceName)).\(ConvertCase.pascalCase(name.name))")
        }
    }
}

extension CanonicalABI.DiscriminantType {
    var swiftTypeName: String {
        switch self {
        case .u8: return "UInt8"
        case .u16: return "UInt16"
        case .u32: return "UInt32"
        }
    }

    var asCoreType: CanonicalABI.CoreType {
        switch self {
        case .u8, .u16, .u32: return .i32
        }
    }
}

extension CanonicalABI.FlagsRawRepresentation {
    var bitsSlots: [Int] {
        switch self {
        case .u8: return [8]
        case .u16: return [16]
        case .u32(let n): return Array(repeating: 32, count: n)
        }
    }
    var swiftTypeNames: [String] {
        switch self {
        case .u8: return ["UInt8"]
        case .u16: return ["UInt16"]
        case .u32(let n):
            return Array(repeating: "UInt32", count: n)
        }
    }
}
