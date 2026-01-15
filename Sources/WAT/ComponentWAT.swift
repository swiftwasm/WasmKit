import WasmParser

/// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
package struct ComponentWat {
    let functionsMap: NameMapping<ComponentWatParser.FunctionDecl>
    let valuesMap: NameMapping<ComponentWatParser.ValueDecl>
    let typesMap: NameMapping<ComponentWatParser.TypeDecl>
    let componentInstancesMap: NameMapping<ComponentWatParser.InstanceDecl>
    let componentsMap: NameMapping<ComponentWatParser.ComponentDef>
    let modulesMap: NameMapping<ComponentWatParser.ModuleDecl>
    let moduleInstancesMap: NameMapping<ComponentWatParser.ModuleInstanceDef>
}
