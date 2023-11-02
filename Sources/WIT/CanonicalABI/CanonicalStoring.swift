public protocol CanonicalStoring {
    associatedtype Operand
    associatedtype Pointer: Strideable

    func storeUInt8(at pointer: Pointer, _ value: Operand)
    func storeUInt16(at pointer: Pointer, _ value: Operand)
    func storeUInt32(at pointer: Pointer, _ value: Operand)
    func storeUInt64(at pointer: Pointer, _ value: Operand)
    func storeInt8(at pointer: Pointer, _ value: Operand)
    func storeInt16(at pointer: Pointer, _ value: Operand)
    func storeInt32(at pointer: Pointer, _ value: Operand)
    func storeInt64(at pointer: Pointer, _ value: Operand)
    func storeFloat32(at pointer: Pointer, _ value: Operand)
    func storeFloat64(at pointer: Pointer, _ value: Operand)
    func storeFlags(at pointer: Pointer, _ value: Operand, type: WITFlags) throws
    func storeOption(
        at pointer: Pointer, _ value: Operand,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Operand) throws -> Void
    ) throws
    func storeResult(
        at pointer: Pointer, _ value: Operand,
        ok: WITType?, error: WITType?,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Bool, Operand) throws -> Void
    ) throws
    func storeVariant(
        at pointer: Pointer, _ value: Operand, type: WITVariant,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Int, Operand) throws -> Void
    ) throws
}

extension CanonicalABI {
    public static func store<Storing: CanonicalStoring, Lowering: CanonicalLowering>(
        type: WITType,
        value: Storing.Operand,
        pointer: Storing.Pointer,
        storing: inout Storing,
        lowering: inout Lowering
    ) throws where Storing.Operand == Lowering.Operand, Storing.Pointer == Lowering.Pointer {
        func storeList(buffer: Storing.Operand, length: Storing.Operand) {
            storing.storeUInt32(at: pointer, buffer)
            storing.storeUInt32(at: pointer.advanced(by: 4), length)
        }
        func storeRecord(values: [Storing.Operand], types: [WITType]) throws {
            for (value, field) in zip(values, fieldOffsets(fields: types)) {
                let (fieldType, offset) = field
                try store(
                    type: fieldType, value: value,
                    pointer: pointer.advanced(by: Storing.Pointer.Stride(exactly: offset)!),
                    storing: &storing, lowering: &lowering
                )
            }
        }

        switch type {
        case .bool:
            storing.storeUInt8(at: pointer, lowering.lowerBool(value))
        case .u8:
            storing.storeUInt8(at: pointer, value)
        case .u16: storing.storeUInt16(at: pointer, value)
        case .u32: storing.storeUInt32(at: pointer, value)
        case .u64: storing.storeUInt64(at: pointer, value)
        case .s8: storing.storeInt8(at: pointer, value)
        case .s16: storing.storeInt16(at: pointer, value)
        case .s32: storing.storeInt32(at: pointer, value)
        case .s64: storing.storeInt64(at: pointer, value)
        case .float32: storing.storeFloat32(at: pointer, value)
        case .float64: storing.storeFloat64(at: pointer, value)
        case .char: storing.storeUInt32(at: pointer, lowering.lowerChar(value))
        case .enum(let enumType):
            storing.storeUInt32(at: pointer, try lowering.lowerEnum(value, type: enumType))
        case .flags(let flags):
            try storing.storeFlags(at: pointer, value, type: flags)
        case .string:
            let (buffer, length) = try lowering.lowerString(value, encoding: "utf8")
            storeList(buffer: buffer, length: length)
        case .option(let wrapped):
            try storing.storeOption(
                at: pointer, value,
                storeDiscriminant: { discriminant in
                    try store(
                        type: .u8, value: discriminant, pointer: pointer,
                        storing: &storing, lowering: &lowering
                    )
                },
                storePayload: { payload in
                    let offset = Storing.Pointer.Stride(exactly: payloadOffset(cases: [wrapped, nil]))!
                    try store(
                        type: wrapped, value: payload, pointer: pointer.advanced(by: offset),
                        storing: &storing, lowering: &lowering
                    )
                }
            )
        case .result(let ok, let error):
            try storing.storeResult(
                at: pointer, value, ok: ok, error: error,
                storeDiscriminant: { discriminant in
                    try store(
                        type: .u8, value: discriminant, pointer: pointer,
                        storing: &storing, lowering: &lowering
                    )
                },
                storePayload: { isError, payload in
                    let offset = Storing.Pointer.Stride(exactly: payloadOffset(cases: [ok, error]))!
                    guard let type = isError ? error : ok else { return }
                    try store(
                        type: type, value: payload, pointer: pointer.advanced(by: offset),
                        storing: &storing, lowering: &lowering
                    )
                }
            )
        case .list(let element):
            let (buffer, length) = try lowerList(value, element: element, storing: &storing, lowering: &lowering)
            storeList(buffer: buffer, length: length)
        case .tuple(let types):
            let values = lowering.lowerTuple(value, types: types)
            try storeRecord(values: values, types: types)
        case .record(let record):
            let types = record.fields.map(\.type)
            let values = lowering.lowerRecord(value, type: record)
            try storeRecord(values: values, types: types)
        case .variant(let variant):
            let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(variant.cases.count))
            try storing.storeVariant(
                at: pointer, value, type: variant,
                storeDiscriminant: { discriminant in
                    try store(
                        type: discriminantType.asWITType, value: discriminant,
                        pointer: pointer, storing: &storing, lowering: &lowering
                    )
                },
                storePayload: { i, payload in
                    guard let payloadType = variant.cases[i].type else { return }
                    let offset = Storing.Pointer.Stride(exactly: payloadOffset(cases: variant.cases.map(\.type)))!
                    try store(
                        type: payloadType, value: payload, pointer: pointer.advanced(by: offset),
                        storing: &storing, lowering: &lowering
                    )
                })
        default:
            fatalError("TODO: storing \"\(type)\" is unimplemented")
        }
    }
}
