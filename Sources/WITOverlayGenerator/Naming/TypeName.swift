import WIT

extension WITType {
    func qualifiedSwiftName(mapping: DefinitionMapping) throws -> String {
        switch self {
        case .record(let record):
            return try mapping.lookupSwiftName(record: record)
        case .enum(let enumTy):
            return try mapping.lookupSwiftName(enum: enumTy)
        case .flags(let flags):
            return try mapping.lookupSwiftName(flags: flags)
        case .variant(let variant):
            return try mapping.lookupSwiftName(variant: variant)
        case .list(let element):
            return try "[" + element.qualifiedSwiftName(mapping: mapping) + "]"
        case .tuple(let types):
            return try "("
                + types.map {
                    try $0.qualifiedSwiftName(mapping: mapping)
                }.joined(separator: ", ") + ")"
        case .string: return "String"
        case .option(let type):
            return try "Optional<\(type.qualifiedSwiftName(mapping: mapping))>"
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
        case .result(let ok, let error):
            let successTy = try ok?.qualifiedSwiftName(mapping: mapping) ?? "Void"
            let failureTy = try "ComponentError<\(error?.qualifiedSwiftName(mapping: mapping) ?? "Void")>"
            return "Result<\(successTy), \(failureTy)>"
        default: fatalError("\(self) is not supported")
        }
    }
}
