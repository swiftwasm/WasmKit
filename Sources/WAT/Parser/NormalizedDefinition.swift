#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    extension ComponentWatParser {
        /// A definition in normalized order, ready for binary encoding.
        /// Each case maps to a component binary section.
        enum NormalizedDefinition {
            case coreModule(CoreModuleIndex)
            case coreInstance(CoreInstanceIndex)
            case coreType(TypeIndex)
            case component(ComponentIndex)
            case instance(ComponentInstanceIndex)
            case componentType(ComponentTypeIndex)
            case canon(CanonDef)
            case componentExport(ExportDef)
            case componentImport(ImportDef)
            case alias(ComponentAlias)

            /// The section ID this definition belongs to.
            var sectionKind: ComponentSectionID {
                switch self {
                case .coreModule: return .coreModule
                case .coreInstance: return .coreInstance
                case .coreType: return .coreType
                case .componentType: return .type
                case .component: return .component
                case .instance: return .instance
                case .alias: return .alias
                case .canon: return .canon
                case .componentImport: return .import
                case .componentExport: return .export
                }
            }
        }
    }

    extension ComponentWatParser.NormalizedDefinition: CustomStringConvertible {
        var description: String {
            switch self {
            case .coreModule(let idx): return "coreModule(\(idx))"
            case .coreInstance(let idx): return "coreInstance(\(idx))"
            case .coreType(let idx): return "coreType(\(idx))"
            case .component(let idx): return "component(\(idx))"
            case .instance(let idx): return "instance(\(idx))"
            case .componentType(let idx): return "componentType(\(idx))"
            case .canon(let def):
                switch def.kind {
                case .lift: return "canon lift"
                case .lower: return "canon lower"
                }
            case .componentExport(let def): return "export \"\(def.exportName)\""
            case .componentImport(let def): return "import \"\(def.importModuleName)\""
            case .alias(let alias):
                let sortStr: String
                switch alias.sort {
                case .core(let coreSort): sortStr = "core \(coreSort.rawValue)"
                case .func: sortStr = "func"
                case .value: sortStr = "value"
                case .type: sortStr = "type"
                case .component: sortStr = "component"
                case .instance: sortStr = "instance"
                }
                let targetStr: String
                switch alias.target {
                case .export(let isCore, let instanceIndex, let exportName):
                    targetStr = "\(isCore ? "core " : "")export \(instanceIndex) \"\(exportName)\""
                case .outer(let outerCount, let typeIndex):
                    targetStr = "outer \(outerCount) \(typeIndex)"
                }
                return "alias \(sortStr) \(targetStr)"
            }
        }
    }

#endif
