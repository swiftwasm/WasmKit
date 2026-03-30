#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    extension ComponentWatParser {
        /// A definition in normalized order, ready for binary encoding.
        /// Each case maps to a component binary section and carries
        /// the full definition, not just an index.
        enum NormalizedDefinition {
            case coreModule(ModuleDef)
            case coreInstance(CoreInstanceDef)
            case coreType(CoreTypeDef)
            case component(ComponentDef)
            case instance(ComponentInstanceDef)
            case componentType(ComponentTypeDef, typeIndex: Int)
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
            case .coreModule(let def): return "coreModule(\(def.id?.value ?? "(unnamed)"))"
            case .coreInstance(let def): return "coreInstance(\(def.id?.value ?? "(unnamed)"))"
            case .coreType(let def): return "coreType(\(def.id?.value ?? "(unnamed)"))"
            case .component(let def): return "component(\(def.id?.value ?? "(unnamed)"))"
            case .instance(let def): return "instance(\(def.id?.value ?? "(unnamed)"))"
            case .componentType(let def, _): return "componentType(\(def.id?.value ?? "(unnamed)"))"
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
