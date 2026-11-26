#if ComponentModel

    import ComponentModel

    // MARK: - NormalizedDefinition

    /// A normalized definition in the component, ready for linear encoding.
    /// Definitions are stored in the order they should appear in the binary,
    /// with dependencies (like inline types) already desugared and placed before their users.
    enum NormalizedDefinition {
        case coreModule(ComponentWatParser.ModuleDef)
        case coreInstance(ComponentWatParser.CoreInstanceDef)
        case coreType(ComponentWatParser.CoreTypeDef)
        /// Component type definition with its type index
        case componentType(ComponentWatParser.ComponentTypeDef, typeIndex: Int)
        case nestedComponent(ComponentWatParser.ComponentDef)
        case componentInstance(ComponentWatParser.ComponentInstanceDef)
        case alias(ComponentWatParser.ComponentAlias)
        case canon(ComponentWatParser.CanonDef)
        case componentStart(ComponentWatParser.StartDef)
        case componentImport(ComponentWatParser.ImportDef)
        case componentExport(ComponentWatParser.ExportDef)

        /// The section kind this definition belongs to.
        /// Used for automatic batching during encoding.
        var sectionKind: ComponentSectionID {
            switch self {
            case .coreModule: return .coreModule
            case .coreInstance: return .coreInstance
            case .coreType: return .coreType
            case .componentType: return .type
            case .nestedComponent: return .component
            case .componentInstance: return .instance
            case .alias: return .alias
            case .canon: return .canon
            case .componentStart: return .start
            case .componentImport: return .import
            case .componentExport: return .export
            }
        }

        /// The name of this definition, if it has one.
        /// Used for generating the name section.
        var name: String? {
            switch self {
            case .coreModule(let def): return def.id?.value
            case .coreInstance(let def): return def.id?.value
            case .coreType(let def): return def.id?.value
            case .componentType(let def, _): return def.id?.value
            case .nestedComponent(let def): return def.id?.value
            case .componentInstance(let def): return def.id?.value
            case .alias(let def): return def.bindingId?.value
            case .canon: return nil  // Canon defs don't have names at component level
            case .componentStart: return nil
            case .componentImport: return nil  // Import names are in the import itself
            case .componentExport: return nil  // Export names are in the export itself
            }
        }
    }

    extension NormalizedDefinition: CustomStringConvertible {
        var description: String {
            switch self {
            case .coreModule(let moduleDef):
                return "coreModule(\(moduleDef.id?.value ?? "(anon)"))"
            case .coreInstance(let instanceDef):
                return "coreInstance(\(instanceDef.id?.value ?? "(anon)"))"
            case .coreType(let typeDef):
                return "coreType(\(typeDef.id?.value ?? "(anon)"))"
            case .componentType(let typeDef, _):
                return "componentType(\(typeDef.id?.value ?? "(anon)"))"
            case .nestedComponent(let componentDef):
                return "component(\(componentDef.id?.value ?? "(anon)"))"
            case .componentInstance(let instanceDef):
                return "instance(\(instanceDef.id?.value ?? "(anon)"))"
            case .alias(let alias):
                let targetStr: String
                switch alias.target {
                case .coreExport(let instanceIndex, let exportName):
                    targetStr = "core export \(instanceIndex) \"\(exportName)\""
                case .componentExport(let instanceIndex, let exportName):
                    targetStr = "export \(instanceIndex) \"\(exportName)\""
                case .outer(let outerCount, let targetIndex):
                    targetStr = "outer \(outerCount) \(targetIndex)"
                }
                return "alias \(alias.sort.text) \(targetStr)"
            case .canon(let canonDef):
                switch canonDef.kind {
                case .lift: return "canon lift"
                case .lower: return "canon lower"
                case .resourceNew: return "canon resource.new"
                case .resourceDrop: return "canon resource.drop"
                case .resourceRep: return "canon resource.rep"
                }
            case .componentStart:
                return "start"
            case .componentImport(let importDef):
                return "import \"\(importDef.importName.string)\""
            case .componentExport(let exportDef):
                return "export \"\(exportDef.exportName.string)\""
            }
        }
    }

#endif
