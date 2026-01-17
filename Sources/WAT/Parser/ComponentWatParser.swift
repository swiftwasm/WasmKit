#if ComponentModel

    import ComponentModel
    import WasmParser

    struct ComponentWatParser {
        var parser: Parser
        let features: WasmFeatureSet

        struct Field {
            enum Kind {
                case component(Name?, [ComponentDefField])
            }
            let location: Location
            let kind: Kind
        }

        init(_ input: String, features: WasmFeatureSet) {
            self.parser = Parser(input)
            self.features = features
        }

        mutating func next() throws(WatParserError) -> Field? {
            // If we have reached the end of the (component ...) block, return nil
            guard try !parser.isEndOfParen() else { return nil }
            try parser.expect(.leftParen)
            let location = parser.lexer.location()
            let keyword = try parser.expectKeyword()

            let field: Field
            switch keyword {
            case "component":
                let id = try parser.takeId()

                var componentDefs = [ComponentDefField]()
                while try parser.take(.leftParen) {
                    let componentDefKeyword = try parser.expectKeyword()
                    switch componentDefKeyword {
                    case "core":
                        let coreKeyword = try parser.expectKeyword()
                        switch coreKeyword {
                        case "module":
                            componentDefs.append(.coreModule(try self.parseModuleDef()))

                        case "instance":
                            componentDefs.append(.coreInstance(try self.parseCoreInstanceDef()))

                        default:
                            throw WatParserError(
                                "Unknown core definition keyword \(coreKeyword)",
                                location: parser.lexer.location()
                            )
                        }
                    case "func":
                        componentDefs.append(contentsOf: try parseComponentFunction())
                    default:
                        throw WatParserError(
                            "Unknown component definition keyword \(componentDefKeyword)",
                            location: parser.lexer.location()
                        )
                    }
                    try parser.expect(.rightParen)
                }
                field = .init(location: location, kind: .component(id, componentDefs))
            default:
                fatalError()
            }

            // Check if the parser has reached the end of the function body
            guard try parser.isEndOfParen() else {
                throw WatParserError("unexpected token", location: parser.lexer.location())
            }

            return field
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

        private mutating func parseComponentFunction() throws(WatParserError) -> [ComponentDefField] {
            var result = [ComponentDefField]()
            let id = try parser.takeId()
            try parser.expect(.leftParen)
            let keyword = try parser.expectKeyword()
            switch keyword {
            case "export":
            case "import":
            case "canon":
                try parser.expectKeyword("lift")
                let coreFunctionIndex = try parseCoreFunctionIndex()
                var options = [CanonDef.Option]()
                while try parser.take(.leftParen) {
                    options.append(try parseCanonOpt())
                    try parser.expect(.rightParen)
                }
                result.append(
                    .canon(
                        .init(
                            id: id,
                            kind: .lift,
                            functionIndex: coreFunctionIndex,
                            options: options
                        ))
                )

            default:
                throw WatParserError(
                    "Unknown component function keyword \(keyword)",
                    location: parser.lexer.location()
                )
            }
            try parser.expectKeyword("export")
            let exportName = try parser.takeString()
            try parser.expect(.rightParen)
            return result
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
        enum ComponentDefField {
            case coreModule(ModuleDef)
            case coreInstance(CoreInstanceDef)
            case coreType(WatParser.FunctionType)
            case component(ComponentDef)
            case instance(ComponentInstanceDef)
            case canon(CanonDef)
        }

        struct ValueDef: NamedModuleFieldDecl {
            var id: Name?
        }

        struct TypeDef: NamedModuleFieldDecl {
            var id: Name?
        }

        struct ComponentInstanceDef: NamedModuleFieldDecl {
            var id: Name?
        }

        struct ComponentDef: NamedModuleFieldDecl {
            var id: Name?
            let fields: [ComponentDefField]
        }

        struct ModuleDef: NamedModuleFieldDecl {
            var id: Name?
            var wat: Wat
        }

        struct CoreInstanceDef: NamedModuleFieldDecl {
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

        struct FuncIndex {
            var instance: Parser.IndexOrId
            var exportName: String
        }

        struct CanonDef: NamedModuleFieldDecl {
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
                case lower
                case lift
            }
            var id: Name?
            let kind: Kind
            let functionIndex: FuncIndex
            let options: [Option]
        }
    }

#endif
