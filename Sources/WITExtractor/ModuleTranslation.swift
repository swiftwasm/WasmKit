struct ModuleTranslation {
    let diagnostics: DiagnosticCollection
    let resolver: TypeResolver
    var builder: WITBuilder

    mutating func translate(inventory: DeclInventory) {
        // Fixed type-then-function order keeps WIT output stable against Swift source reordering.
        for type in inventory.types { translateType(type) }
        for function in inventory.functions { translateFunction(function) }
    }

    mutating func translateType(_ type: TypeEntry) {
        switch type.kind {
        case .structType: translateStruct(type)
        case .enumType: translateEnum(type)
        }
    }

    mutating func translateStruct(_ type: TypeEntry) {
        let scope = type.scopePath + [type.name]
        let witTypeName = type.witName
        var fields: [WITRecord.Field] = []
        for field in type.fields {
            let fieldName = ConvertCase.witIdentifier(identifier: field.name)
            guard let fieldWITType = resolver.resolve(field.type, inScope: scope) else {
                diagnostics.add(
                    .skipField(
                        context: type.qualifiedName, field: field.name,
                        missingType: field.type.trimmedDescription))
                continue
            }
            fields.append(WITRecord.Field(name: fieldName, type: fieldWITType))
        }
        builder.define(record: WITRecord(name: witTypeName, fields: fields))
    }

    mutating func translateEnum(_ type: TypeEntry) {
        let scope = type.scopePath + [type.name]
        let witTypeName = type.witName
        var cases: [(name: String, type: String?)] = []
        let hasPayload = type.cases.contains { !$0.payload.isEmpty }
        for enumCase in type.cases {
            let caseName = ConvertCase.witIdentifier(identifier: enumCase.name)
            var payloadWITType: String?
            if !enumCase.payload.isEmpty {
                payloadWITType = resolver.resolvePayload(enumCase.payload, inScope: scope)
                if payloadWITType == nil {
                    // Drop only the payload, not the case: the overlay maps cases positionally
                    // (SourceDefinitionMapping.enumCaseSwiftNames), so the case set must stay in sync.
                    diagnostics.add(
                        .skipField(
                            context: type.qualifiedName, field: enumCase.name,
                            missingType: enumCase.payload.map(\.trimmedDescription).joined(separator: ", ")))
                }
            }
            cases.append((caseName, payloadWITType))
        }
        if hasPayload {
            builder.define(
                variant: WITVariant(name: witTypeName, cases: cases.map { WITVariant.Case(name: $0, type: $1) }))
        } else {
            builder.define(enum: WITEnum(name: witTypeName, cases: cases.map { name, _ in name }))
        }
    }

    mutating func translateFunction(_ function: FunctionEntry) {
        let witName = function.witName
        guard let parameterTypes = resolver.resolveParameters(function.parameters.map(\.type), inScope: []) else {
            diagnostics.add(
                .skipField(
                    context: function.name, field: "parameter",
                    missingType: function.parameters.map(\.type.trimmedDescription).joined(separator: ", ")))
            return
        }
        guard let resultTypes = resolver.resolveResults(function.returnClause, inScope: []) else {
            diagnostics.add(
                .skipField(
                    context: function.name, field: "result",
                    missingType: function.returnClause?.type.trimmedDescription ?? ""))
            return
        }
        // An anonymous param (`_:`) has no internal name; use an alphabetical placeholder.
        var fallback = AlphabeticalIterator()
        let witParameters = zip(function.parameters, parameterTypes).map { param, witType in
            let name = param.internalName.map { ConvertCase.witIdentifier(identifier: $0) } ?? fallback.next()
            return WITFunction.Parameter(name: name, type: witType)
        }
        // WIT permits at most one result; a multi-element tuple return collapses to one `tuple<...>`.
        let witResults: WITFunction.Results = resultTypes.isEmpty ? .none : .single(resultTypes[0])
        builder.define(function: WITFunction(name: witName, parameters: witParameters, results: witResults))
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
