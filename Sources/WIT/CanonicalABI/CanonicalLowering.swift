/// A type that provides lowering of a WIT value to core values.
public protocol CanonicalLowering {
    /// A type of a lowered core value and a type of a WIT value.
    associatedtype Operand

    associatedtype Pointer

    /// Lowers a WIT bool value to a core i32 value.
    func lowerBool(_ value: Operand) -> Operand
    /// Lowers a WIT u8 value to a core i32 value.
    func lowerUInt8(_ value: Operand) -> Operand
    /// Lowers a WIT u16 value to a core i32 value.
    func lowerUInt16(_ value: Operand) -> Operand
    /// Lowers a WIT u32 value to a core i32 value.
    func lowerUInt32(_ value: Operand) -> Operand
    /// Lowers a WIT u64 value to a core i64 value.
    func lowerUInt64(_ value: Operand) -> Operand
    /// Lowers a WIT s8 value to a core i32 value.
    func lowerInt8(_ value: Operand) -> Operand
    /// Lowers a WIT s16 value to a core i32 value.
    func lowerInt16(_ value: Operand) -> Operand
    /// Lowers a WIT s32 value to a core i32 value.
    func lowerInt32(_ value: Operand) -> Operand
    /// Lowers a WIT s64 value to a core i64 value.
    func lowerInt64(_ value: Operand) -> Operand
    /// Lowers a WIT f32 value to a core f32 value.
    func lowerFloat32(_ value: Operand) -> Operand
    /// Lowers a WIT f64 value to a core f64 value.
    func lowerFloat64(_ value: Operand) -> Operand
    /// Lowers a WIT char value to a core i32 value.
    func lowerChar(_ value: Operand) -> Operand
    /// Lowers a WIT enum value to a core i32 value.
    func lowerEnum(_ value: Operand, type: WITEnum) throws -> Operand
    /// Lowers a WIT flags value to core integer values
    func lowerFlags(_ value: Operand, type: WITFlags) throws -> [Operand]
    /// Lowers a WIT string value to a pair of a pointer and a length, both of which are core i32 values.
    func lowerString(_ value: Operand, encoding: String) throws -> (pointer: Operand, length: Operand)
    /// Lowers a WIT list value to a pair of a pointer and a length, both of which are core i32 values.
    func lowerList(
        _ value: Operand, element: WITType,
        storeElement: (Pointer, Operand) throws -> Void
    ) throws -> (pointer: Operand, length: Operand)

    /// Lowers an option value to a pair of a discriminant and payload values.
    /// The implementation of this method should call `lowerPayload` to lower the payload value.
    ///
    /// - Parameters:
    ///   - value: The value to be lowered.
    ///   - wrapped: The wrapped type of the option.
    ///   - lowerPayload: A closure that lowers the payload value.
    /// - Returns: A pair of a discriminant and payload values.
    ///            The discriminant value should be a boolean value.
    ///            The payload value should be a lowered core values of the wrapped type.
    func lowerOption(
        _ value: Operand, wrapped: WITType,
        lowerPayload: (Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand])

    /// Lowers a result value to a pair of a discriminant and payload values.
    /// The implementation of this method should call `lowerPayload` to lower the payload value.
    ///
    /// - Parameters:
    ///   - value: The value to be lowered.
    ///   - ok: The type of the `ok` case.
    ///   - error: The type of the `error` case.
    ///   - lowerPayload: A closure that lowers the payload value. It takes a boolean value that
    ///                   indicates whether the payload is an error or not.
    /// - Returns: A pair of a discriminant and payload values.
    ///            The discriminant value should be a core i32 value.
    func lowerResult(
        _ value: Operand, ok: WITType?, error: WITType?,
        lowerPayload: (Bool, Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand])

    /// Lowers a record value to a list of WIT values.
    func lowerRecord(_ value: Operand, type: WITRecord) -> [Operand]
    /// Lowers a tuple value to a list of WIT values.
    func lowerTuple(_ value: Operand, types: [WITType]) -> [Operand]

    /// Lowers a variant value to a pair of a discriminant and payload values.
    /// The implementation of this method should call `lowerPayload` to lower the payload value.
    ///
    /// - Parameters:
    ///   - value: The value to be lowered.
    ///   - type: The type of the variant.
    ///   - lowerPayload: A closure that lowers the payload value as the payload type of the given case index.
    ///                   The closure should return a list of lowered core values of the payload type.
    ///                   The returned list should have the same types of elements as the flattened payload
    ///                   types in the variant. If the case doesn't have payload, the closure should return
    ///                   zero values of the flattened payload types in the variant.
    /// - Returns: A pair of a discriminant and payload values. Both values should be lowered core values.
    func lowerVariant(
        _ value: Operand, type: WITVariant,
        lowerPayload: (Int, Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand])

    /// Makes a zero value of the given core type.
    func makeZeroValue(of type: CanonicalABI.CoreType) -> Operand

    /// Casts the given value from the source core type to the destination core type.
    /// The `source` type should have smaller or equal size than the `destination` type.
    func numericCast(
        _ value: Operand, from source: CanonicalABI.CoreType, to destination: CanonicalABI.CoreType
    ) -> Operand
}

extension CanonicalABI {
    /// Performs ["Flat Lowering"][cabi_flat_lowering] defined in the Canonical ABI.
    /// It recursively lowers a WIT value to a list of core values.
    ///
    /// [cabi_flat_lowering]: https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md#flat-lowering
    public static func lower<Lowering: CanonicalLowering, Storing: CanonicalStoring>(
        type: WITType,
        value: Lowering.Operand,
        lowering: inout Lowering, storing: inout Storing
    ) throws -> [Lowering.Operand] where Lowering.Operand == Storing.Operand, Lowering.Pointer == Storing.Pointer {
        switch type {
        case .bool: return [lowering.lowerBool(value)]
        case .u8: return [lowering.lowerUInt8(value)]
        case .u16: return [lowering.lowerUInt16(value)]
        case .u32: return [lowering.lowerUInt32(value)]
        case .u64: return [lowering.lowerUInt64(value)]
        case .s8: return [lowering.lowerInt8(value)]
        case .s16: return [lowering.lowerInt16(value)]
        case .s32: return [lowering.lowerInt32(value)]
        case .s64: return [lowering.lowerInt64(value)]
        case .float32: return [lowering.lowerFloat32(value)]
        case .float64: return [lowering.lowerFloat64(value)]
        case .char: return [lowering.lowerChar(value)]
        case .enum(let enumType):
            return [try lowering.lowerEnum(value, type: enumType)]
        case .flags(let flags):
            return try lowering.lowerFlags(value, type: flags)
        case .string:
            let (pointer, length) = try lowering.lowerString(value, encoding: "utf8")
            return [pointer, length]
        case .list(let element):
            let (pointer, length) = try lowerList(value, element: element, storing: &storing, lowering: &lowering)
            return [pointer, length]
        case .record(let record):
            let fieldValues = lowering.lowerRecord(value, type: record)
            return try zip(fieldValues, record.fields).flatMap { value, field in
                try lower(type: field.type, value: value, lowering: &lowering, storing: &storing)
            }
        case .tuple(let types):
            let fieldValues = lowering.lowerTuple(value, types: types)
            return try zip(fieldValues, types).flatMap { value, type in
                try lower(type: type, value: value, lowering: &lowering, storing: &storing)
            }
        case .option(let wrapped):
            return try lowerVariant(
                variants: [nil, wrapped],
                value: value, lowering: &lowering, storing: &storing,
                lowerVariant: { lowering, storing, lowerPayload in
                    let (discriminant, payload) = try lowering.lowerOption(
                        value, wrapped: wrapped,
                        lowerPayload: { payload in
                            try lowerPayload(&lowering, &storing, 1, payload)
                        }
                    )
                    return [discriminant] + payload
                }
            )
        case .result(let ok, let error):
            return try lowerVariant(
                variants: [ok, error],
                value: value, lowering: &lowering, storing: &storing,
                lowerVariant: { lowering, storing, lowerPayload in
                    let (discriminant, payload) = try lowering.lowerResult(
                        value, ok: ok, error: error,
                        lowerPayload: { isError, payload in
                            try lowerPayload(&lowering, &storing, isError ? 1 : 0, payload)
                        }
                    )
                    return [discriminant] + payload
                }
            )
        case .variant(let variant):
            return try lowerVariant(
                variants: variant.cases.map(\.type),
                value: value, lowering: &lowering, storing: &storing,
                lowerVariant: { lowering, storing, lowerPayload in
                    let (discriminant, payload) = try lowering.lowerVariant(
                        value,
                        type: variant,
                        lowerPayload: {
                            try lowerPayload(&lowering, &storing, $0, $1)
                        }
                    )
                    return [discriminant] + payload
                }
            )
        default:
            fatalError("TODO: lifting \"\(type)\" is unimplemented")
        }
    }

    typealias LowerVariant<Lowering: CanonicalLowering, Storing: CanonicalStoring> = (
        _ lowering: inout Lowering, _ storing: inout Storing,
        _ lowerPayloed: LowerVariantPayload<Lowering, Storing>
    ) throws -> [Lowering.Operand]

    typealias LowerVariantPayload<Lowering: CanonicalLowering, Storing: CanonicalStoring> = (
        inout Lowering, inout Storing, Int, Lowering.Operand
    ) throws -> [Lowering.Operand]

    static func lowerVariant<Lowering: CanonicalLowering, Storing: CanonicalStoring>(
        variants: [WITType?], value: Lowering.Operand,
        lowering: inout Lowering, storing: inout Storing,
        lowerVariant: LowerVariant<Lowering, Storing>
    ) throws -> [Lowering.Operand] where Lowering.Operand == Storing.Operand, Lowering.Pointer == Storing.Pointer {
        let unionPayloadCoreTypes = CanonicalABI.flattenVariantPayload(variants: variants)
        let lowerPayload: LowerVariantPayload<Lowering, Storing> = { lowering, storing, caseIndex, payload in
            guard let payloadType = variants[caseIndex] else {
                // If the case doesn't have payload, return zeros
                return unionPayloadCoreTypes.map { lowering.makeZeroValue(of: $0) }
            }
            let singlePayloadCoreTypes = CanonicalABI.flatten(type: payloadType)
            let lowered = try lower(type: payloadType, value: payload, lowering: &lowering, storing: &storing)

            var results: [Lowering.Operand] = []
            for (i, unionPayloadCoreType) in unionPayloadCoreTypes.enumerated() {
                guard i < singlePayloadCoreTypes.count else {
                    // Extend the payload core values with zeros
                    results.append(lowering.makeZeroValue(of: unionPayloadCoreType))
                    continue
                }
                // Unioned payload core type is always larger than or equal to the specific payload core type.
                // See ``CanonicalABI/flattenVariantPayload`` for details.
                let castedPayloadPiece = lowering.numericCast(
                    lowered[i],
                    from: singlePayloadCoreTypes[i].type,
                    to: unionPayloadCoreType
                )
                results.append(castedPayloadPiece)
            }
            return results
        }
        return try lowerVariant(&lowering, &storing, lowerPayload)
    }

    static func lowerList<Lowering: CanonicalLowering, Storing: CanonicalStoring>(
        _ value: Lowering.Operand, element: WITType,
        storing: inout Storing, lowering: inout Lowering
    ) throws -> (
        pointer: Lowering.Operand, length: Lowering.Operand
    ) where Lowering.Operand == Storing.Operand, Lowering.Pointer == Storing.Pointer {
        return try lowering.lowerList(
            value, element: element,
            storeElement: { pointer, value in
                try CanonicalABI.store(
                    type: element, value: value, pointer: pointer,
                    storing: &storing, lowering: &lowering
                )
            }
        )
    }
}
