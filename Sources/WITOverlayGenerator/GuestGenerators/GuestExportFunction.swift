import WIT

struct GuestStaticCanonicalLifting: StaticCanonicalLifting {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    var printer: SourcePrinter
    var builder: SwiftFunctionBuilder
    let definitionMapping: DefinitionMapping

    func liftUInt(_ value: Operand, bitWidth: Int) -> Operand {
        let sourceBiWidth = bitWidth == 64 ? 64 : 32
        return .call(
            "UInt\(bitWidth)",
            arguments: [
                .call("UInt\(sourceBiWidth)", arguments: [("bitPattern", value)])
            ])
    }
    func liftInt(_ value: Operand, bitWidth: Int) -> Operand {
        .call("Int\(bitWidth)", arguments: [value])
    }

    func liftPointer(_ value: Operand, pointeeTypeName: String) -> Operand {
        .forceUnwrap(
            .call(
                "UnsafePointer<\(pointeeTypeName)>",
                arguments: [
                    (
                        "bitPattern", .call("Int", arguments: [value])
                    )
                ]
            ))
    }

    func liftBufferPointer(_ value: Operand, length: Operand) -> Operand {
        .call(
            "UnsafeBufferPointer",
            arguments: [
                ("start", value), ("count", .call("Int", arguments: [length])),
            ])
    }

    func liftList(pointer: Operand, length: Operand, element: WITType, loadElement: (Pointer) throws -> Operand) throws -> Operand {
        let loadElementVar = builder.variable("loadElement")
        try printer.write(line: "let \(loadElementVar): (UnsafeRawPointer) -> \(element.qualifiedSwiftName(mapping: definitionMapping)) = {")
        try printer.indent {
            // NOTE: `loadElement` can print statements
            let loaded = try loadElement(.init(basePointerVar: "$0", offset: 0))
            printer.write(line: "return \(loaded)")
        }
        printer.write(line: "}")

        return .call(
            "Prelude.liftList",
            arguments: [
                ("pointer", .call("UInt32", arguments: [pointer])),
                ("length", .call("UInt32", arguments: [length])),
                ("elementSize", .literal(CanonicalABI.size(type: element).description)),
                ("loadElement", .variable(loadElementVar)),
            ])
    }
}

struct GuestStaticCanonicalLowering: StaticCanonicalLowering {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    var printer: SourcePrinter
    var builder: SwiftFunctionBuilder
    let definitionMapping: DefinitionMapping

    func lowerString(_ value: Operand, encoding: String) throws -> (pointer: Operand, length: Operand) {
        let stringBufferVar = builder.variable("stringBuffer")
        printer.write(line: "let \(stringBufferVar) = Array(\(value).utf8)")
        let operand = StaticMetaOperand.variable(stringBufferVar)
        return (
            .call("Prelude.leakUnderlyingBuffer", arguments: [operand]),
            .call("UInt32", arguments: [.accessField(operand, name: "count")])
        )
    }
    func lowerList(
        _ value: Operand, element: WITType,
        storeElement: (Pointer, Operand) throws -> Void
    ) throws -> (pointer: Operand, length: Operand) {
        let storeElementVar = builder.variable("storeElement")
        try printer.write(line: "let \(storeElementVar): (\(element.qualifiedSwiftName(mapping: definitionMapping)), UnsafeMutableRawPointer) -> Void = {")
        try printer.indent {
            try storeElement(Pointer(basePointerVar: "$1", offset: 0), .variable("$0"))
        }
        printer.write(line: "}")
        let lowered = Operand.call(
            "Prelude.lowerList",
            arguments: [
                (nil, value),
                ("elementSize", .literal(CanonicalABI.size(type: element).description)),
                ("elementAlignment", .literal(CanonicalABI.alignment(type: element).description)),
                ("storeElement", .variable(storeElementVar)),
            ])
        let loweredVar = StaticMetaOperand.variable(builder.variable("stringLowered"))
        printer.write(line: "let \(loweredVar) = \(lowered)")
        return (
            lowerUInt32(.accessField(loweredVar, name: "pointer")),
            lowerUInt32(.accessField(loweredVar, name: "length"))
        )
    }
}

struct GuestExportFunction {
    let function: FunctionSyntax
    let builder = SwiftFunctionBuilder()
    let definitionMapping: DefinitionMapping

    let name: CanonicalFunctionName
    let implementation: String

    func print(
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws {
        let coreSignature = try CanonicalABI.flattenSignature(
            function: function,
            typeResolver: typeResolver
        )

        // TODO: Use `@_expose(wasm)` once it will be merged
        printer.write(line: "@_cdecl(\"\(name.abiName)\")")
        printer.write(
            line: renderSwiftFunctionDecl(
                name: "__export_\(name.uniqueSwiftName)",
                coreSignature: coreSignature
            ) + " {"
        )
        try printer.indent {
            try printBody(
                coreSignature: coreSignature, typeResolver: typeResolver, printer: printer
            )
        }
        printer.write(line: "}")

        if coreSignature.isIndirectResult {
            try printPostReturn(coreSignature: coreSignature, typeResolver: typeResolver, parentPrinter: printer)
        }
    }

    func printBody(
        coreSignature: CanonicalABI.CoreSignature,
        typeResolver: (TypeReprSyntax) throws -> WITType,
        printer: SourcePrinter
    ) throws {
        // Before executing any code, run static constructor (a.k.a ctors) functions
        // to initialize wasi-libc, Swift runtime, and so on.
        printer.write(line: "Prelude.initializeOnce()")

        var arguments = coreSignature.parameters.map {
            StaticMetaOperand.variable($0.swiftLabelName)
        }.makeIterator()

        for parameter in function.parameters {
            let type = try typeResolver(parameter.type)
            var lifting = GuestStaticCanonicalLifting(
                printer: printer, builder: builder,
                definitionMapping: definitionMapping
            )
            var loading = StaticCanonicalLoading(printer: printer, builder: builder)
            let rValue = try WIT.CanonicalABI.lift(
                type: type, coreValues: &arguments, lifting: &lifting, loading: &loading
            )
            try printer.write(line: "let \(SwiftName.makeName(parameter.name)) = \(rValue)")
        }

        let resultVar = builder.variable("result")
        if !function.results.types.isEmpty {
            printer.write(line: "let \(resultVar) = \(implementation)(")
        } else {
            // Don't assign the returned void value to variable to suppress warnings
            printer.write(line: "\(implementation)(")
        }
        try printer.indent {
            for (i, parameter) in function.parameters.enumerated() {
                let isEnd = i == function.parameters.count - 1
                let paramName = try ConvertCase.camelCase(parameter.name)
                printer.write(line: "\(paramName): \(paramName)\(isEnd ? "" : ",")")
            }
        }
        printer.write(line: ")")

        var lowering = GuestStaticCanonicalLowering(
            printer: printer,
            builder: builder,
            definitionMapping: definitionMapping
        )
        var storing = StaticCanonicalStoring(printer: printer, builder: builder, definitionMapping: definitionMapping)

        if coreSignature.isIndirectResult {
            let resultBuffer = builder.variable("resultBuffer")
            for resultTypeRepr in function.results.types {
                let type = try typeResolver(resultTypeRepr)
                printer.write(line: "let \(resultBuffer) = UnsafeMutableRawPointer.allocate(byteCount: \(CanonicalABI.size(type: type)), alignment: \(CanonicalABI.alignment(type: type)))")
                let basePointer = StaticCanonicalStoring.Pointer(
                    basePointerVar: resultBuffer, offset: 0
                )
                try CanonicalABI.store(
                    type: type, value: .variable(resultVar),
                    pointer: basePointer, storing: &storing, lowering: &lowering
                )
            }
            printer.write(line: "return Int32(UInt(bitPattern: \(resultBuffer)))")
        } else {
            var allResultValues: [StaticMetaOperand] = []
            for resultTypeRepr in function.results.types {
                let type = try typeResolver(resultTypeRepr)
                let resultValues = try CanonicalABI.lower(type: type, value: .variable(resultVar), lowering: &lowering, storing: &storing)
                // Number of result values should be 0 or 1
                guard resultValues.count <= 1 else { fatalError("Lowered return value should not have multiple core values") }
                allResultValues.append(contentsOf: resultValues)
            }
            // If the original signature already doesn't have a result type, resultVar is unavailable
            if allResultValues.isEmpty && !function.results.types.isEmpty {
                // Suppress unused variable warning
                printer.write(line: "_ = \(resultVar)")
            }
            printer.write(line: "return (\(allResultValues.map(\.description).joined(separator: ", ")))")
        }
    }

    func printPostReturn(
        coreSignature: CanonicalABI.CoreSignature,
        typeResolver: (TypeReprSyntax) throws -> WITType,
        parentPrinter: SourcePrinter
    ) throws {
        let builder = SwiftFunctionBuilder()
        let printer = SourcePrinter()
        let resultTypes = try function.results.types.map(typeResolver)

        // TODO: Use `@_expose(wasm)` once it will be merged
        printer.write(line: "@_cdecl(\"cabi_post_\(name.abiName)\")")
        printer.write(line: "func __cabi_post_return_\(name.uniqueSwiftName)(")
        let argPointerVar = builder.variable("arg")
        printer.indent {
            assert(coreSignature.results.count == 1, "Currently only single result is supported by Canonical ABI")
            printer.write(line: argPointerVar + ": UnsafeMutableRawPointer")
        }
        printer.write(line: ") {")

        var needsDeallocation = false
        try printer.indent {
            let deallocation = StaticCanonicalDeallocation(printer: printer, builder: builder)
            let loading = StaticCanonicalLoading(printer: printer, builder: builder)
            for (resultType, offset) in CanonicalABI.fieldOffsets(fields: resultTypes) {
                let pointer = StaticMetaPointer(basePointerVar: argPointerVar, offset: offset)
                let result = try CanonicalABI.deallocate(
                    type: resultType, pointer: pointer,
                    deallocation: deallocation, loading: loading
                )
                needsDeallocation = needsDeallocation || result
            }
        }
        printer.write(line: "}")

        if needsDeallocation {
            parentPrinter.write(multiline: printer.contents)
        }
    }
}

extension CanonicalABI.SignatureSegment {
    fileprivate var swiftLabelName: String {
        ConvertCase.camelCase(label.map(ConvertCase.camelCase))
    }
}

private func renderSwiftFunctionDecl(
    name: String,
    coreSignature: CanonicalABI.CoreSignature
) -> String {
    var result = "func \(name)("
    result += coreSignature.parameters.map { param in
        param.swiftLabelName + ": " + param.type.swiftType
    }.joined(separator: ", ")
    result += ")"
    switch coreSignature.results.count {
    case 0: break
    case 1:
        result += " -> " + coreSignature.results[0].type.swiftType
    default:
        result += " -> ("
        result += coreSignature.results.map { result in
            result.swiftLabelName + ": " + result.type.swiftType
        }.joined(separator: ", ")
        result += ")"
    }
    return result
}

extension CanonicalABI.CoreType {
    fileprivate var swiftType: String {
        switch self {
        case .i32: return "Int32"
        case .i64: return "Int64"
        case .f32: return "Float"
        case .f64: return "Double"
        }
    }
}
