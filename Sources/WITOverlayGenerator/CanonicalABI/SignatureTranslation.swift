import WIT

struct SwiftSignature: CustomStringConvertible {
    var name: String
    var parameters: [(label: String, type: String)]
    var resultType: String
    var hasThrows: Bool

    var description: String {
        let parameters = parameters.map { "\($0): \($1)" }
        var result = "func \(name)(\(parameters.joined(separator: ", ")))"
        if hasThrows {
            result += " throws"
        }
        result += " -> \(resultType)"
        return result
    }
}

struct SignatureTranslation {

    var interfaceContext: (interface: SyntaxNode<InterfaceSyntax>, package: PackageUnit)?

    func convertType(_ typeRepr: TypeReprSyntax) throws -> String {
        switch typeRepr {
        case .bool: return "Bool"
        case .u8: return "UInt8"
        case .u16: return "UInt16"
        case .u32: return "UInt32"
        case .u64: return "UInt64"
        case .s8: return "Int8"
        case .s16: return "Int16"
        case .s32: return "Int32"
        case .s64: return "Int64"
        case .float32: return "Float"
        case .float64: return "Double"
        case .char: return "Unicode.Scalar"
        case .string: return "String"
        case .name(let identifier):
            if let (interface, package) = interfaceContext {
                return try typeNamespace(packageName: package.packageName, interface: interface.name) + "." + ConvertCase.pascalCase(identifier)
            }
            return try ConvertCase.pascalCase(identifier)
        case .list(let typeRepr):
            return try "[\(convertType(typeRepr))]"
        case .tuple(let array):
            return try "(" + array.map(convertType(_:)).joined(separator: ", ") + ")"
        case .option(let typeRepr):
            return try "Optional<\(convertType(typeRepr))>"
        case .result(let result):
            let successType = try result.ok.map { try convertType($0) } ?? "Void"
            let failureType =
                try result.error.map {
                    try convertType($0)
                } ?? "Void"
            return "Result<\(successType), ComponentError<\(failureType)>>"
        default: fatalError()
        }
    }

    private func convert(parameters: ParameterList) throws -> [(label: String, type: String)] {
        try parameters.map {
            try ("\(SwiftName.makeName($0.name))", "\(convertType($0.type))")
        }
    }

    private func signature(results: ResultListSyntax) throws -> String {
        switch results {
        case .named(let namedResults):
            return try "("
                + namedResults.map {
                    try "\(SwiftName.makeName($0.name)): \(convertType($0.type))"
                }.joined(separator: ", ") + ")"
        case .anon(let typeRepr):
            return try convertType(typeRepr)
        }
    }

    func signature(function: FunctionSyntax, name: String) throws -> SwiftSignature {
        let parameters = try self.convert(parameters: function.parameters)
        return try SwiftSignature(
            name: SwiftName.makeName(kebab: name),
            parameters: parameters,
            resultType: signature(results: function.results),
            hasThrows: false
        )
    }
}
