#if ComponentModel

    import BasicContainers
    import WasmParser
    import WasmTypes

    struct ComponentIndex: RawRepresentable {
        let rawValue: Int
    }

    /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
    package struct ComponentWat: ~Copyable {
        // Listed in the order of section indices in binary encoding§
        var coreModulesMap: NameMapping<ComponentWatParser.ModuleDef> = .init()
        var coreInstancesMap: NameMapping<ComponentWatParser.CoreInstanceDef> = .init()
        var coreTypesMap: NameMapping<FunctionType> = .init()

        var componentFunctions: NameMapping<ComponentWatParser.ComponentFuncDef> = .init()
        var valuesMap: NameMapping<ComponentWatParser.ValueDef> = .init()
        var componentTypes: NameMapping<ComponentWatParser.ComponentTypeDef> = .init()
        var componentInstancesMap: NameMapping<ComponentWatParser.ComponentInstanceDef> = .init()
        var componentsMap: NameMapping<ComponentWatParser.ComponentDef> = .init()

        var aliases = Aliases()
        var canon = UniqueArray<ComponentWatParser.CanonDef>()

        /// As sections in CM binaries can stay disjoint and unmerged, for compatibility with other tools, we should preserve disjoint sections together with their ordering.
        var fields = UniqueArray<ComponentWatParser.Field>()

        struct Aliases: ~Copyable {
            init() {}
        }

    }

#endif
