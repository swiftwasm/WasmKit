import ComponentModel
import WasmParser

struct ComponentWatParser {
    var parser: Parser
    let features: WasmFeatureSet

    struct Field {
        enum Kind {
            case component(Name?, [ComponentDef])
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

            var componentDecls = [ComponentDef]()
            while try parser.take(.leftParen) {
                switch try parser.expectKeyword() {
                case "core":
                    try parser.consume()

                    switch try parser.expectKeyword() {
                    case "module":
                        let moduleID = try parser.takeId()
                        let wat = try parseWAT(&parser, features: features)
                        componentDecls.append(.init(id: moduleID, kind: .coreModule(wat)))

                    case "instance":
                        let instanceID = try parser.takeId()
                        try parser.expect(.leftParen)

                        switch try parser.expectKeyword() {
                        case "instantiate":
                            let instantiatedModuleID = try parser.takeId()
                            var instantiateArguments = [ModuleInstanceDef.Argument]()

                            while try parser.take(.leftParen) {
                                try parser.expectKeyword("with")
                                let exportName = try parser.expectString()
//                                instantiateArguments.append(.)
                                try parser.expect(.rightParen)
                            }
                            componentDecls.append(
                                .init(
                                    id: instantiatedModuleID,
                                    kind: .coreInstance(.init(id: instantiatedModuleID, arguments: instantiateArguments))
                                )
                            )
                        default:
                            fatalError()
                        }

                    default:
                        fatalError()
                    }
                default:
                    fatalError()
                }
                try parser.expect(.rightParen)
            }
            field = .init(location: location, kind: .component(id, componentDecls))
        default:
            fatalError()
        }

        try parser.expect(.rightParen)

        return field
    }
}

extension ComponentWatParser {
    struct FunctionDef: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ValueDef: NamedModuleFieldDecl {
        var id: Name?
    }

    struct TypeDef: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ComponentInstanceDef {
        var id: Name?
    }

    struct ComponentDef: NamedModuleFieldDecl {
        enum Kind {
            case coreModule(Wat)
            case coreInstance(ModuleInstanceDef)
            case coreType(WatParser.FunctionType)
            indirect case component(ComponentDef)
            case instance(ComponentInstanceDef)
        }

        var id: Name?
        let kind: Kind
    }

    struct ModuleDef: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ModuleInstanceDef: NamedModuleFieldDecl {
        enum Argument {
            struct Export {
                let name: String
                let sort: CoreDeclSort
                let index: UInt32
            }
            case instance(Name, ModuleInstanceIndex)
            case exports([Export])
        }

        var id: Name?
        var arguments: [Argument]
    }
}
