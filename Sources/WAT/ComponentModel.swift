struct WatComponentParser {
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

/// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
package struct WatComponent {
    let functionsMap: NameMapping<WatComponentParser.FunctionDecl>
    let valuesMap: NameMapping<WatComponentParser.ValueDecl>
    let typesMap: NameMapping<WatComponentParser.TypeDecl>
    let componentTnstancesMap: NameMapping<WatComponentParser.InstanceDecl>
    let componentsMap: NameMapping<WatComponentParser.ComponentDecl>
    let modulesMap: NameMapping<WatComponentParser.ModuleDecl>
    let moduleInstancesMap: NameMapping<WatComponentParser.ModuleInstanceDecl>
}
