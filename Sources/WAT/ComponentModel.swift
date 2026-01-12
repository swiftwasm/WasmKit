import WasmParser

/// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
package struct ComponentWat {
    let functionsMap: NameMapping<ComponentWatParser.FunctionDecl>
    let valuesMap: NameMapping<ComponentWatParser.ValueDecl>
    let typesMap: NameMapping<ComponentWatParser.TypeDecl>
    let componentTnstancesMap: NameMapping<ComponentWatParser.InstanceDecl>
    let componentsMap: NameMapping<ComponentWatParser.ComponentDecl>
    let modulesMap: NameMapping<ComponentWatParser.ModuleDecl>
    let moduleInstancesMap: NameMapping<ComponentWatParser.ModuleInstanceDecl>
}

struct ComponentWatParser {
    var parser: Parser
    let features: WasmFeatureSet

    struct Field {
        enum Kind: Equatable {
            case component(Name?)
        }
        let location: Location
        let kind: Kind
    }

    init(_ input: String, features: WasmFeatureSet) {
        self.parser = Parser(input)
        self.features = features
    }

    mutating func next() throws -> Field? {
        // If we have reached the end of the (component ...) block, return nil
        guard try !parser.isEndOfParen() else { return nil }
        try parser.expect(.leftParen)
        let location = parser.lexer.location()
        let keyword = try parser.expectKeyword()

        let field: Field
        switch keyword {
        case "component":
            let id = try parser.takeId()
            try parser.expect(.rightParen)
            field = .init(location: location, kind: .component(id))
        default:
            fatalError()
        }

        return field
    }
}

extension ComponentWatParser {
    struct FunctionDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ValueDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct TypeDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct InstanceDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ComponentDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ModuleDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ModuleInstanceDecl: NamedModuleFieldDecl {
        var id: Name?
    }
}
