/// A type that provides lifting of a core value to WIT values.
public protocol CanonicalLifting {
    /// A type of a core value and a type of a WIT value.
    associatedtype Operand

    /// A type of a pointer representation.
    associatedtype Pointer: Strideable

    /// Lifts a core i32 value to a WIT bool value.
    func liftBool(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT u8 value.
    func liftUInt8(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT u16 value.
    func liftUInt16(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT u32 value.
    func liftUInt32(_ value: Operand) -> Operand
    /// Lifts a core i64 value to a WIT u64 value.
    func liftUInt64(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT s8 value.
    func liftInt8(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT s16 value.
    func liftInt16(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT s32 value.
    func liftInt32(_ value: Operand) -> Operand
    /// Lifts a core i64 value to a WIT s64 value.
    func liftInt64(_ value: Operand) -> Operand
    /// Lifts a core f32 value to a WIT f32 value.
    func liftFloat32(_ value: Operand) -> Operand
    /// Lifts a core f64 value to a WIT f64 value.
    func liftFloat64(_ value: Operand) -> Operand
    /// Lifts a core i32 value to a WIT char value.
    func liftChar(_ value: Operand) -> Operand
    /// Lifts a pair of a pointer and a length, both of which are core i32 values, to a WIT string value.
    func liftString(pointer: Operand, length: Operand, encoding: String) throws -> Operand
    /// Lifts a pair of a pointer and a length, both of which are core i32 values, to a WIT list value.
    ///
    /// - Parameters:
    ///   - pointer: A pointer that contains the byte representation of the list elements.
    ///   - length: A number of elements in the list.
    ///   - element: A type of the list elements.
    ///   - loadElement: A closure that loads an element from the given pointer.
    func liftList(
        pointer: Operand, length: Operand, element: WITType,
        loadElement: (Pointer) throws -> Operand
    ) throws -> Operand
    /// Lifts lifted WIT values of the fields of a record to a WIT record value.
    func liftRecord(fields: [Operand], type: WITRecord) throws -> Operand
    /// Lifts lifted WIT values of the tuple elements to a WIT tuple value
    func liftTuple(elements: [Operand], types: [WITType]) throws -> Operand
    /// Lifts a core i32 value to a WIT enum value.
    func liftEnum(_ value: Operand, type: WITEnum) throws -> Operand
    /// Lifts core integer values to a WIT flag value.
    func liftFlags(_ value: [Operand], type: WITFlags) throws -> Operand

    /// Lifts a pair of a discriminant and payload core values to a WIT option value.
    ///
    /// - Parameters:
    ///   - discriminant: A core i32 value that represents a discriminant.
    ///   - liftPayload: A closure that lifts a payload core value to a WIT value.
    func liftOption(
        discriminant: Operand, wrapped: WITType, liftPayload: () throws -> Operand
    ) throws -> Operand

    /// Lifts a pair of a discriminant and payload core values to a WIT result value.
    ///
    /// - Parameters:
    ///   - discriminant: A core i32 value that represents a discriminant.
    ///   - liftPayload: A closure that lifts a payload core value to a WIT value.
    ///                  It takes a boolean value that indicates whether the payload is an error or not.
    func liftResult(
        discriminant: Operand, ok: WITType?, error: WITType?, liftPayload: (_ isError: Bool) throws -> Operand?
    ) throws -> Operand

    /// Lifts a pair of a discriminant and payload core values to a WIT variant value.
    ///
    /// - Parameters:
    ///   - discriminant: A core i32 value that represents a discriminant.
    ///   - liftPayload: A closure that lifts a payload core value to a WIT value.
    ///                  It takes a case index of the variant to be lifted.
    func liftVariant(
        discriminant: Operand, type: WITVariant, liftPayload: (Int) throws -> Operand?
    ) throws -> Operand
}

extension CanonicalABI {
    /// Performs ["Flat Lifting"][cabi_flat_lifting] defined in the Canonical ABI.
    /// It recursively lifts a core value to a WIT value.
    ///
    /// [cabi_flat_lifting]: https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md#flat-lifting
    public static func lift<Lifting: CanonicalLifting, Loading: CanonicalLoading>(
        type: WITType,
        coreValues: inout some IteratorProtocol<Lifting.Operand>,
        lifting: inout Lifting,
        loading: inout Loading
    ) throws -> Lifting.Operand where Lifting.Operand == Loading.Operand, Lifting.Pointer == Loading.Pointer {
        switch type {
        case .bool: return lifting.liftBool(coreValues.next()!)
        case .u8: return lifting.liftUInt8(coreValues.next()!)
        case .u16: return lifting.liftUInt16(coreValues.next()!)
        case .u32: return lifting.liftUInt32(coreValues.next()!)
        case .u64: return lifting.liftUInt64(coreValues.next()!)
        case .s8: return lifting.liftInt8(coreValues.next()!)
        case .s16: return lifting.liftInt16(coreValues.next()!)
        case .s32: return lifting.liftInt32(coreValues.next()!)
        case .s64: return lifting.liftInt64(coreValues.next()!)
        case .float32: return lifting.liftFloat32(coreValues.next()!)
        case .float64: return lifting.liftFloat64(coreValues.next()!)
        case .char: return lifting.liftChar(coreValues.next()!)
        case .string:
            return try lifting.liftString(
                pointer: coreValues.next()!,
                length: coreValues.next()!,
                encoding: "utf8"
            )
        case .list(let element):
            return try liftList(
                pointer: coreValues.next()!, length: coreValues.next()!,
                element: element, lifting: &lifting, loading: &loading
            )
        case .handleOwn, .handleBorrow:
            fatalError("TODO: resource type is not supported yet")
        case .record(let record):
            let fields = try record.fields.map { field in
                try lift(type: field.type, coreValues: &coreValues, lifting: &lifting, loading: &loading)
            }
            return try lifting.liftRecord(fields: fields, type: record)
        case .tuple(let types):
            let elements = try types.map { type in
                try lift(type: type, coreValues: &coreValues, lifting: &lifting, loading: &loading)
            }
            return try lifting.liftTuple(elements: elements, types: types)
        case .enum(let enumType):
            return try lifting.liftEnum(coreValues.next()!, type: enumType)
        case .flags(let flags):
            let numberOfI32 = CanonicalABI.numberOfInt32(flagsCount: flags.flags.count)
            let rawValues = (0..<numberOfI32).map { _ in coreValues.next()! }
            return try lifting.liftFlags(rawValues, type: flags)
        case .option(let wrapped):
            let discriminant = coreValues.next()!
            return try lifting.liftOption(
                discriminant: discriminant, wrapped: wrapped,
                liftPayload: {
                    try lift(type: wrapped, coreValues: &coreValues, lifting: &lifting, loading: &loading)
                }
            )
        case .result(let ok, let error):
            let discriminant = coreValues.next()!
            let unionPayloadTypes = CanonicalABI.flattenVariantPayload(variants: [ok, error])
            // Collect all the payload values here so that we can consume them multiple times.
            let unionPayloadValues = unionPayloadTypes.indices.map { _ in coreValues.next()! }
            return try lifting.liftResult(
                discriminant: discriminant, ok: ok, error: error,
                liftPayload: { isError in
                    guard let type = isError ? error : ok else { return nil }
                    var tmpIterator = unionPayloadValues.makeIterator()
                    return try lift(type: type, coreValues: &tmpIterator, lifting: &lifting, loading: &loading)
                }
            )
        case .variant(let variant):
            let discriminant = coreValues.next()!
            let unionPayloadTypes = CanonicalABI.flattenVariantPayload(variants: variant.cases.map(\.type))
            // Collect all the payload values here so that we can consume them multiple times.
            let unionPayloadValues = unionPayloadTypes.indices.map { _ in coreValues.next()! }
            return try lifting.liftVariant(
                discriminant: discriminant, type: variant,
                liftPayload: { caseIndex in
                    let variantCase = variant.cases[caseIndex]
                    guard let payloadType = variantCase.type else { return nil }
                    var tmpIterator = unionPayloadValues.makeIterator()
                    return try lift(type: payloadType, coreValues: &tmpIterator, lifting: &lifting, loading: &loading)
                })
        default:
            fatalError("TODO: lifting \"\(type)\" is unimplemented")
        }
    }

    static func liftList<Lifting: CanonicalLifting, Loading: CanonicalLoading>(
        pointer: Lifting.Operand, length: Lifting.Operand,
        element: WITType,
        lifting: inout Lifting, loading: inout Loading
    ) throws -> Lifting.Operand where Lifting.Operand == Loading.Operand, Lifting.Pointer == Loading.Pointer {
        try lifting.liftList(
            pointer: pointer, length: length, element: element,
            loadElement: { elementPtr in
                return try CanonicalABI.load(
                    loading: &loading, lifting: &lifting,
                    type: element, pointer: elementPtr
                )
            }
        )
    }
}
