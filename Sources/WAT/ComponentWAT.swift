import WasmParser

/// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
package struct ComponentWat {
    let functionsMap: NameMapping<ComponentWatParser.FunctionDef>
    let valuesMap: NameMapping<ComponentWatParser.ValueDef>
    let typesMap: NameMapping<ComponentWatParser.TypeDef>
    let componentInstancesMap: NameMapping<ComponentWatParser.InstanceDecl>
    let componentsMap: NameMapping<ComponentWatParser.ComponentDef>
    let modulesMap: NameMapping<ComponentWatParser.ModuleDef>
    let moduleInstancesMap: NameMapping<ComponentWatParser.ModuleInstanceDef>
}
