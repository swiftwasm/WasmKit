import WIT

/// A type responsible for lifting a core value representation of WasmKit to a Swift value
struct HostStaticCanonicalLifting: StaticCanonicalLifting {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    let printer: SourcePrinter
    let builder: SwiftFunctionBuilder
    let context: StaticMetaCanonicalCallContext
    let definitionMapping: DefinitionMapping

    func liftUInt(_ value: Operand, bitWidth: Int) -> Operand {
        .call("UInt\(bitWidth)", arguments: [value])
    }
    func liftInt(_ value: Operand, bitWidth: Int) -> Operand {
        let sourceBiWidth = bitWidth == 64 ? 64 : 32
        return .call(
            "Int\(bitWidth)",
            arguments: [
                .call("Int\(sourceBiWidth)", arguments: [("bitPattern", value)])
            ])
    }

    func liftPointer(_ value: Operand, pointeeTypeName: String) -> Operand {
        return .call(
            "UnsafeGuestPointer<\(pointeeTypeName)>",
            arguments: [
                ("memorySpace", .accessField(.variable(context.contextVar), name: "guestMemory")),
                ("offset", value),
            ])
    }

    func liftBufferPointer(_ value: Operand, length: Operand) -> Operand {
        .call(
            "UnsafeGuestBufferPointer",
            arguments: [
                ("baseAddress", value), ("count", length),
            ])
    }

    func liftList(
        pointer: Operand, length: Operand,
        element: WITType, loadElement: (Pointer) throws -> Operand
    ) throws -> Operand {
        let loadElementVar = builder.variable("loadElement")
        try printer.write(line: "let \(loadElementVar): (UnsafeGuestRawPointer) throws -> \(element.qualifiedSwiftName(mapping: definitionMapping)) = {")
        try printer.indent {
            // NOTE: `loadElement` can print statements
            let loaded = try loadElement(.init(basePointerVar: "$0", offset: 0))
            printer.write(line: "return \(loaded)")
        }
        printer.write(line: "}")

        return .call(
            "try CanonicalLifting.liftList",
            arguments: [
                ("pointer", pointer),
                ("length", length),
                ("elementSize", .literal(CanonicalABI.size(type: element).description)),
                ("loadElement", .variable(loadElementVar)),
                ("context", .variable(context.contextVar)),
            ])
    }
}

/// A type responsible for lowering a Swift value to a core value representation of WasmKit
struct HostStaticCanonicalLowering: StaticCanonicalLowering {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer
    let printer: SourcePrinter
    let builder: SwiftFunctionBuilder
    let context: StaticMetaCanonicalCallContext
    let definitionMapping: DefinitionMapping

    func lowerString(_ value: Operand, encoding: String) throws -> (pointer: Operand, length: Operand) {
        let lowered = Operand.call(
            "try CanonicalLowering.lowerString",
            arguments: [
                (nil, value), ("context", .variable(context.contextVar)),
            ])
        let loweredVar = StaticMetaOperand.variable(builder.variable("stringLowered"))
        printer.write(line: "let \(loweredVar) = \(lowered)")
        return (
            lowerUInt32(.accessField(loweredVar, name: "pointer")),
            lowerUInt32(.accessField(loweredVar, name: "length"))
        )
    }

    func lowerList(
        _ value: Operand, element: WIT.WITType,
        storeElement: (Pointer, Operand) throws -> Void
    ) throws -> (pointer: Operand, length: Operand) {
        let storeElementVar = builder.variable("storeElement")
        try printer.write(line: "let \(storeElementVar): (\(element.qualifiedSwiftName(mapping: definitionMapping)), UnsafeGuestRawPointer) throws -> Void = {")
        try printer.indent {
            try storeElement(Pointer(basePointerVar: "$1", offset: 0), .variable("$0"))
        }
        printer.write(line: "}")
        let lowered = Operand.call(
            "try CanonicalLowering.lowerList",
            arguments: [
                (nil, value),
                ("elementSize", .literal(CanonicalABI.size(type: element).description)),
                ("elementAlignment", .literal(CanonicalABI.alignment(type: element).description)),
                ("storeElement", .variable(storeElementVar)),
                ("context", .variable(context.contextVar)),
            ])
        let loweredVar = StaticMetaOperand.variable(builder.variable("listLowered"))
        printer.write(line: "let \(loweredVar) = \(lowered)")
        return (
            lowerUInt32(.accessField(loweredVar, name: "pointer")),
            lowerUInt32(.accessField(loweredVar, name: "length"))
        )
    }
}

/// A type representing a function that wraps an exported function from a WebAssembly module
/// callable from host environment.
struct HostExportFunction {
    let function: FunctionSyntax
    let name: CanonicalFunctionName
    let signatureTranslation: SignatureTranslation
    let builder = SwiftFunctionBuilder()
    let context: StaticMetaCanonicalCallContext
    let definitionMapping: DefinitionMapping

    init(
        function: FunctionSyntax,
        name: CanonicalFunctionName,
        signatureTranslation: SignatureTranslation,
        definitionMapping: DefinitionMapping
    ) {
        self.function = function
        self.name = name
        self.signatureTranslation = signatureTranslation
        self.definitionMapping = definitionMapping
        // Reserve variables used in the function
        self.context = StaticMetaCanonicalCallContext(contextVar: builder.variable("context"))
    }

    private func printLowerArguments(
        parameterNames: some Sequence<String>,
        coreSignature: CanonicalABI.CoreSignature,
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws -> [StaticMetaOperand] {
        // TODO: Support indirect parameters
        var loweredArguments: [StaticMetaOperand] = []
        var coreParameters = coreSignature.parameters.makeIterator()

        var lowering = HostStaticCanonicalLowering(printer: printer, builder: builder, context: context, definitionMapping: definitionMapping)
        var storing = StaticCanonicalStoring(printer: printer, builder: builder, definitionMapping: definitionMapping)

        for (parameter, parameterName) in zip(function.parameters, parameterNames) {
            let type = try typeResolver(parameter.type)
            let loweredValues = try CanonicalABI.lower(
                type: type, value: StaticMetaOperand.variable(parameterName), lowering: &lowering, storing: &storing
            )
            for lowered in loweredValues {
                let loweredVar = builder.variable(parameterName + "Lowered")
                guard let coreType = coreParameters.next() else {
                    fatalError("insufficient number of core types!?")
                }
                printer.write(line: "let \(loweredVar) = \(WasmKitSourcePrinter().printNewValue(lowered, type: coreType.type))")
                loweredArguments.append(.variable(loweredVar))
            }
        }
        return loweredArguments
    }

    private func printReturnIndirectResult(
        call: String,
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws {
        let resultPtrVar = builder.variable("resultPtr")
        var loading = StaticCanonicalLoading(printer: printer, builder: builder)
        printer.write(line: "let \(resultPtrVar) = \(call)[0].i32")

        var lifting = HostStaticCanonicalLifting(
            printer: printer, builder: builder, context: context,
            definitionMapping: definitionMapping
        )
        let hostPointerVar = builder.variable("guestPointer")
        printer.write(
            line: "let \(hostPointerVar) = UnsafeGuestRawPointer(memorySpace: \(context.contextVar).guestMemory, offset: \(resultPtrVar))"
        )

        var loadedResults: [StaticMetaOperand] = []
        for resultType in function.results.types {
            let resolvedResultType = try typeResolver(resultType)
            let loaded = try CanonicalABI.load(
                loading: &loading, lifting: &lifting,
                type: resolvedResultType, pointer: StaticMetaPointer(basePointerVar: hostPointerVar, offset: 0)
            )
            loadedResults.append(loaded)
        }
        printer.write(line: "return (\(loadedResults.map(\.description).joined(separator: ", ")))")
    }

    private func printReturnDirectResult(
        call: String, coreSignature: CanonicalABI.CoreSignature,
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws {
        let resultVar = builder.variable("result")
        printer.write(line: "let \(resultVar) = \(call)")

        if coreSignature.results.isEmpty {
            // Suppress unused variable warning
            printer.write(line: "_ = \(resultVar)")
        }

        var resultCoreValues: [StaticMetaOperand] = []
        for (idx, result) in coreSignature.results.enumerated() {
            let resultElementVar = builder.variable("resultElement")
            printer.write(line: "let \(resultElementVar) = \(resultVar)[\(idx)].\(result.type)")
            resultCoreValues.append(.variable(resultElementVar))
        }
        var resultCoreValuesIterator = resultCoreValues.makeIterator()

        var liftedResults: [StaticMetaOperand] = []
        var lifting = HostStaticCanonicalLifting(
            printer: printer, builder: builder, context: context,
            definitionMapping: definitionMapping
        )
        var loading = StaticCanonicalLoading(printer: printer, builder: builder)
        for resultType in function.results.types {
            let resolvedResultType = try typeResolver(resultType)
            let lifted = try WIT.CanonicalABI.lift(
                type: resolvedResultType, coreValues: &resultCoreValuesIterator,
                lifting: &lifting, loading: &loading
            )
            liftedResults.append(lifted)
        }
        printer.write(line: "return (\(liftedResults.map(\.description).joined(separator: ", ")))")
    }

    /// Prints a Swift source code of the function
    ///
    /// - Parameters:
    ///   - typeResolver: A function that resolves a WIT type from a type representation syntax
    ///   - printer: A printer to print the source code
    func print(
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws {
        let coreSignature = try CanonicalABI.flattenSignature(
            function: function,
            typeResolver: typeResolver
        )
        var signature = try signatureTranslation.signature(function: function, name: ConvertCase.camelCase(kebab: name.apiSwiftName))
        let witParameters = signature.parameters.map(\.label)
        signature.hasThrows = true
        printer.write(line: signature.description + " {")
        try printer.indent {
            let optionsVar = builder.variable("options")
            printer.write(line: "let \(optionsVar) = CanonicalOptions._derive(from: instance, exportName: \"\(name.abiName)\")")
            printer.write(line: "let \(context.contextVar) = CanonicalCallContext(options: \(optionsVar), instance: instance)")
            // Suppress unused variable warning for "context"
            printer.write(line: "_ = \(context.contextVar)")

            let arguments = try printLowerArguments(
                parameterNames: witParameters, coreSignature: coreSignature,
                typeResolver: typeResolver, printer: printer
            )
            let functionVar = builder.variable("function")
            printer.write(
                multiline: """
                    guard let \(functionVar) = instance.exports[function: \"\(name.abiName)\"] else {
                        throw CanonicalABIError(description: "Function \\"\(name.abiName)\\" not found in the instance")
                    }
                    """)
            var call = "try \(functionVar)("
            if !arguments.isEmpty {
                call += "[\(arguments.map(\.description).joined(separator: ", "))]"
            }
            call += ")"
            if coreSignature.isIndirectResult {
                try printReturnIndirectResult(call: call, typeResolver: typeResolver, printer: printer)
            } else {
                try printReturnDirectResult(
                    call: call, coreSignature: coreSignature,
                    typeResolver: typeResolver, printer: printer)
            }
        }
        printer.write(line: "}")
    }
}
