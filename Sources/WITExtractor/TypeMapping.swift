@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
struct TypeMapping {
    typealias DeclScope = [SwiftAPIDigester.SDKNodeDecl]
    struct DeclSource {
        let node: SwiftAPIDigester.SDKNodeDecl
        let scope: DeclScope

        var qualifiedName: String {
            let typeContext: String
            if !scope.isEmpty {
                typeContext = scope.map(\.parent.printedName).joined(separator: ".") + "."
            } else {
                typeContext = ""
            }
            return typeContext + node.parent.printedName
        }
    }

    private var usrToWITTypeName: [String: String] = [:]
    private var witTypeNameToDecl: [String: DeclSource] = [:]
    private var declScope: DeclScope = []

    func qualifiedName(byWITName witName: String) -> String? {
        guard let source = witTypeNameToDecl[witName] else { return nil }
        return source.qualifiedName
    }

    private static let knownMapping = buildKnownMapping()

    static func buildKnownMapping() -> [String: String] {
        var mapping: [String: String] = [:]

        // This assumes platforms where this extractor is running on and
        // where the input swiftmodule is built for has the same mangled
        // type name.
        func add(_ type: Any.Type, _ witType: String) {
            guard let mangledName = _mangledTypeName(type) else {
                fatalError("mangled name should be available at runtime")
            }
            let usr = "s:" + mangledName
            mapping[usr] = witType
        }

        add(Bool.self, "bool")

        add(UInt8.self, "u8")
        add(UInt16.self, "u16")
        add(UInt32.self, "u32")
        add(UInt64.self, "u64")
        add(UInt.self, "u64")

        add(Int8.self, "s8")
        add(Int16.self, "s16")
        add(Int32.self, "s32")
        add(Int64.self, "s64")
        add(Int.self, "s64")

        add(Float.self, "f32")
        add(Double.self, "f64")

        add(String.self, "string")

        return mapping
    }

    static func lookupKnownMapping(usr: String) -> String? {
        if let known = Self.knownMapping[usr] {
            return known
        }
        return nil
    }

    func lookupWITType(
        byNode node: SwiftAPIDigester.SDKNodeTypeNominal,
        diagnostics: DiagnosticCollection
    ) -> String? {
        if let usr = node.body.usr, let found = lookupWITType(byUsr: usr) {
            return found
        }

        func genericParameters() -> some Collection<String> {
            let children = node.parent.parent.children ?? []
            return children.lazy.compactMap { child in
                guard case let .typeNominal(typeNode) = child else {
                    diagnostics.add(.warning("Missing generic parameter type node for \(node.parent.parent.printedName)"))
                    return nil
                }
                guard let found = lookupWITType(byNode: typeNode, diagnostics: diagnostics) else {
                    diagnostics.add(.warning("Missing corresponding WIT type for generic parameter type \(typeNode.parent.parent.printedName)"))
                    return nil
                }
                return found
            }
        }

        switch node.parent.parent.name {
        case "Tuple":
            let elements = genericParameters()
            if elements.count == 1 {
                return elements.first
            }
            return "tuple<\(elements.joined(separator: ", "))>"
        case "Paren":
            return genericParameters().first
        default: break
        }

        // Lookup known generic types
        switch node.body.usr {
        case "s:Sq":  // "Optional"
            guard let wrapped = genericParameters().first else { return nil }
            return "option<\(wrapped)>"
        case "s:Sa":  // "Array"
            guard let element = genericParameters().first else { return nil }
            return "list<\(element)>"
        case "s:SD":  // "Dictionary"
            var genericParams = genericParameters().makeIterator()
            guard let key = genericParams.next(), let value = genericParams.next() else { return nil }
            // NOTE: There is no key-value map representation in WIT, so lower to tuple-list
            return "list<tuple<\(key), \(value)>>"
        default: break
        }

        return nil
    }

    func lookupWITType(byUsr usr: String) -> String? {
        if let known = Self.knownMapping[usr] {
            return known
        }
        return usrToWITTypeName[usr]
    }

    mutating func collect(digest: SwiftAPIDigester.Output) {
        collect(node: digest.ABIRoot)
    }

    private mutating func collect(node: SwiftAPIDigester.SDKNode) {
        var cleanup: (inout TypeMapping) -> Void = { _ in }
        defer { cleanup(&self) }

        if case let .typeDecl(typeDecl) = node {
            collect(node: typeDecl.parent)
            declScope.append(typeDecl.parent)
            cleanup = {
                _ = $0.declScope.popLast()
            }
        }

        for child in node.body.children ?? [] {
            collect(node: child)
        }
    }

    private mutating func collect(node: SwiftAPIDigester.SDKNodeDecl) {
        let scopeNames = declScope.map { $0.parent.name }
        let witTypeName = ConvertCase.witIdentifier(identifier: scopeNames + [node.parent.name])
        self.witTypeNameToDecl[witTypeName] = DeclSource(node: node, scope: declScope)
        self.usrToWITTypeName[node.body.usr] = witTypeName
    }
}
