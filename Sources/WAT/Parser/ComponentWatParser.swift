#if ComponentModel

    import BasicContainers
    import ComponentModel
    import WasmParser
    import WasmTypes

    struct ComponentWatParser: ~Copyable {
        /// Underlying WAT parser to delegate to.
        var parser: Parser

        let features: WasmFeatureSet

        struct Field {
            enum Kind {
                case component(Int)
            }
        }

        init(_ input: String, features: WasmFeatureSet) {
            self.parser = Parser(input)
            self.features = features
        }

        /// Parses a single top-level definition and updates in-progress parsing result stored in `self.wat`.
        /// - Returns: `true` if no more tokens to parse.
        mutating func next(parsedComponent: inout ComponentDef) throws(WatParserError) -> Bool {
            // If we have reached the end of the (component ...) block, return nil
            guard try !parser.isEndOfParen() else { return false }
            try parser.expect(.leftParen)
            let location = parser.lexer.location()
            let keyword = try parser.expectKeyword()

            let field: Field
            switch keyword {
            case "component":
                let id = try parser.takeId()
                var newComponent = ComponentDef(id: id)

                while try parser.take(.leftParen) {
                    let componentDefKeyword = try parser.expectKeyword()
                    switch componentDefKeyword {
                    case "core":
                        let coreKeyword = try parser.expectKeyword()
                        let location = parser.lexer.location()
                        switch coreKeyword {
                        case "module":
                            newComponent.fields.append(
                                .init(
                                    location: location,
                                    kind: .coreModule(try self.parseModuleDef())
                                )
                            )

                        case "instance":
                            newComponent.fields.append(
                                .init(
                                    location: location,
                                    kind: .coreInstance(try self.parseCoreInstanceDef())
                                )
                            )

                        default:
                            throw WatParserError(
                                "Unknown core definition keyword \(coreKeyword)",
                                location: location
                            )
                        }
                    case "func":
                        try parseComponentFunction(&parsedComponent)
                    default:
                        throw WatParserError(
                            "Unknown component definition keyword \(componentDefKeyword)",
                            location: location
                        )
                    }
                    try parser.expect(.rightParen)
                }
                let componentIndex = try parsedComponent.componentsMap.add(newComponent)
                parsedComponent.fields.append(.init(location: location, kind: .component(.init(rawValue: componentIndex))))
            default:
                fatalError()
            }

            // Check if the parser has reached the end of the function body
            guard try parser.isEndOfParen() else {
                throw WatParserError("unexpected token", location: parser.lexer.location())
            }

            return false
        }

        private mutating func parseModuleDef() throws(WatParserError) -> ModuleDef {
            let moduleID = try parser.takeId()
            let wat = try parseWAT(&parser, features: features)
            return .init(id: moduleID, wat: wat)
        }

        private mutating func parseModuleInstanceArguments() throws(WatParserError) -> CoreInstanceDef.Argument {
            try parser.expectKeyword("with")
            let importName = try parser.expectString()
            try parser.expect(.leftParen)

            let result: CoreInstanceDef.Argument.Kind
            if try parser.takeKeyword("instance") {
                let instanceID = try parser.expectIndexOrId()
                result = .instance(instanceID)
            } else {
                throw WatParserError("Core instance inline exports not supported yet", location: parser.lexer.location())
            }
            try parser.expect(.rightParen)
            return .init(importName: importName, kind: result)
        }

        private mutating func parseCoreDefSort() throws(WatParserError) -> CoreDefSort {
            let rawKeyword = try parser.expectKeyword()
            guard let keyword = CoreDefSort(rawValue: rawKeyword) else {
                throw WatParserError(
                    "Unexpected core declaration sort `\(rawKeyword)",
                    location: parser.lexer.location()
                )
            }

            return keyword
        }

        private mutating func parseComponentDefSort() throws(WatParserError) -> ComponentDefSort {
            let rawKeyword = try parser.expectKeyword()
            switch rawKeyword {
            case "core":
                return .core(try parseCoreDefSort())

            case "func": return .func
            case "value": return .value
            case "type": return .type
            case "component": return .component
            case "instance": return .instance

            default:
                throw WatParserError(
                    "Unexpected component declaration sort `\(rawKeyword)",
                    location: parser.lexer.location()
                )
            }
        }

        private mutating func parseCoreInstanceDef() throws(WatParserError) -> CoreInstanceDef {
            let instanceId = try parser.takeId()
            try parser.expect(.leftParen)

            try parser.expectKeyword("instantiate")
            let instantiatedModuleId = try parser.expectIndexOrId()
            var instantiateArguments = [CoreInstanceDef.Argument]()

            while try parser.take(.leftParen) {
                instantiateArguments.append(try self.parseModuleInstanceArguments())
                try parser.expect(.rightParen)
            }

            try parser.expect(.rightParen)

            return CoreInstanceDef(
                id: instanceId,
                moduleId: instantiatedModuleId,
                arguments: instantiateArguments
            )
        }

        private mutating func parseComponentType() throws(WatParserError) -> ComponentType {
            let primitiveTypeKeyword = try parser.peekKeyword()

            if let primitiveTypeKeyword {
                switch primitiveTypeKeyword {
                case "bool": return .bool
                case "u8": return .u8
                case "u16": return .u16
                case "u32": return .u32
                case "u64": return .u64
                case "s8": return .s8
                case "s16": return .s16
                case "s32": return .s32
                case "s64": return .s64
                case "float32": return .float32
                case "float64": return .float64
                case "char": return .char
                case "string": return .string
                case "error-context": return .errorContext
                default:
                    throw WatParserError(
                        "Unexpected primitive component type keyword `\(primitiveTypeKeyword)",
                        location: parser.lexer.location()
                    )
                }
            } else {
                try parser.expect(.leftParen)
                let compositeTypeKeyword = try parser.expectKeyword()
                switch compositeTypeKeyword {
                case "func":
                case "record":
                case "variant":
                case "list":
                case "tuple":
                case "flags":
                case "enum":
                case "option":
                case "result":
                case "own":
                case "borrow":
                case "stream":
                case "future":
                default:
                    throw WatParserError(
                        "Unexpected composite component type keyword `\(compositeTypeKeyword)",
                        location: parser.lexer.location()
                    )
                }
            }
        }

        private mutating func parseComponentFunction(
            _ parsedComponent: inout ComponentDef
        ) throws(WatParserError) {
            let funcLocation = parser.lexer.location()
            let id = try parser.takeId()
            var parameters = [(name: String, type: ComponentType)]()
            var resultType: ComponentType?
            var typeId: Parser.IndexOrId?
            var exportDef: (Location, exportName: String)?
            var importDef: (Location, importModule: String, importName: String)?

            /// Component functions are not tracked as separate entities in the final binary, i.e. there's no dedicated
            /// component functions section in the binary format. They're always encoded as a part of following
            /// sections: imports, exports, types, or canonical definitions.
            /// What looks like a function definition in component WAT `(func ...)` always desugars into one or
            /// more definitions in those sections.
            while try parser.take(.leftParen) {
                let keyword = try parser.expectKeyword()
                switch keyword {
                case "param":
                    guard resultType == nil else {
                        throw WatParserError(
                            "Unknown component function parameter after function result is already declared",
                            location: parser.lexer.location()
                        )
                    }

                    let label = try parser.expectString()
                    parameters.append((label, try parseComponentType()))

                case "result":
                    resultType = try parseComponentType()

                case "export":
                    exportDef = (parser.lexer.location(), try parser.expectString())

                case "import":
                    let importModuleName = try parser.expectString()
                    let importName = try parser.expectString()
                    importDef = (parser.lexer.location(), importModuleName, importName)

                case "canon":
                    let location = parser.lexer.location()
                    try parser.expectKeyword("lift")
                    let coreFunctionIndex = try parseCoreFunctionIndex()
                    var options = [CanonDef.Option]()
                    while try parser.take(.leftParen) {
                        options.append(try parseCanonOpt())
                        try parser.expect(.rightParen)
                    }
                    parsedComponent.fields.append(
                        .init(
                            location: location,
                            kind: .canon(.init(
                                kind: .lift(coreFunctionIndex),
                                functionIndex: coreFunctionIndex,
                                options: options
                            ))
                        )
                    )

                default:
                    throw WatParserError(
                        "Unknown component function keyword \(keyword)",
                        location: parser.lexer.location()
                    )
                }

                try parser.expect(.rightParen)
            }

            let concreteType: ComponentTypeDef.Kind
            if parameters.count > 0 || resultType != nil {
                concreteType = .function(parameters.map(\.type), resultType)
            } else {
                concreteType = .function([], nil)
            }

            let typeIndex: Int
            if let existingTypeIndex = parsedComponent.typesMap[concreteType] {
                typeIndex = existingTypeIndex
            } else {
                typeIndex = try parsedComponent.componentTypes.add(.init(kind: concreteType))
                parsedComponent.typesMap[concreteType] = typeIndex
            }

            let funcIndex = try parsedComponent.componentFunctions.add(
                ComponentFuncDef(paramNames: parameters.map(\.name), type: .init(rawValue: typeIndex))
            )
            parsedComponent.fields.append(
                .init(
                    location: ,
                    kind: .exportDef(ExportDef(exportName: exportName, descriptor: .function(<#T##Parser.IndexOrId#>)))
                )
            )
        }

        private mutating func parseCanonOpt() throws(WatParserError) -> CanonDef.Option {
            let keyword = try parser.expectKeyword()
            switch keyword {
            case "memory":
                return .memory(try parser.expectIndexOrId())
            case "realloc":
                return .realloc(try parseCoreFunctionIndex())
            case "post-return":
                return .postReturn(try parseCoreFunctionIndex())
            case "async":
                return .async
            case "callback":
                return .callback(try parseCoreFunctionIndex())
            default:
                throw WatParserError(
                    "Unknown canon options keyword \(keyword)",
                    location: parser.lexer.location()
                )
            }
        }

        private mutating func parseCoreFunctionIndex() throws(WatParserError) -> FuncIndex {
            try parser.expect(.leftParen)
            try parser.expectKeyword("core")
            try parser.expectKeyword("func")
            let instanceId = try parser.expectIndexOrId()
            let exportName = try parser.expectString()
            try parser.expect(.rightParen)

            return .init(instance: instanceId, exportName: exportName)
        }
    }

    extension ComponentWatParser {
        struct ComponentDefField {
            enum Kind {
                case coreModule(ModuleDef)
                case coreInstance(CoreInstanceDef)
                case coreType(WatParser.FunctionType)
                case component(ComponentIndex)
                case instance(ComponentInstanceIndex)
                case canon(CanonDef)
                case exportDef(ExportDef)
                case importDef(ImportDef)
            }

            let location: Location
            let kind: Kind
        }

        struct ValueDef: NamedFieldDecl {
            var id: Name?
        }

        struct ComponentInstanceDef: NamedFieldDecl {
            var id: Name?
        }

        /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
        struct ComponentDef: NamedFieldDecl {
            var id: Name?

            // Listed in the order of section indices in binary encoding.
            var coreModulesMap: NameMapping<ModuleDef> = .init()
            var coreInstancesMap: NameMapping<CoreInstanceDef> = .init()
            var coreTypesMap: NameMapping<ComponentTypeDef> = .init()

            var componentFunctions: NameMapping<ComponentFuncDef> = .init()
            var valuesMap: NameMapping<ValueDef> = .init()
            var componentTypes: NameMapping<ComponentTypeDef> = .init()
            var componentInstancesMap: NameMapping<ComponentInstanceDef> = .init()
            var componentsMap: NameMapping<ComponentDef> = .init()

            /// As sections in CM binaries can stay disjoint and unmerged, for compatibility with other tools,
            /// we should preserve disjoint sections together with their ordering.
            var fields = [ComponentDefField]()

            /// Mapping from a component type to its unique ID in `componentTypes` name mapping storage.
            var typesMap = [ComponentTypeDef.Kind: Int]()

            struct Aliases {
                init() {}
            }

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
            var id: Name?
            let type: FunctionType
        }

        struct FuncIndex {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        struct CanonDef {
            enum Option {
                enum Encoding {
                    case utf8
                    case utf16
                    case latin1UTF16
                }
                case stringEncoding(Encoding)
                case memory(Parser.IndexOrId)
                case realloc(FuncIndex)
                case postReturn(FuncIndex)
                case `async`
                case callback(FuncIndex)
            }

            enum Kind {
                case lower(ComponentFuncIndex)
                case lift(FuncIndex)
            }
            let kind: Kind
            let functionIndex: FuncIndex
            let options: [Option]
        }

        enum ExternDesc {
            case module(Parser.IndexOrId)
            case function(Parser.IndexOrId)
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
                case function([ComponentType], ComponentType?)
            }
            var id: Name?
            let kind: Kind
        }
    }

#endif
