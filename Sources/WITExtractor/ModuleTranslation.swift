@available(macOS 11, *)
struct ModuleTranslation {
    let diagnostics: DiagnosticCollection
    let typeMapping: TypeMapping
    var builder: WITBuilder

    mutating func translate(sourceSummary: SwiftSourceSummary) {
        for (_, typeSource) in sourceSummary.typesByWITName {
            translateType(source: typeSource)
        }

        for (_, functionSource) in sourceSummary.functionsByWITName {
            translateFunction(source: functionSource)
        }
    }

    mutating func translateType(source: SwiftTypeSource) {
        switch source {
        case .structType(let source):
            translateStruct(source: source)
        case .enumType(let source):
            translateEnum(source: source)
        }
    }

    mutating func translateStruct(source: SwiftStructSource) {
        guard let witTypeName = typeMapping.lookupWITType(byUsr: source.usr) else {
            return
        }
        var fields: [WITRecord.Field] = []

        for field in source.fields {
            let fieldName = ConvertCase.witIdentifier(identifier: field.name)
            guard let fieldWITType = typeMapping.lookupWITType(byNode: field.type, diagnostics: diagnostics) else {
                diagnostics.add(
                    .skipField(
                        context: source.node.parent.printedName,
                        field: field.name,
                        missingType: field.type.parent.parent.printedName
                    )
                )
                continue
            }
            fields.append(WITRecord.Field(name: fieldName, type: fieldWITType))
        }

        builder.define(
            record: WITRecord(name: witTypeName, fields: fields)
        )
    }

    mutating func translateEnum(source: SwiftEnumSource) {
        guard let witTypeName = typeMapping.lookupWITType(byUsr: source.usr) else {
            return
        }

        var cases: [(name: String, type: String?)] = []
        var hasPayload = false

        for enumCase in source.cases {
            let caseName = ConvertCase.witIdentifier(identifier: enumCase.name)

            var payloadWITType: String?
            if let payloadTypeNode = enumCase.payloadType {
                hasPayload = true
                payloadWITType = typeMapping.lookupWITType(byNode: payloadTypeNode, diagnostics: diagnostics)
                if payloadWITType == nil {
                    diagnostics.add(
                        .skipField(
                            context: source.node.parent.printedName,
                            field: enumCase.name,
                            missingType: payloadTypeNode.parent.parent.printedName
                        )
                    )
                }
            }
            cases.append((caseName, payloadWITType))
        }

        // If the given Swift enum has at least one case with payload, turn it into variant,
        // otherwise optimize to be enum.
        if hasPayload {
            builder.define(variant: WITVariant(name: witTypeName, cases: cases.map { WITVariant.Case(name: $0, type: $1) }))
        } else {
            builder.define(enum: WITEnum(name: witTypeName, cases: cases.map { name, _ in name }))
        }
    }

    mutating func translateFunction(source: SwiftFunctionSource) {
        let witName = ConvertCase.witIdentifier(identifier: source.name)
        let witResultTypeNames = source.results.compactMap { result -> String? in
            guard let singleResult = typeMapping.lookupWITType(byNode: result.type, diagnostics: diagnostics) else {
                diagnostics.add(
                    .skipField(
                        context: source.name,
                        field: "result",
                        missingType: result.type.parent.parent.printedName
                    )
                )
                return nil
            }
            return singleResult
        }

        guard witResultTypeNames.count == source.results.count else {
            // Skip emitting if there is any missing WIT type
            return
        }

        let witResults: WITFunction.Results
        switch source.results.count {
        case 0:
            witResults = .named([])
        case 1:
            witResults = .anon(witResultTypeNames[0])
        default:
            var resultNames = AlphabeticalIterator()
            witResults = .named(
                zip(source.results, witResultTypeNames).map { source, witType in
                    WITFunction.Parameter(name: source.name ?? resultNames.next(), type: witType)
                })
        }

        var parameterNames = AlphabeticalIterator()
        let witParameters = source.parameters.compactMap { param -> WITFunction.Parameter? in
            let name = parameterNames.next()
            guard let type = typeMapping.lookupWITType(byNode: param.type, diagnostics: diagnostics) else {
                diagnostics.add(
                    .skipField(
                        context: source.name,
                        field: param.name ?? "parameter",
                        missingType: param.type.parent.parent.printedName
                    )
                )
                return nil
            }
            return WITFunction.Parameter(name: name, type: type)
        }

        guard witParameters.count == source.parameters.count else {
            // Skip emitting if there is any missing WIT type
            return
        }

        builder.define(
            function: WITFunction(
                name: witName,
                parameters: witParameters,
                results: witResults
            )
        )
    }
}

private struct AlphabeticalIterator {
    var index: Int = 0

    mutating func next() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyz")
        var buffer: [Character] = []
        var tmpIndex = index
        while tmpIndex >= chars.count {
            buffer.append(chars[tmpIndex % chars.count])
            tmpIndex /= chars.count
            tmpIndex -= 1
        }
        buffer.append(chars[tmpIndex])
        index += 1
        return String(buffer)
    }
}
