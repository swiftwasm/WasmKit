import SwiftSyntax

/// Inlines the dependency types a `DeclInventory`'s `@WIT` decls reference. WIT records/variants/enums
/// are value types, so a dependency type is materialized as its own top-level WIT type. Same-module
/// unmarked types are not inlined.
struct InlineClosure {
    let resolver: TypeResolver
    let mainModule: String
    let diagnostics: DiagnosticCollection

    func widen(_ inventory: DeclInventory) -> DeclInventory {
        var result = inventory
        // Seeded with main-module types so a `@WIT` type is never re-inlined.
        var seen: Set<[String]> = Set(inventory.types.map { [mainModule] + $0.scopePath + [$0.name] })
        var queue: [TypeResolver.ReferencedNominal] = []

        func enqueue(_ types: [TypeSyntax], inScope scope: [String]) {
            for type in types {
                for ref in resolver.referencedNominals(in: type, inScope: scope) {
                    guard ref.module != mainModule else { continue }
                    let key = [ref.module] + ref.qualifiedName
                    guard !seen.contains(key) else { continue }
                    seen.insert(key)
                    queue.append(ref)
                }
            }
        }

        for type in result.types {
            let scope = type.scopePath + [type.name]
            enqueue(type.fields.map(\.type), inScope: scope)
            for caseEntry in type.cases { enqueue(caseEntry.payload, inScope: scope) }
        }
        for function in result.functions {
            enqueue(function.parameters.map(\.type), inScope: [])
            if let returnType = function.returnClause?.type { enqueue([returnType], inScope: []) }
        }

        var index = 0
        while index < queue.count {
            let ref = queue[index]
            index += 1
            let leaf = ref.qualifiedName.last ?? ""
            let qualified = ([ref.module] + ref.qualifiedName).joined(separator: ".")
            let (fields, cases) = WITDeclCollector.members(of: ref.node, owner: qualified, into: diagnostics)
            // A non-public dependency type is not nameable across modules.
            guard ref.node.isPublic else {
                diagnostics.add(
                    .skipInlinedType(
                        name: qualified, reason: "it is not public and cannot be referenced from the generated overlay"))
                continue
            }
            let kind: TypeEntry.Kind
            switch ref.node {
            case .structDecl(let structDecl):
                guard memberwiseConstructibleAcrossModules(structDecl, recordFields: fields) else {
                    diagnostics.add(
                        .skipInlinedType(
                            name: qualified,
                            reason:
                                "its memberwise initializer is not public; add a public initializer matching its stored properties so the generated overlay can construct it across modules"))
                    continue
                }
                kind = .structType
            case .enumDecl:
                guard !cases.isEmpty else {
                    diagnostics.add(
                        .skipInlinedType(name: qualified, reason: "empty enum has no WIT representation"))
                    continue
                }
                kind = .enumType
            }
            result.types.append(
                TypeEntry(
                    kind: kind, scopePath: Array(ref.qualifiedName.dropLast()), name: leaf,
                    fields: fields, cases: cases, swiftQualifiedName: qualified))
            enqueue(fields.map(\.type), inScope: ref.qualifiedName)
            for caseEntry in cases { enqueue(caseEntry.payload, inScope: ref.qualifiedName) }
        }
        return result
    }
}

/// Whether the overlay can construct `structDecl` via the memberwise-shaped call `Type(f0: v0, ...)` that
/// `liftRecord` emits in record-field order. The implicit memberwise init is `internal`, so a cross-module
/// struct needs an explicit public/open, non-failable, non-effectful init whose argument labels equal the
/// record's field labels in order; any other shape is treated as non-matching.
private func memberwiseConstructibleAcrossModules(
    _ structDecl: StructDeclSyntax, recordFields: [FieldEntry]
) -> Bool {
    let fieldLabels = recordFields.map(\.name)
    for member in structDecl.memberBlock.members {
        guard let initializer = member.decl.as(InitializerDeclSyntax.self),
            initializer.modifiers.isPublic,
            initializer.optionalMark == nil,
            initializer.signature.effectSpecifiers == nil
        else { continue }
        let labels = initializer.signature.parameterClause.parameters.map { $0.firstName.text }
        if labels == fieldLabels { return true }
    }
    return false
}
