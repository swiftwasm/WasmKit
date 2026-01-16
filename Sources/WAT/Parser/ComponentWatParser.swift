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


    mutating func next() throws -> Field? {
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
                        let instanceId = try parser.takeId()
                        try parser.expect(.leftParen)

                        try parser.expectKeyword("instantiate")
                        let instantiatedModuleId = try parser.expectIndexOrId()
                        var instantiateArguments = [CoreInstanceDef.Argument]()

                        while try parser.take(.leftParen) {
                            instantiateArguments.append(try self.parseModuleInstanceArguments())
                            try parser.expect(.rightParen)
                        }
                        componentDefs.append(
                            .coreInstance(
                            CoreInstanceDef(
                                id: instanceId,
                                moduleId: instantiatedModuleId,
                                arguments: instantiateArguments ) ) )

                    default:
                        throw WatParserError(
                            "Unknown core definition keyword \(coreKeyword)",
                            location: parser.lexer.location()
                        )
                    }
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

        try parser.expect(.rightParen)

        return field
    }

    private mutating func parseModuleDef() throws -> ModuleDef {
        let moduleID = try parser.takeId()
        let wat = try parseWAT(&parser, features: features)
        return .init(id: moduleID, wat: wat)
    }

    private mutating func parseModuleInstanceArguments() throws -> CoreInstanceDef.Argument {
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


    private mutating func parseCoreDefSort() throws -> CoreDefSort {
        let rawKeyword = try parser.expectKeyword()
        guard let keyword = CoreDefSort(rawValue: rawKeyword) else {
            throw WatParserError(
                "Unexpected core declaration sort `\(rawKeyword)",
                location: parser.lexer.location()
            )
        }

        return keyword
    }

    private mutating func parseComponentDefSort() throws -> ComponentDefSort {
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
}

extension ComponentWatParser {
    enum ComponentDefField {
        case coreModule(ModuleDef)
        case coreInstance(CoreInstanceDef)
        case coreType(WatParser.FunctionType)
        case component(ComponentDef)
        case instance(ComponentInstanceDef)
    }

    struct FunctionDef: NamedModuleFieldDecl {
        var id: Name?
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
        let wat: Wat
    }

    struct CoreInstanceDef: NamedModuleFieldDecl {
        struct Argument {
            enum Kind {
                struct Export {
                    let name: String
                    let sort: CoreDeclSort
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
}
