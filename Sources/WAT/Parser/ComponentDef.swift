#if ComponentModel

    import ComponentModel
    import WasmParserCore
    import WasmTypes

    extension ComponentWatParser {
        struct ComponentDefField {
            let location: Location
            let kind: NormalizedDefinition
        }

        struct ValueDef: NamedFieldDecl {
            var id: Name?
        }

        struct ComponentInstanceDef: NamedFieldDecl {
            var id: Name?
            var componentRef: Parser.IndexOrId?
            var arguments: [ComponentInstanceArgument]
        }

        struct ComponentInstanceArgument {
            enum Kind {
                case instance(Parser.IndexOrId)
            }
            let name: String
            let kind: Kind
        }

        /// A core function definition created via canon lower.
        struct CoreFuncDef: NamedFieldDecl {
            var id: Name?
        }

        /// A core memory definition created via alias.
        struct CoreMemoryAliasDef: NamedFieldDecl {
            var id: Name?
        }

        /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
        public struct ComponentDef: NamedFieldDecl {
            var id: Name?

            // Listed in the order of section indices in binary encoding.
            var coreModulesMap: NameMapping<ModuleDef> = .init()
            var coreInstancesMap: NameMapping<CoreInstanceDef> = .init()
            var coreTypesMap: CoreTypesMap = .init()
            var coreFunctionsMap: NameMapping<CoreFuncDef> = .init()  // Core functions created by canon lower
            var coreMemoriesMap: NameMapping<CoreMemoryAliasDef> = .init()  // Core memories created by alias

            var componentFunctions: NameMapping<ComponentFuncDef> = .init()
            var valuesMap: NameMapping<ValueDef> = .init()
            var componentTypes: NameMapping<ComponentTypeDef> = .init()
            var componentInstancesMap: NameMapping<ComponentInstanceDef> = .init()
            var componentsMap: NameMapping<ComponentDef> = .init()

            /// As sections in CM binaries can stay disjoint and unmerged,
            /// we should preserve disjoint sections together with their ordering.
            var fields = [ComponentDefField]()

            /// Mapping from a component type to its unique ID in `componentTypes` name mapping storage.
            var typesMap = [ComponentTypeDef.Kind: Int]()
        }

        struct ModuleDef: NamedFieldDecl {
            var id: Name?
            var wat: Wat
        }

        struct CoreInstanceDef: NamedFieldDecl {
            struct Argument {
                enum Kind {
                    struct Export {
                        let name: String
                        let sort: CoreDefSort
                        let index: UInt32
                    }
                    case instance(Parser.IndexOrId)
                    case exports([Export])
                }

                let importName: String
                let kind: Kind
            }

            var id: Name?
            var moduleId: Parser.IndexOrId
            var arguments: [Argument]
        }

        struct CoreTypeDef: NamedFieldDecl {
            enum Kind {
                case function(WatParser.FunctionType)
                case module(CoreModuleTypeDef)
            }
            var id: Name?
            let kind: Kind
        }

        struct CoreModuleTypeDef {
            var declarations: [CoreModuleDecl]
            var localTypeBindings: [String: Int] = [:]

            func resolveTypeIndex(use: Parser.IndexOrId, globalResolver: CoreTypesMap) throws(WatParserError) -> Int {
                switch use {
                case .id(let id, _):
                    if let localDeclIndex = localTypeBindings[id.value] {
                        return localDeclIndex
                    }
                    return try globalResolver.resolveIndex(use: use)
                case .index:
                    return try globalResolver.resolveIndex(use: use)
                }
            }
        }

        enum CoreModuleDecl {
            case alias(CoreModuleAlias)
            case type(TypeIndex)
            case `import`(CoreModuleImport)
            case export(CoreModuleExport)
        }

        struct CoreModuleAlias {
            let sort: CoreDefSort
            let target: CoreModuleAliasTarget
            let bindingId: Name?
        }

        enum CoreModuleAliasTarget {
            case outer(componentId: Parser.IndexOrId, index: Parser.IndexOrId, resolvedIndex: Int, outerCount: Int)
        }

        enum CoreAliasSort: String {
            case `func`
            case table
            case memory
            case global
            case type
        }

        /// Component-level alias definition.
        /// Syntax: (alias core export $instance "name" (core <sort> $bindingId))
        ///         (alias export $instance "name" (<sort> $bindingId))
        ///         (alias outer $component $idx (<sort> $bindingId))
        ///
        /// This is separate from `ComponentModel.ComponentAlias` because the parser works with
        /// unresolved symbolic references (`Parser.IndexOrId`) while the binary representation
        /// uses resolved numeric indices (`UInt32`). The encoder resolves these during binary encoding.
        struct ComponentAlias {
            enum Target {
                case export(isCore: Bool, instanceIndex: Parser.IndexOrId, exportName: String)
                case outer(outerCount: Parser.IndexOrId, typeIndex: Parser.IndexOrId)
            }

            let sort: ComponentDefSort
            let target: Target
            let bindingId: Name?
        }

        struct CoreModuleImport {
            let moduleName: String
            let name: String
            let descriptor: CoreImportDesc
        }

        enum CoreImportDesc {
            case `func`(typeIndex: Parser.IndexOrId)
        }

        struct CoreModuleExport {
            let name: String
            let descriptor: CoreImportDesc
        }

        struct FuncIndex {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        /// Reference to a core memory via instance export.
        /// Used in canon options: (memory $instance "export")
        struct MemoryRef {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        /// Reference to a component function via instance export.
        /// Used in canon lower: (func $instance "export")
        struct ComponentFuncRef {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        struct CanonDef {
            enum Option {
                case stringEncoding(ComponentStringEncoding)
                case memory(MemoryRef)
                case realloc(FuncIndex)
                case postReturn(FuncIndex)
                case `async`
                case callback(FuncIndex)
            }

            enum Kind {
                case lower(ComponentFuncRef)
                case lift(FuncIndex)
            }
            let kind: Kind
            let functionIndex: FuncIndex
            let options: [Option]
        }

        enum ExternDesc {
            case module(Parser.IndexOrId)
            case function(ComponentFuncIndex)
            case functionFromInstance(Parser.IndexOrId, String)  // (instance, exportName)
            case value(Parser.IndexOrId)
            case type(Parser.IndexOrId)
            case component(Parser.IndexOrId)
            case instance(Parser.IndexOrId)
        }

        struct ExportDef {
            let exportName: String
            let descriptor: ExternDesc
        }

        struct ImportDef {
            let importModuleName: String
            let importName: String
            let descriptor: ExternDesc
        }

        struct ComponentFuncDef: NamedFieldDecl {
            var id: Name?
            let paramNames: [String]
            let type: ComponentTypeIndex
        }

        struct ComponentTypeDef: NamedFieldDecl {
            enum Kind: Hashable {
                case function(ComponentFuncType)
                case value(ComponentValueType)
                case instance(InstanceTypeDef)
                case component(ComponentInnerTypeDef)
            }
            var id: Name?
            let kind: Kind
        }

        struct InstanceTypeDef: Hashable {
            struct TypeDecl: Hashable {
                let id: Name?
                let valueType: ComponentValueType
            }
            struct ExportDecl: Hashable {
                let name: String
                // Simplified - full implementation would handle type equality constraints
            }
            let typeDecls: [TypeDecl]
            let exports: [ExportDecl]
        }

        struct ComponentInnerTypeDef: Hashable {
            struct TypeDecl: Hashable {
                let id: Name?
                let valueType: ComponentValueType
            }
            struct ImportDecl: Hashable {
                let name: String
            }
            struct ExportDecl: Hashable {
                let name: String
            }
            let typeDecls: [TypeDecl]
            let imports: [ImportDecl]
            let exports: [ExportDecl]
        }
    }

#endif
