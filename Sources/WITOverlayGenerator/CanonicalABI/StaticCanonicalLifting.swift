import WIT

protocol StaticCanonicalLifting: CanonicalLifting where Operand == StaticMetaOperand {
    var printer: SourcePrinter { get }
    var builder: SwiftFunctionBuilder { get }
    var definitionMapping: DefinitionMapping { get }

    func liftUInt(_ value: Operand, bitWidth: Int) -> Operand
    func liftInt(_ value: Operand, bitWidth: Int) -> Operand
    func liftPointer(_ value: Operand, pointeeTypeName: String) -> Operand
    func liftBufferPointer(_ value: Operand, length: Operand) -> Operand
}

extension StaticCanonicalLifting {
    func liftBool(_ value: Operand) -> Operand {
        .call("Bool", arguments: [.literal("\(value) != 0")])
    }

    private func liftFloat(_ value: Operand, bitWidth: Int) -> Operand {
        .call("Float\(bitWidth)", arguments: [value])
    }

    func liftUInt8(_ value: Operand) -> Operand { liftUInt(value, bitWidth: 8) }
    func liftUInt16(_ value: Operand) -> Operand { liftUInt(value, bitWidth: 16) }
    func liftUInt32(_ value: Operand) -> Operand { liftUInt(value, bitWidth: 32) }
    func liftUInt64(_ value: Operand) -> Operand { liftUInt(value, bitWidth: 64) }
    func liftInt8(_ value: Operand) -> Operand { liftInt(value, bitWidth: 8) }
    func liftInt16(_ value: Operand) -> Operand { liftInt(value, bitWidth: 16) }
    func liftInt32(_ value: Operand) -> Operand { liftInt(value, bitWidth: 32) }
    func liftInt64(_ value: Operand) -> Operand { liftInt(value, bitWidth: 64) }
    func liftFloat32(_ value: Operand) -> Operand { liftFloat(value, bitWidth: 32) }
    func liftFloat64(_ value: Operand) -> Operand { liftFloat(value, bitWidth: 64) }
    func liftChar(_ value: Operand) -> Operand {
        .forceUnwrap(.call("Unicode.Scalar", arguments: [liftUInt32(value)]))
    }

    func liftString(pointer: Operand, length: Operand, encoding: String) throws -> Operand {
        .call(
            "String",
            arguments: [
                ("decoding", liftBufferPointer(liftPointer(pointer, pointeeTypeName: "UInt8"), length: length)),
                ("as", .literal("UTF8.self")),
            ])
    }

    func liftRecord(fields: [Operand], type: WITRecord) throws -> Operand {
        let arguments = zip(fields, type.fields).map { operand, field in
            (ConvertCase.camelCase(kebab: field.name), operand)
        }
        let swiftTypeName = try definitionMapping.lookupSwiftName(record: type)
        return .call(swiftTypeName, arguments: arguments)
    }

    func liftTuple(elements: [Operand], types: [WITType]) throws -> Operand {
        return .literal("(" + elements.map(\.description).joined(separator: ", ") + ")")
    }

    func liftEnum(_ value: Operand, type: WITEnum) throws -> Operand {
        let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(type.cases.count))
        let swiftTypeName = try definitionMapping.lookupSwiftName(enum: type)
        return .forceUnwrap(
            .call(
                swiftTypeName,
                arguments: [
                    (
                        "rawValue", .call(discriminantType.swiftTypeName, arguments: [value])
                    )
                ]
            )
        )
    }

    func liftFlags(_ value: [Operand], type: WITFlags) throws -> Operand {
        let rawValue: Operand
        let swiftTypeName = try definitionMapping.lookupSwiftName(flags: type)
        switch CanonicalABI.rawType(ofFlags: type.flags.count) {
        case .u8: rawValue = liftUInt8(value[0])
        case .u16: rawValue = liftUInt16(value[0])
        case .u32:
            let u32Values = value.map { liftUInt32($0) }
            if u32Values.count == 1 {
                rawValue = u32Values[0]
            } else {
                // Build \(type).RawValue struct from raw values.
                rawValue = .call("\(swiftTypeName).RawValue", arguments: u32Values)
            }
        }
        return .call(swiftTypeName, arguments: [("rawValue", rawValue)])
    }

    func liftOption(discriminant: Operand, wrapped: WITType, liftPayload: () throws -> Operand) throws -> Operand {
        try liftVariantLike(
            discriminant: discriminant,
            swiftCaseNames: ["none", "some"],
            swiftTypeName: WITType.option(wrapped).qualifiedSwiftName(
                mapping: definitionMapping
            ),
            liftPayload: {
                caseIndex in
                if caseIndex == 1 {
                    return try liftPayload()
                } else {
                    return nil
                }
            }
        )
    }

    func liftResult(discriminant: Operand, ok: WITType?, error: WITType?, liftPayload: (Bool) throws -> Operand?) throws -> Operand {
        try liftVariantLike(
            discriminant: discriminant,
            swiftCaseNames: ["success", "failure"],
            swiftTypeName: WITType.result(ok: ok, error: error).qualifiedSwiftName(
                mapping: definitionMapping
            ),
            liftPayload: {
                caseIndex in
                // Put `Void` value even the case doesn't have payload because
                // Swift's `Result` type always expect a paylaod for both cases.
                let isFailure = caseIndex == 1
                let lifted = try liftPayload(isFailure) ?? .literal("()")
                // Wrap with `ComponentError` because not all types used in error conform `Error`
                return isFailure ? .call("ComponentError", arguments: [lifted]) : lifted
            }
        )
    }

    func liftVariant(discriminant: Operand, type: WITVariant, liftPayload: (Int) throws -> Operand?) throws -> Operand {
        try liftVariantLike(
            discriminant: discriminant,
            swiftCaseNames: type.cases.map { SwiftName.makeName(kebab: $0.name) },
            swiftTypeName: definitionMapping.lookupSwiftName(variant: type),
            liftPayload: liftPayload
        )
    }

    func liftVariantLike(
        discriminant: Operand,
        swiftCaseNames: [String], swiftTypeName: String,
        liftPayload: (Int) throws -> Operand?
    ) throws -> Operand {
        let loadedVar = builder.variable("variantLifted")
        printer.write(line: "let \(loadedVar): \(swiftTypeName)")
        printer.write(line: "switch \(discriminant) {")
        for (i, variantCaseName) in swiftCaseNames.enumerated() {
            printer.write(line: "case \(i):")
            try printer.indent {
                let caseName = variantCaseName
                if let liftedPayload = try liftPayload(i) {
                    printer.write(line: "\(loadedVar) = .\(caseName)(\(liftedPayload))")
                } else {
                    printer.write(line: "\(loadedVar) = .\(caseName)")
                }
            }
        }
        printer.write(line: "default: fatalError(\"invalid variant discriminant\")")
        printer.write(line: "}")
        return .variable(loadedVar)
    }
}
