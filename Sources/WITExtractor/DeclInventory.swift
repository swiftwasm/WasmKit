import SwiftSyntax

/// Member types are carried as unresolved `TypeSyntax`; resolution happens later.
struct DeclInventory {
    var types: [TypeEntry] = []
    var functions: [FunctionEntry] = []
}

struct TypeEntry {
    enum Kind { case structType, enumType }
    var kind: Kind
    /// Enclosing type names, outermost first; empty at top level.
    var scopePath: [String]
    /// Leaf Swift name.
    var name: String
    /// Public stored instance fields, for structs.
    var fields: [FieldEntry]
    /// For enums; never empty.
    var cases: [CaseEntry]
    /// Bare for a main-module type (`NamespaceEnum.NestedStruct`), `Module.`-prefixed for an inlined
    /// dependency type (`ExternalLib.External`).
    var swiftQualifiedName: String

    var qualifiedName: String { (scopePath + [name]).joined(separator: ".") }

    /// Every site keying or emitting this type must use this one derivation so the WIT, the source-summary
    /// index, and the name table stay in lockstep.
    var witName: String { ConvertCase.witIdentifier(identifier: scopePath + [name]) }
}

struct FieldEntry {
    /// Bare (unescaped) Swift name.
    var name: String
    var type: TypeSyntax
}

struct CaseEntry {
    var name: String
    var payload: [TypeSyntax]
}

struct FunctionEntry {
    struct Parameter {
        /// External argument label, or nil when unlabeled (`_`).
        var externalLabel: String?
        /// Internal parameter name, or nil when anonymous (`_:`).
        var internalName: String?
        var type: TypeSyntax
    }

    /// Leaf Swift base name; top-level only.
    var name: String
    var parameters: [Parameter]
    var returnClause: ReturnClauseSyntax?

    /// Derived identically to `TypeEntry.witName`: a function and a type sharing a WIT name collide in the
    /// same namespace (see `resolvingInterfaceNameCollisions`).
    var witName: String { ConvertCase.witIdentifier(identifier: name) }
}

extension DeclInventory {
    /// A WIT interface shares one namespace across types and functions (wasm-tools rejects a name defined
    /// twice), and `ConvertCase.kebabCase` is not injective, so distinct Swift decls can collapse onto one
    /// WIT name. Keep the first at each WIT name in emission order (all types, then all functions; source
    /// order within each, matching `ModuleTranslation.translate`), dropping later ones with a diagnostic.
    /// Member-level names (record fields, enum cases, params) are not de-collided.
    func resolvingInterfaceNameCollisions(diagnostics: DiagnosticCollection) -> DeclInventory {
        var keptBy: [String: String] = [:]  // WIT name -> kept declaration's Swift name
        var keptTypes: [TypeEntry] = []
        var keptFunctions: [FunctionEntry] = []
        for type in types {
            if let keeping = keptBy[type.witName] {
                diagnostics.add(
                    .nameCollision(dropped: type.qualifiedName, witName: type.witName, keeping: keeping))
            } else {
                keptBy[type.witName] = type.qualifiedName
                keptTypes.append(type)
            }
        }
        for function in functions {
            if let keeping = keptBy[function.witName] {
                diagnostics.add(
                    .nameCollision(dropped: function.name, witName: function.witName, keeping: keeping))
            } else {
                keptBy[function.witName] = function.name
                keptFunctions.append(function)
            }
        }
        return DeclInventory(types: keptTypes, functions: keptFunctions)
    }
}
