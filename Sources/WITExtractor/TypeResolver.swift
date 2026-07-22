import SwiftSyntax

/// An unresolved type returns nil (drop the declaration), never a fabricated bare name.
struct TypeResolver {
    let symbolTable: WITSymbolTable

    /// When non-nil, a user nominal resolves only if its qualified name is in this set, so a reference to a
    /// dropped type resolves to nil rather than a dangling WIT name. nil disables the gate.
    var emittedNominals: Set<WITSymbolTable.QualifiedName>? = nil

    /// Consulted after the symbol table, so a same-module user type shadowing a primitive name wins.
    /// `Int`/`UInt` map to the 64-bit WIT types (WIT has no word-size-relative integer).
    private static let knownTypes: [String: String] = [
        "Bool": "bool",
        "UInt8": "u8", "UInt16": "u16", "UInt32": "u32", "UInt64": "u64", "UInt": "u64",
        "Int8": "s8", "Int16": "s16", "Int32": "s32", "Int64": "s64", "Int": "s64",
        "Float": "f32", "Double": "f64",
        "String": "string",
    ]

    /// `scope` is the qualified name of the enclosing type, empty at top level.
    func resolve(_ type: TypeSyntax, inScope scope: [String]) -> String? {
        resolve(type, inScope: scope, expandingAliases: [])
    }

    private func resolve(
        _ type: TypeSyntax, inScope scope: [String], expandingAliases: Set<[String]>
    ) -> String? {
        // Structural sugar, matched by syntax kind so it cannot be shadowed.
        if let optional = type.as(OptionalTypeSyntax.self) {
            return resolve(optional.wrappedType, inScope: scope, expandingAliases: expandingAliases)
                .map { "option<\($0)>" }
        }
        if let array = type.as(ArrayTypeSyntax.self) {
            return resolve(array.element, inScope: scope, expandingAliases: expandingAliases)
                .map { "list<\($0)>" }
        }
        if let dictionary = type.as(DictionaryTypeSyntax.self) {
            guard
                let key = resolve(dictionary.key, inScope: scope, expandingAliases: expandingAliases),
                let value = resolve(dictionary.value, inScope: scope, expandingAliases: expandingAliases)
            else { return nil }
            return "list<tuple<\(key), \(value)>>"
        }
        if let tuple = type.as(TupleTypeSyntax.self) {
            return resolveTuple(tuple.elements.map(\.type), inScope: scope, expandingAliases: expandingAliases)
        }

        guard let (namePath, genericArguments) = nameAndGenericArguments(of: type) else { return nil }

        // Same-module nominal/typealias, consulted before the generic-sugar spellings and the primitive
        // map, so a same-module type named `Array`/`Optional`/`Int` shadows the built-in.
        if let resolved = symbolTable.resolve(namePath, inScope: scope) {
            switch resolved.entry {
            case .nominal:
                if let emitted = emittedNominals, !emitted.contains(resolved.qualifiedName) { return nil }
                return ConvertCase.witIdentifier(identifier: resolved.qualifiedName)
            case .typeAlias(let rhs):
                guard !expandingAliases.contains(resolved.qualifiedName) else { return nil }  // cycle: drop
                // The alias RHS resolves in the alias's own enclosing scope, not the reference's.
                let aliasScope = Array(resolved.qualifiedName.dropLast())
                return resolve(
                    rhs, inScope: aliasScope,
                    expandingAliases: expandingAliases.union([resolved.qualifiedName]))
            }
        }

        if let sugar = resolveGenericSugar(
            namePath, genericArguments, inScope: scope, expandingAliases: expandingAliases)
        {
            return sugar
        }

        return knownType(for: namePath)
    }

    private func resolveAll(
        _ types: [TypeSyntax], inScope scope: [String], expandingAliases: Set<[String]>
    ) -> [String]? {
        var resolved: [String] = []
        for type in types {
            guard let element = resolve(type, inScope: scope, expandingAliases: expandingAliases) else {
                return nil
            }
            resolved.append(element)
        }
        return resolved
    }

    private func resolveTuple(
        _ types: [TypeSyntax], inScope scope: [String], expandingAliases: Set<[String]>
    ) -> String? {
        guard !types.isEmpty else { return nil }
        guard let resolved = resolveAll(types, inScope: scope, expandingAliases: expandingAliases) else {
            return nil
        }
        if resolved.count == 1 { return resolved[0] }
        return "tuple<\(resolved.joined(separator: ", "))>"
    }

    private func resolveGenericSugar(
        _ namePath: [String], _ arguments: [TypeSyntax], inScope scope: [String],
        expandingAliases: Set<[String]>
    ) -> String? {
        guard let leaf = namePath.last, !arguments.isEmpty else { return nil }
        guard namePath.count == 1 || (namePath.count == 2 && namePath.first == "Swift") else { return nil }
        func element(_ index: Int) -> String? {
            resolve(arguments[index], inScope: scope, expandingAliases: expandingAliases)
        }
        switch leaf {
        case "Optional":
            guard arguments.count == 1, let wrapped = element(0) else { return nil }
            return "option<\(wrapped)>"
        case "Array":
            guard arguments.count == 1, let inner = element(0) else { return nil }
            return "list<\(inner)>"
        case "Dictionary":
            guard arguments.count == 2, let key = element(0), let value = element(1) else { return nil }
            return "list<tuple<\(key), \(value)>>"
        default:
            return nil
        }
    }

    private func knownType(for namePath: [String]) -> String? {
        if namePath.count == 1 { return Self.knownTypes[namePath[0]] }
        if namePath.count == 2, namePath[0] == "Swift" { return Self.knownTypes[namePath[1]] }
        return nil
    }

    // Uses `.text` symmetrically with `WITSymbolTableBuilder` (which keys on `node.name.text`); unescaping
    // here alone would desync the lookup. Generic arguments on a member-type base (`Outer<Int>.Inner`) are
    // dropped: the base resolves by name only.
    private func nameAndGenericArguments(of type: TypeSyntax) -> (path: [String], arguments: [TypeSyntax])? {
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            guard let arguments = genericArguments(identifier.genericArgumentClause) else { return nil }
            return ([identifier.name.text], arguments)
        }
        if let member = type.as(MemberTypeSyntax.self) {
            guard let basePath = nameAndGenericArguments(of: member.baseType)?.path else { return nil }
            guard let arguments = genericArguments(member.genericArgumentClause) else { return nil }
            return (basePath + [member.name.text], arguments)
        }
        return nil
    }

    // Any `.expr` arg (a value generic) yields nil for the whole clause.
    private func genericArguments(_ clause: GenericArgumentClauseSyntax?) -> [TypeSyntax]? {
        guard let clause else { return [] }
        var types: [TypeSyntax] = []
        for argument in clause.arguments {
            guard case .type(let type) = argument.argument else { return nil }
            types.append(type)
        }
        return types
    }

    /// A payload is one WIT type (unlike a function's result list), so multiple parameters lower to a
    /// single `tuple<...>`.
    func resolvePayload(_ payload: [TypeSyntax], inScope scope: [String]) -> String? {
        guard !payload.isEmpty else { return nil }
        return resolveTuple(payload, inScope: scope, expandingAliases: [])
    }

    func resolveParameters(_ parameters: [TypeSyntax], inScope scope: [String]) -> [String]? {
        resolveAll(parameters, inScope: scope, expandingAliases: [])
    }

    /// No result (absent clause, `-> ()`, `-> Void`, `-> Swift.Void`) is the empty list. WIT permits at
    /// most one result (`result-list ::= (empty) | '-> ' ty`), so a multi-element tuple return lowers to a
    /// single `tuple<...>` element, not one per member.
    func resolveResults(_ returnClause: ReturnClauseSyntax?, inScope scope: [String]) -> [String]? {
        guard let returnClause else { return [] }
        let returnType = returnClause.type
        if isVoid(returnType) { return [] }
        if let tuple = returnType.as(TupleTypeSyntax.self) {
            guard let lowered = resolveTuple(tuple.elements.map(\.type), inScope: scope, expandingAliases: []) else {
                return nil
            }
            return [lowered]
        }
        guard let single = resolve(returnType, inScope: scope) else { return nil }
        return [single]
    }

    private func isVoid(_ type: TypeSyntax) -> Bool {
        if let tuple = type.as(TupleTypeSyntax.self) { return tuple.elements.isEmpty }
        guard let (path, arguments) = nameAndGenericArguments(of: type), arguments.isEmpty else { return false }
        return path == ["Void"] || path == ["Swift", "Void"]
    }
}

extension TypeResolver {
    struct ReferencedNominal {
        let qualifiedName: WITSymbolTable.QualifiedName
        let module: String
        let node: WITSymbolTable.NominalNode
    }

    /// Every same-table nominal `type` structurally references. Ungated: walks the table directly, not via
    /// `resolve`. Stops at a nominal, not descending into a user generic nominal's arguments, mirroring the
    /// resolver's generic-sugar asymmetry (`Box<External>` references only `Box`).
    func referencedNominals(in type: TypeSyntax, inScope scope: [String]) -> [ReferencedNominal] {
        var found: [ReferencedNominal] = []
        collectReferencedNominals(in: type, inScope: scope, expandingAliases: [], into: &found)
        return found
    }

    private func collectReferencedNominals(
        in type: TypeSyntax, inScope scope: [String], expandingAliases: Set<[String]>,
        into found: inout [ReferencedNominal]
    ) {
        if let optional = type.as(OptionalTypeSyntax.self) {
            collectReferencedNominals(
                in: optional.wrappedType, inScope: scope, expandingAliases: expandingAliases, into: &found)
            return
        }
        if let array = type.as(ArrayTypeSyntax.self) {
            collectReferencedNominals(
                in: array.element, inScope: scope, expandingAliases: expandingAliases, into: &found)
            return
        }
        if let dictionary = type.as(DictionaryTypeSyntax.self) {
            collectReferencedNominals(
                in: dictionary.key, inScope: scope, expandingAliases: expandingAliases, into: &found)
            collectReferencedNominals(
                in: dictionary.value, inScope: scope, expandingAliases: expandingAliases, into: &found)
            return
        }
        if let tuple = type.as(TupleTypeSyntax.self) {
            for element in tuple.elements {
                collectReferencedNominals(
                    in: element.type, inScope: scope, expandingAliases: expandingAliases, into: &found)
            }
            return
        }

        guard let (namePath, genericArguments) = nameAndGenericArguments(of: type) else { return }

        if let resolved = symbolTable.resolve(namePath, inScope: scope) {
            switch resolved.entry {
            case .nominal(let module, let node):
                found.append(
                    ReferencedNominal(qualifiedName: resolved.qualifiedName, module: module, node: node))
            case .typeAlias(let rhs):
                guard !expandingAliases.contains(resolved.qualifiedName) else { return }  // cycle: stop
                let aliasScope = Array(resolved.qualifiedName.dropLast())
                collectReferencedNominals(
                    in: rhs, inScope: aliasScope,
                    expandingAliases: expandingAliases.union([resolved.qualifiedName]), into: &found)
            }
            return
        }

        guard let leaf = namePath.last, !genericArguments.isEmpty,
            namePath.count == 1 || (namePath.count == 2 && namePath.first == "Swift")
        else { return }
        switch leaf {
        case "Optional", "Array":
            guard genericArguments.count == 1 else { return }
            collectReferencedNominals(
                in: genericArguments[0], inScope: scope, expandingAliases: expandingAliases, into: &found)
        case "Dictionary":
            guard genericArguments.count == 2 else { return }
            collectReferencedNominals(
                in: genericArguments[0], inScope: scope, expandingAliases: expandingAliases, into: &found)
            collectReferencedNominals(
                in: genericArguments[1], inScope: scope, expandingAliases: expandingAliases, into: &found)
        default:
            return
        }
    }
}
