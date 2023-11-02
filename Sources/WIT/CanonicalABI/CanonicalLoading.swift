public protocol CanonicalLoading {
    associatedtype Operand
    associatedtype Pointer: Strideable

    func loadUInt8(at pointer: Pointer) -> Operand
    func loadUInt16(at pointer: Pointer) -> Operand
    func loadUInt32(at pointer: Pointer) -> Operand
    func loadUInt64(at pointer: Pointer) -> Operand
    func loadInt8(at pointer: Pointer) -> Operand
    func loadInt16(at pointer: Pointer) -> Operand
    func loadInt32(at pointer: Pointer) -> Operand
    func loadInt64(at pointer: Pointer) -> Operand
    func loadFloat32(at pointer: Pointer) -> Operand
    func loadFloat64(at pointer: Pointer) -> Operand
}

extension CanonicalABI {
    public static func load<Loading: CanonicalLoading, Lifting: CanonicalLifting>(
        loading: inout Loading,
        lifting: inout Lifting,
        type: WITType,
        pointer: Loading.Pointer
    ) throws -> Loading.Operand where Loading.Operand == Lifting.Operand, Lifting.Pointer == Loading.Pointer {
        func loadRecordLike(types: [WITType]) throws -> [Loading.Operand] {
            var fieldValues: [Loading.Operand] = []
            for field in fieldOffsets(fields: types) {
                let (fieldType, offset) = field
                let loaded = try load(
                    loading: &loading, lifting: &lifting,
                    type: fieldType, pointer: pointer.advanced(by: Loading.Pointer.Stride(exactly: offset)!)
                )
                fieldValues.append(loaded)
            }
            return fieldValues
        }
        switch type {
        case .bool: return lifting.liftBool(loading.loadUInt8(at: pointer))
        case .u8: return loading.loadUInt8(at: pointer)
        case .u16: return loading.loadUInt16(at: pointer)
        case .u32: return loading.loadUInt32(at: pointer)
        case .u64: return loading.loadUInt64(at: pointer)
        case .s8: return loading.loadInt8(at: pointer)
        case .s16: return loading.loadInt16(at: pointer)
        case .s32: return loading.loadInt32(at: pointer)
        case .s64: return loading.loadInt64(at: pointer)
        case .float32: return loading.loadFloat32(at: pointer)
        case .float64: return loading.loadFloat64(at: pointer)
        case .char: return lifting.liftChar(loading.loadUInt32(at: pointer))
        case .enum(let enumType):
            let discriminant = loadVariantDiscriminant(
                pointer: pointer, numberOfCases: enumType.cases.count, loading: loading
            )
            return try lifting.liftEnum(discriminant, type: enumType)
        case .flags(let flags):
            let rawValueType = CanonicalABI.rawType(ofFlags: flags.flags.count)
            let rawValues: [Loading.Operand]
            switch rawValueType {
            case .u8: rawValues = [loading.loadUInt8(at: pointer)]
            case .u16: rawValues = [loading.loadUInt16(at: pointer)]
            case .u32(let numberOfU32):
                rawValues = (0..<numberOfU32).map { i in
                    loading.loadUInt32(at: pointer.advanced(by: Loading.Pointer.Stride(exactly: i * 4)!))
                }
            }
            return try lifting.liftFlags(rawValues, type: flags)
        case .string:
            let (buffer, length) = loadList(loading: loading, pointer: pointer)
            return try lifting.liftString(pointer: buffer, length: length, encoding: "utf8")
        case .list(let element):
            let (buffer, length) = loadList(loading: loading, pointer: pointer)
            return try CanonicalABI.liftList(
                pointer: buffer, length: length,
                element: element, lifting: &lifting, loading: &loading
            )
        case .option(let wrapped):
            let discriminant = loading.loadUInt8(at: pointer)
            let offset = Loading.Pointer.Stride(exactly: payloadOffset(cases: [wrapped, nil]))!
            return try lifting.liftOption(
                discriminant: discriminant, wrapped: wrapped,
                liftPayload: {
                    try load(
                        loading: &loading, lifting: &lifting,
                        type: wrapped, pointer: pointer.advanced(by: offset)
                    )
                })
        case .result(let ok, let error):
            let discriminant = loading.loadUInt8(at: pointer)
            let offset = Loading.Pointer.Stride(exactly: payloadOffset(cases: [ok, error]))!
            return try lifting.liftResult(
                discriminant: discriminant, ok: ok, error: error,
                liftPayload: { isError in
                    guard let type = isError ? error : ok else { return nil }
                    return try load(
                        loading: &loading, lifting: &lifting,
                        type: type, pointer: pointer.advanced(by: offset)
                    )
                }
            )
        case .record(let record):
            let types = record.fields.map(\.type)
            return try lifting.liftRecord(fields: loadRecordLike(types: types), type: record)
        case .tuple(let types):
            return try lifting.liftTuple(elements: loadRecordLike(types: types), types: types)
        case .variant(let variant):
            let discriminant = loadVariantDiscriminant(
                pointer: pointer, numberOfCases: variant.cases.count, loading: loading
            )
            let payloadOffset = CanonicalABI.payloadOffset(cases: variant.cases.map(\.type))
            let payloadPtr = pointer.advanced(by: .init(exactly: payloadOffset)!)
            return try lifting.liftVariant(
                discriminant: discriminant, type: variant,
                liftPayload: { i in
                    let variantCase = variant.cases[i]
                    if let caseType = variantCase.type {
                        return try load(loading: &loading, lifting: &lifting, type: caseType, pointer: payloadPtr)
                    }
                    return nil
                })
        default:
            fatalError("TODO: loading \"\(type)\" is unimplemented")
        }
    }

    static func loadList<Loading: CanonicalLoading>(
        loading: Loading, pointer: Loading.Pointer
    ) -> (buffer: Loading.Operand, length: Loading.Operand) {
        let buffer = loading.loadUInt32(at: pointer)
        let length = loading.loadUInt32(at: pointer.advanced(by: 4))
        return (buffer, length)
    }

    static func loadVariantDiscriminant<Loading: CanonicalLoading>(
        pointer: Loading.Pointer, numberOfCases: Int, loading: Loading
    ) -> Loading.Operand {
        let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(numberOfCases))
        let discriminant: Loading.Operand
        switch discriminantType {
        case .u8: discriminant = loading.loadUInt8(at: pointer)
        case .u16: discriminant = loading.loadUInt16(at: pointer)
        case .u32: discriminant = loading.loadUInt32(at: pointer)
        }
        return discriminant
    }
}
