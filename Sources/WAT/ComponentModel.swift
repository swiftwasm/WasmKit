import WasmParser

/// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
package struct ComponentWat {
    let functionsMap: NameMapping<ComponentWatParser.FunctionDecl>
    let valuesMap: NameMapping<ComponentWatParser.ValueDecl>
    let typesMap: NameMapping<ComponentWatParser.TypeDecl>
    let componentTnstancesMap: NameMapping<ComponentWatParser.InstanceDecl>
    let componentsMap: NameMapping<ComponentWatParser.ComponentDecl>
    let modulesMap: NameMapping<ComponentWatParser.ModuleDecl>
    let moduleInstancesMap: NameMapping<ComponentWatParser.ModuleInstanceDecl>
}

struct ComponentWatParser {
    var parser: Parser
    let features: WasmFeatureSet

    init(_ input: String, features: WasmFeatureSet) {
        self.parser = Parser(input)
        self.features = features
    }

    mutating func nextDirective() throws -> WastDirective? {
        var originalParser = parser
        guard (try parser.peek(.leftParen)) != nil else { return nil }
        try parser.consume()
        //        guard try WastDirective.peek(wastParser: self) else {
        //            if try peekModuleField() {
        //                // Parse inline module, which doesn't include surrounding (module)
        //                let location = originalParser.lexer.location()
        //                return .module(
        //                    ModuleDirective(
        //                        source: .text(try parseWAT(&originalParser, features: features)), id: nil, location: location
        //                    ))
        //            }
        //            throw WatParserError("unexpected wast directive token", location: parser.lexer.location())
        //        }
        //        let directive = try WastDirective.parse(wastParser: &self)
        //        return directive
        return nil
    }
}

extension ComponentWatParser {
    struct FunctionDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ValueDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct TypeDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct InstanceDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ComponentDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ModuleDecl: NamedModuleFieldDecl {
        var id: Name?
    }

    struct ModuleInstanceDecl: NamedModuleFieldDecl {
        var id: Name?
    }
}
