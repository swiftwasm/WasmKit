public struct SwiftSourceSummary {
    // Those properties are ordered dictionaries to keep the order in the source module.
    public internal(set) var typesByWITName: [(witName: String, source: SwiftTypeSource)]
    public internal(set) var functionsByWITName: [(witName: String, source: SwiftFunctionSource)]

    public func lookupType(byWITName witName: String) -> SwiftTypeSource? {
        typesByWITName.first(where: { $0.witName == witName })?.source
    }
}

public struct SwiftStructSource {
    public struct Field {
        let name: String
        let type: SwiftAPIDigester.SDKNodeTypeNominal
    }
    public let usr: String
    public let fields: [Field]
    let node: SwiftAPIDigester.SDKNodeDecl
}

public struct SwiftEnumSource {
    public struct Case {
        public let name: String
        let payloadType: SwiftAPIDigester.SDKNodeTypeNominal?
    }
    public let usr: String
    public let cases: [Case]
    let node: SwiftAPIDigester.SDKNodeDecl
}

public enum SwiftTypeSource {
    case structType(SwiftStructSource)
    case enumType(SwiftEnumSource)

    var usr: String {
        switch self {
        case .structType(let structSource):
            return structSource.usr
        case .enumType(let enumSource):
            return enumSource.usr
        }
    }
}

public struct SwiftFunctionSource {
    typealias Parameter = (name: String?, type: SwiftAPIDigester.SDKNodeTypeNominal)
    let parameters: [Parameter]
    let results: [Parameter]
    let name: String
}

@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
struct SourceSummaryBuilder {
    let diagnostics: DiagnosticCollection
    let typeMapping: TypeMapping
    var sourceSummary = SwiftSourceSummary(typesByWITName: [], functionsByWITName: [])

    mutating func build(digest: SwiftAPIDigester.Output) {
        build(node: digest.ABIRoot)
    }

    mutating func build(node: SwiftAPIDigester.SDKNode) {
        switch node {
        case .root: break
        case .typeDecl(let typeDecl):
            buildType(node: typeDecl.parent)
        case .decl(let decl):
            if decl.body.declKind == "Func" {
                buildFunction(node: decl)
            }
        case .typeNominal: break
        case .unknown: break
        }

        for child in node.body.children ?? [] {
            build(node: child)
        }
    }

    mutating func buildType(node: SwiftAPIDigester.SDKNodeDecl) {
        guard shouldExtract(node) else { return }
        switch node.body.declKind {
        case "Struct":
            buildStruct(node: node)
        case "Enum":
            buildEnum(node: node)
        default:
            diagnostics.add(.warning("\"\(node.parent.printedName)\" is supported yet to export (\(node.body.declKind))"))
        }
    }

    mutating func buildStruct(node: SwiftAPIDigester.SDKNodeDecl) {
        guard let witTypeName = typeMapping.lookupWITType(byUsr: node.body.usr) else {
            return
        }
        var fields: [SwiftStructSource.Field] = []

        for child in node.parent.children ?? [] {
            guard let declChild = child.decl, declChild.parent.kind == "Var" else { continue }
            // Ignore static fields
            if let isStatic = declChild.body.static, isStatic { continue }

            guard case let .typeNominal(fieldTypeNode) = child.body.children?.first else {
                diagnostics.add(
                    .warning("Skipping \(node.parent.printedName)/\(child.body.printedName) field due to missing nominal type child node")
                )
                continue
            }
            fields.append(SwiftStructSource.Field(name: child.body.name, type: fieldTypeNode))
        }

        sourceSummary.typesByWITName.append(
            (
                witTypeName,
                SwiftTypeSource.structType(
                    SwiftStructSource(
                        usr: node.body.usr,
                        fields: fields,
                        node: node
                    )
                )
            ))
    }

    mutating func buildEnum(node: SwiftAPIDigester.SDKNodeDecl) {
        guard let witTypeName = typeMapping.lookupWITType(byUsr: node.body.usr) else {
            return
        }

        func payloadType(element: SwiftAPIDigester.SDKNodeDecl) -> SwiftAPIDigester.SDKNodeTypeNominal? {
            // EnumElement has a TypeFunc child that has the following signature:
            // 1. `(EnumType.Type) -> (Payload) -> EnumType` if it has payload.
            // 2. `(EnumType.Type) -> EnumType` if it has no payload.
            guard let typeFunc = element.parent.children?.first?.body, typeFunc.kind == "TypeFunc" else {
                diagnostics.add(.warning("Missing TypeFunc node in enum element node \"\(element.parent.printedName)\""))
                return nil
            }
            // TypeFunc has two children, 1. Result type, 2. Tuple of parameter types.
            // See `SwiftDeclCollector::constructTypeNode` in `lib/APIDigester/ModuleAnalyzerNodes.cpp` in Swift.
            guard let resultType = typeFunc.children?.first?.body, resultType.kind == "TypeFunc" else {
                // If the result is not TypeFunc, it has no payload
                return nil
            }
            guard case let .typeNominal(payloadTupleType) = resultType.children?.last else {
                return nil
            }
            return payloadTupleType
        }

        var cases: [SwiftEnumSource.Case] = []

        for child in node.parent.children ?? [] {
            guard let declChild = child.decl, declChild.body.declKind == "EnumElement" else { continue }

            let payloadTypeNode = payloadType(element: declChild)
            cases.append(SwiftEnumSource.Case(name: child.body.name, payloadType: payloadTypeNode))
        }

        // WIT enum/variant doesn't allow empty cases
        guard !cases.isEmpty else { return }

        sourceSummary.typesByWITName.append(
            (
                witTypeName,
                .enumType(
                    SwiftEnumSource(
                        usr: node.body.usr,
                        cases: cases,
                        node: node
                    )
                )
            ))
    }

    mutating func buildFunction(node: SwiftAPIDigester.SDKNodeDecl) {
        guard shouldExtractFunction(node) else { return }

        let witName = ConvertCase.witIdentifier(identifier: node.parent.name)
        var results: [SwiftFunctionSource.Parameter] = []

        if case let .typeNominal(resultNode) = node.parent.children?.first {
            // If returns a tuple, it's a function that returns multiple values.
            if resultNode.parent.parent.name == "Tuple" {
                let tupleElements = resultNode.parent.parent.children ?? []

                for elementNode in tupleElements {
                    guard case let .typeNominal(resultNominalNode) = elementNode else {
                        diagnostics.add(
                            .warning("Skipping \(node.parent.printedName)'s result due to missing nominal type child node")
                        )
                        return
                    }
                    results.append(SwiftFunctionSource.Parameter(name: nil, type: resultNominalNode))
                }
            } else if resultNode.parent.parent.name == "Void" {
                // If it returns Void, no result value
            } else {
                results.append(SwiftFunctionSource.Parameter(name: nil, type: resultNode))
            }
        }

        let parameters =
            node.parent.children?.dropFirst().compactMap { child -> SwiftFunctionSource.Parameter? in
                guard case .typeNominal(let paramTypeNode) = child else { return nil }
                return SwiftFunctionSource.Parameter(name: nil, type: paramTypeNode)
            } ?? []

        sourceSummary.functionsByWITName.append(
            (
                witName,
                SwiftFunctionSource(
                    parameters: parameters,
                    results: results,
                    name: node.parent.name
                )
            ))
    }
}

private func shouldExtract(_ decl: SwiftAPIDigester.SDKNodeDecl) -> Bool {
    guard let spiGroup = decl.body.spi_group_names, spiGroup.contains("WIT") else { return false }
    return true
}

private func shouldExtractFunction(_ decl: SwiftAPIDigester.SDKNodeDecl) -> Bool {
    guard shouldExtract(decl) else { return false }
    let excludedNames = [
        // Skip auto-generated Encodable/encode
        "encode(to:)",
        // Skip auto-generated Hashable/hash
        "hash(into:)",
        // Skip auto-generated Equatable/==
        "==(_:_:)",
        // Skip auto-generated enum equals
        "__derived_enum_equals(_:_:)",
    ]
    if excludedNames.contains(decl.parent.printedName) { return false }
    return true
}
