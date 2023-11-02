import WIT

struct StaticCanonicalStoring: CanonicalStoring {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    let printer: SourcePrinter
    let builder: SwiftFunctionBuilder
    let definitionMapping: DefinitionMapping

    private func storeByteSwappable(at pointer: Pointer, value: Operand, type: String) {
        let boundPointer = "\(pointer).assumingMemoryBound(to: \(type).self)"
        printer.write(line: "\(boundPointer).pointee = \(type)(\(value))")
    }

    private func storeUInt(at pointer: Pointer, value: Operand, bitWidth: Int) {
        storeByteSwappable(at: pointer, value: value, type: "UInt\(bitWidth)")
    }
    private func storeInt(at pointer: Pointer, value: Operand, bitWidth: Int) {
        storeByteSwappable(at: pointer, value: value, type: "Int\(bitWidth)")
    }
    private func storeFloat(at pointer: Pointer, value: Operand, bitWidth: Int) {
        storeUInt(at: pointer, value: .accessField(value, name: "bitPattern"), bitWidth: bitWidth)
    }

    func storeUInt8(at pointer: Pointer, _ value: Operand) {
        storeUInt(at: pointer, value: value, bitWidth: 8)
    }
    func storeUInt16(at pointer: Pointer, _ value: Operand) {
        storeUInt(at: pointer, value: value, bitWidth: 16)
    }
    func storeUInt32(at pointer: Pointer, _ value: Operand) {
        storeUInt(at: pointer, value: value, bitWidth: 32)
    }
    func storeUInt64(at pointer: Pointer, _ value: Operand) {
        storeUInt(at: pointer, value: value, bitWidth: 64)
    }
    func storeInt8(at pointer: Pointer, _ value: Operand) {
        storeInt(at: pointer, value: value, bitWidth: 8)
    }
    func storeInt16(at pointer: Pointer, _ value: Operand) {
        storeInt(at: pointer, value: value, bitWidth: 16)
    }
    func storeInt32(at pointer: Pointer, _ value: Operand) {
        storeInt(at: pointer, value: value, bitWidth: 32)
    }
    func storeInt64(at pointer: Pointer, _ value: Operand) {
        storeInt(at: pointer, value: value, bitWidth: 64)
    }
    func storeFloat32(at pointer: Pointer, _ value: Operand) {
        storeFloat(at: pointer, value: value, bitWidth: 32)
    }
    func storeFloat64(at pointer: Pointer, _ value: Operand) {
        storeFloat(at: pointer, value: value, bitWidth: 64)
    }

    func storeFlags(at pointer: Pointer, _ value: Operand, type: WITFlags) throws {
        let rawValueType = CanonicalABI.rawType(ofFlags: type.flags.count)
        let rawValue = Operand.accessField(value, name: "rawValue")
        switch rawValueType {
        case .u8: storeUInt8(at: pointer, rawValue)
        case .u16: storeUInt16(at: pointer, rawValue)
        case .u32(1): storeUInt32(at: pointer, rawValue)
        case .u32(let numberOfU32):
            for i in 0..<numberOfU32 {
                storeUInt32(at: pointer.advanced(by: i * 4), .accessField(rawValue, name: "field\(i)"))
            }
        }
    }

    func storeOption(
        at pointer: Pointer, _ value: Operand,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Operand) throws -> Void
    ) throws {
        printer.write(line: "switch \(value) {")
        let wrappedVar = builder.variable("wrapped")
        printer.write(line: "case .some(let \(wrappedVar)):")
        try printer.indent {
            try storeDiscriminant(.literal("1"))
            try storePayload(.variable(wrappedVar))
        }
        printer.write(line: "case .none:")
        try printer.indent {
            try storeDiscriminant(.literal("0"))
        }
        printer.write(line: "}")
    }

    func storeResult(
        at pointer: Pointer, _ value: Operand, ok: WITType?, error: WITType?,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Bool, Operand) throws -> Void
    ) throws {
        try storeVariantLike(
            at: pointer, value, variants: [ok, error],
            swiftCaseNames: ["success", "failure"],
            storeDiscriminant: storeDiscriminant,
            storePayload: { caseIndex, payload in
                let isFailure = caseIndex == 1
                try storePayload(isFailure, isFailure ? .accessField(payload, name: "content") : payload)
            })
    }

    func storeVariant(
        at pointer: Pointer, _ value: Operand, type: WITVariant,
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Int, Operand) throws -> Void
    ) throws {
        try storeVariantLike(
            at: pointer, value, variants: type.cases.map(\.type),
            swiftCaseNames: definitionMapping.enumCaseSwiftNames(variantType: type),
            storeDiscriminant: storeDiscriminant, storePayload: storePayload
        )
    }

    func storeVariantLike(
        at pointer: Pointer, _ value: Operand,
        variants: [WITType?], swiftCaseNames: [String],
        storeDiscriminant: (Operand) throws -> Void,
        storePayload: (Int, Operand) throws -> Void
    ) throws {
        printer.write(line: "switch \(value) {")
        let payloadVar = builder.variable("payload")
        for (i, variantCaseType) in variants.enumerated() {
            let caseName = swiftCaseNames[i]
            if variantCaseType != nil {
                // Emit case-let only when it has payload type
                printer.write(line: "case .\(caseName)(let \(payloadVar)):")
            } else {
                printer.write(line: "case .\(caseName):")
            }
            try printer.indent {
                try storeDiscriminant(.literal(i.description))
                try storePayload(i, .variable(payloadVar))
            }
        }
        printer.write(line: "}")
    }
}
