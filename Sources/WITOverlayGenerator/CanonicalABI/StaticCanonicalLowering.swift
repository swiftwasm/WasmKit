import WIT

protocol StaticCanonicalLowering: CanonicalLowering where Operand == StaticMetaOperand {
    var printer: SourcePrinter { get }
    var builder: SwiftFunctionBuilder { get }
    var definitionMapping: DefinitionMapping { get }
}

extension StaticCanonicalLowering {
    func lowerBool(_ value: Operand) -> Operand { .lowerBool(value) }

    private func lowerIntToI32(_ value: Operand) -> Operand {
        .call("Int32", arguments: [value])
    }
    private func lowerUIntToI32(_ value: Operand) -> Operand {
        .call("Int32", arguments: [("bitPattern", .call("UInt32", arguments: [value]))])
    }
    func lowerUInt8(_ value: Operand) -> Operand { lowerUIntToI32(value) }
    func lowerUInt16(_ value: Operand) -> Operand { lowerUIntToI32(value) }
    func lowerUInt32(_ value: Operand) -> Operand { lowerUIntToI32(value) }
    func lowerUInt64(_ value: Operand) -> Operand {
        .call("Int64", arguments: [("bitPattern", value)])
    }
    func lowerInt8(_ value: Operand) -> Operand { lowerIntToI32(value) }
    func lowerInt16(_ value: Operand) -> Operand { lowerIntToI32(value) }
    func lowerInt32(_ value: Operand) -> Operand { lowerIntToI32(value) }
    func lowerInt64(_ value: Operand) -> Operand { value }
    func lowerFloat32(_ value: Operand) -> Operand { value }
    func lowerFloat64(_ value: Operand) -> Operand { value }
    func lowerChar(_ value: Operand) -> Operand {
        lowerUInt32(.accessField(value, name: "value"))
    }

    func lowerEnum(_ value: Operand, type: WITEnum) throws -> Operand {
        lowerUIntToI32(.accessField(value, name: "witRawValue"))
    }

    func lowerFlags(_ value: Operand, type: WITFlags) throws -> [Operand] {
        let rawValueTypes = CanonicalABI.rawType(ofFlags: type.flags.count)
        let rawValue = Operand.accessField(value, name: "rawValue")
        if rawValueTypes.bitsSlots.count == 1 {
            return [lowerUIntToI32(rawValue)]
        }
        return rawValueTypes.swiftTypeNames.indices.map {
            lowerUIntToI32(.accessField(rawValue, name: "field\($0)"))
        }
    }

    func lowerOption(
        _ value: Operand, wrapped: WITType,
        lowerPayload: (Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand]) {
        return try lowerVariantLike(
            value, variants: [nil, wrapped],
            swiftCaseNames: ["none", "some"],
            lowerPayload: { caseIndex, payload in
                // If `some`
                if caseIndex == 1 {
                    return try lowerPayload(payload)
                }
                // If `none`
                let coreTypes = CanonicalABI.flatten(type: wrapped).map(\.type)
                return coreTypes.map { self.makeZeroValue(of: $0) }
            }
        )
    }

    func lowerResult(
        _ value: Operand, ok: WITType?, error: WITType?,
        lowerPayload: (Bool, Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand]) {
        return try lowerVariantLike(
            value, variants: [ok, error],
            swiftCaseNames: ["success", "failure"],
            lowerPayload: { caseIndex, payload in
                let isFailure = caseIndex == 1
                let payload = isFailure ? .accessField(payload, name: "content") : payload
                return try lowerPayload(isFailure, payload)
            }
        )
    }

    private func lowerRecordLike(_ value: Operand, fieldNames: [String], temporaryVariablePrefix: String) -> [Operand] {
        var lowered: [Operand] = []
        for fieldName in fieldNames {
            let fieldVar = builder.variable(temporaryVariablePrefix + ConvertCase.pascalCase(kebab: fieldName))
            printer.write(line: "let \(fieldVar) = \(value).\(fieldName)")
            lowered.append(.variable(fieldVar))
        }
        return lowered
    }
    func lowerRecord(_ value: Operand, type: WITRecord) -> [Operand] {
        return lowerRecordLike(
            value, fieldNames: type.fields.map { ConvertCase.camelCase(kebab: $0.name) },
            temporaryVariablePrefix: "record"
        )
    }
    func lowerTuple(_ value: Operand, types: [WIT.WITType]) -> [Operand] {
        return lowerRecordLike(
            value, fieldNames: types.indices.map { $0.description },
            temporaryVariablePrefix: "tuple"
        )
    }
    func lowerVariant(
        _ value: Operand, type: WITVariant, lowerPayload: (Int, Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand]) {
        return try lowerVariantLike(
            value, variants: type.cases.map(\.type),
            swiftCaseNames: definitionMapping.enumCaseSwiftNames(variantType: type),
            lowerPayload: lowerPayload
        )
    }

    func lowerVariantLike(
        _ value: Operand, variants: [WITType?], swiftCaseNames: [String],
        lowerPayload: (Int, Operand) throws -> [Operand]
    ) throws -> (discriminant: Operand, payload: [Operand]) {
        let discriminantType = CanonicalABI.discriminantType(numberOfCases: UInt32(variants.count))
        let discriminantVar = builder.variable("discriminant")
        let payloadVar = builder.variable("payload")

        // Declare lowered variables
        printer.write(line: "let \(discriminantVar): \(discriminantType.asCoreType.swiftTypeName)")
        let payloadCoreTypes = CanonicalABI.flattenVariantPayload(variants: variants)
        let payloadCoreVars = payloadCoreTypes.map { _ in builder.variable("loweredPayloed") }
        for (type, varName) in zip(payloadCoreTypes, payloadCoreVars) {
            printer.write(line: "let \(varName): \(type.swiftTypeName)")
        }

        // Start switch
        printer.write(line: "switch \(value) {")

        for (caseIndex, payloadType) in variants.enumerated() {
            // Handle a case
            let caseName = swiftCaseNames[caseIndex]
            var casePattern = "case .\(SwiftName.makeName(caseName))"
            if payloadType != nil {
                casePattern += "(let \(payloadVar))"
            }
            casePattern += ":"
            printer.write(line: casePattern)

            try printer.indent {
                // Lower discriminant
                printer.write(line: "\(discriminantVar) = \(caseIndex)")

                // Lower payload even though the case doesn't have payload,
                // initialize the payload with zeros
                let loweredSinglePayload = try lowerPayload(caseIndex, .variable(payloadVar))
                for (destCoreVar, srcCoreValue) in zip(payloadCoreVars, loweredSinglePayload) {
                    printer.write(line: "\(destCoreVar) = \(srcCoreValue)")
                }
            }
        }
        printer.write(line: "}")
        // End switch
        return (.variable(discriminantVar), payloadCoreVars.map { .variable($0) })
    }

    func makeZeroValue(of type: CanonicalABI.CoreType) -> Operand {
        switch type {
        case .i32: return .literal("Int32(0)")
        case .i64: return .literal("Int64(0)")
        case .f32: return .literal("Float32(0)")
        case .f64: return .literal("Float64(0)")
        }
    }

    func numericCast(_ value: Operand, from source: CanonicalABI.CoreType, to destination: CanonicalABI.CoreType) -> Operand {
        switch (source, destination) {
        case (.i32, .i32), (.i64, .i64), (.f32, .f32), (.f64, .f64): return value

        case (.i32, .f32):
            return .call("Float32", arguments: [("bitPattern", value)])
        case (.i32, .f64):
            return .call("Float32", arguments: [("bitPattern", numericCast(value, from: .i32, to: .i64))])
        case (.i32, .i64):
            return .call("Int64", arguments: [value])

        case (.f32, .i64):
            return numericCast(numericCast(value, from: .f32, to: .i32), from: .i32, to: .f64)
        case (.f32, .f64):
            return .call("Float64", arguments: [value])

        case (.i64, .f64):
            return .call("Float64", arguments: [("bitPattern", value)])
        case (.f64, .i64), (.f32, .i32):
            return .accessField(value, name: "bitPattern")

        case (.i64, .i32), (.i64, .f32), (.f64, .i32), (.f64, .f32):
            fatalError("Should not trucate while casting")
        }
    }
}

extension CanonicalABI.CoreType {
    fileprivate var swiftTypeName: String {
        switch self {
        case .i32: return "Int32"
        case .i64: return "Int64"
        case .f32: return "Float32"
        case .f64: return "Float64"
        }
    }
}
