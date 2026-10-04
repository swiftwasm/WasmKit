// Human-readable descriptions for core Wasm types.
//
// These are hand-written (rather than relying on the reflection-based default
// stringification) so that string interpolation of these types also works
// under Embedded Swift, which has no reflection support.

extension AbstractHeapType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .funcRef: return "func"
        case .externRef: return "extern"
        case .exnRef: return "exn"
        case .any: return "any"
        case .eq: return "eq"
        case .i31: return "i31"
        case .structRef: return "struct"
        case .arrayRef: return "array"
        case .noneRef: return "none"
        case .noExtern: return "noextern"
        case .noFunc: return "nofunc"
        case .noExn: return "noexn"
        }
    }
}

extension HeapType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .abstract(let type): return type.description
        case .concrete(let typeIndex): return "$\(typeIndex)"
        }
    }
}

extension ReferenceType: CustomStringConvertible {
    public var description: String {
        if isNullable {
            switch heapType {
            case .abstract(.funcRef): return "funcref"
            case .abstract(.externRef): return "externref"
            case .abstract(.exnRef): return "exnref"
            case .abstract(.any): return "anyref"
            case .abstract(.eq): return "eqref"
            case .abstract(.i31): return "i31ref"
            case .abstract(.structRef): return "structref"
            case .abstract(.arrayRef): return "arrayref"
            case .abstract(.noneRef): return "nullref"
            case .abstract(.noExtern): return "nullexternref"
            case .abstract(.noFunc): return "nullfuncref"
            case .abstract(.noExn): return "nullexnref"
            case .concrete: break
            }
        }
        return "(ref \(isNullable ? "null " : "")\(heapType))"
    }
}

extension ValueType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .i32: return "i32"
        case .i64: return "i64"
        case .f32: return "f32"
        case .f64: return "f64"
        case .v128: return "v128"
        case .ref(let type): return type.description
        }
    }
}

extension FunctionType: CustomStringConvertible {
    public var description: String {
        "(\(ValueType.descriptionList(parameters))) -> (\(ValueType.descriptionList(results)))"
    }
}

extension V128: CustomStringConvertible {
    public var description: String {
        // Build the hex string in a single byte buffer to avoid per-byte
        // string allocations.
        var utf8: [UInt8] = []
        utf8.reserveCapacity(2 + bytes.count * 2)
        utf8.append(UInt8(ascii: "0"))
        utf8.append(UInt8(ascii: "x"))
        for byte in bytes {
            utf8.append(hexDigits.utf8Start[Int(byte >> 4)])
            utf8.append(hexDigits.utf8Start[Int(byte & 0xF)])
        }
        return String(decoding: utf8, as: UTF8.self)
    }
}

extension Reference: CustomStringConvertible {
    public var description: String {
        switch self {
        case .function(let address): return "funcref(\(addressDescription(address)))"
        case .extern(let address): return "externref(\(addressDescription(address)))"
        case .exception(let address): return "exnref(\(addressDescription(address)))"
        case .any(let reference): return "anyref(\(reference.map { "\($0)" } ?? "null"))"
        case .externalized(let reference): return "externref(\(reference))"
        }
    }
}

extension AnyRef: CustomStringConvertible {
    public var description: String {
        if let i31 {
            return "i31(\(i31))"
        } else if let internalizedValue {
            return "host(\(internalizedValue))"
        }
        return "object"
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .i32(let value): return "i32(\(value))"
        case .i64(let value): return "i64(\(value))"
        case .f32(let bitPattern): return "f32(0x\(String(bitPattern, radix: 16)))"
        case .f64(let bitPattern): return "f64(0x\(String(bitPattern, radix: 16)))"
        case .v128(let value): return "v128(\(value))"
        case .ref(let reference): return reference.description
        }
    }
}

extension ValueType {
    /// Returns the descriptions of `types` joined with ", ".
    public static func descriptionList(_ types: [ValueType]) -> String {
        types.map { $0.description }.joined(separator: ", ")
    }
}

extension Value {
    /// Returns the descriptions of `values` joined with ", ".
    public static func descriptionList(_ values: [Value]) -> String {
        values.map { $0.description }.joined(separator: ", ")
    }
}

/// ASCII code units of the lowercase hex digits, indexable in O(1).
private let hexDigits: StaticString = "0123456789abcdef"

private func addressDescription(_ address: Int?) -> String {
    address.map { "\($0)" } ?? "null"
}
