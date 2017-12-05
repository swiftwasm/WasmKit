import Antlr4

public enum WASTParseError: Error {
    case visitorError
    case syntaxError(line: Int, column: Int, message: String)
}

private final class ErrorListener: BaseErrorListener {
    var errors: [WASTParseError] = []

    override func syntaxError<T>(
        _: Recognizer<T>,
        _: AnyObject?,
        _ line: Int,
        _ charPositionInLine: Int,
        _ msg: String,
        _: AnyObject?
    ) {
        errors.append(.syntaxError(line: line, column: charPositionInLine, message: msg))
    }
}

public extension Module {
    init(wast input: String) throws {
        let input = ANTLRInputStream(input)
        let errorListener = ErrorListener()

        let lexer = WASTLexer(input)
        lexer.removeErrorListeners()
        lexer.addErrorListener(errorListener)

        let tokenStream = CommonTokenStream(lexer)
        let parser = try WASTParser(tokenStream)
        parser.removeErrorListeners()
        parser.addErrorListener(errorListener)

        let visitor = WASTModuleVisitor()

        guard let module = visitor.visit(try parser.module()) else {
            throw WASTParseError.visitorError
        }

        guard errorListener.errors.isEmpty else {
            throw errorListener.errors.first!
        }

        self = module
    }
}

/// https://webassembly.github.io/spec/text/modules.html#modules
private final class WASTModuleVisitor: WASTVisitor<Module> {

    override func visit(_ tree: ParseTree) -> Module? {
        guard let tree = tree as? WASTParser.ModuleContext else {
            return nil
        }
        return visitModule(tree)
    }

    override func visitModule(_ ctx: WASTParser.ModuleContext) -> Module {
        var module = Module(
            types: [], functions: [], tables: [], memories: [], globals: [],
            elements: [], data: [], start: nil, imports: [], exports: []
        )

        for field in ctx.moduleField() {
            if let typeDefinition = field.typeDefinition() {
                guard let type = typeDefinition.accept(WASTFunctionTypeVisitor()) else {
                    fatalError("\(#file, #function, #line)")
                }
                module.types.append(type)
            }
//            Type Uses
//            Imports

            if let functionDefinition = field.functionDefinition() {
                guard let function = functionDefinition.accept(WASTFunctionVisitor()) else {
                    fatalError("\(#file, #function, #line)")
                }
                module.functions.append(function)
            }

//            Tables
//            Memories
//            Globals
//            Exports
//            Start Function
//            Element Segments
//            Data Segments
        }

        return module
    }
}

/// https://webassembly.github.io/spec/text/modules.html#functions
private final class WASTFunctionVisitor: WASTVisitor<Function> {
    override func visitFunctionDefinition(_ ctx: WASTParser.FunctionDefinitionContext) -> Function {
        return Function(type: 0, locals: [], body: Expression(instructions: []))
    }
}

/// https://webassembly.github.io/spec/text/types.html#function-types
private final class WASTFunctionTypeVisitor: WASTVisitor<FunctionType> {
    override func visitTypeDefinition(_ ctx: WASTParser.TypeDefinitionContext) -> FunctionType {
        guard let functionType = ctx.functionType() else {
            fatalError("\(#file, #function, #line)")
        }
        guard let type = functionType.accept(self) else {
            fatalError("\(#file, #function, #line)")
        }
        return type
    }

    override func visitFunctionType(_ ctx: WASTParser.FunctionTypeContext) -> FunctionType {
        var parameters = [Value.Type]()
        for functionParameter in ctx.functionParameter() {
            for valueTypeCtx in functionParameter.valueType() {
                guard let valueType = valueTypeCtx.accept(WASTValueTypesVisitor()) else {
                    fatalError("\(#file, #function, #line)")
                }
                parameters.append(valueType)
            }
        }

        var results = [Value.Type]()
        for functionResult in ctx.functionResult() {
            for valueResultCtx in functionResult.valueType() {
                guard let valueResult = valueResultCtx.accept(WASTValueTypesVisitor()) else {
                    fatalError("\(#file, #function, #line)")
                }
                results.append(valueResult)
            }
        }

        return FunctionType(parameters: parameters, results: results)
    }
}

/// https://webassembly.github.io/spec/text/types.html#value-types
private final class WASTValueTypesVisitor: WASTVisitor<Value.Type> {
    override func visitValueType(_ ctx: WASTParser.ValueTypeContext) -> Value.Type {
        switch ctx.getText() {
        case "i32": return Int32.self
        case "i64": return Int64.self
        case "f32": return Float32.self
        case "f64": return Float64.self
        default: fatalError("\(#file, #function, #line)")
        }
    }
}

private final class WASTUnsignedVisitor: WASTVisitor<UInt32> {
    override func visitTerminal(_ node: TerminalNode) -> UInt32? {
        fatalError(node.getText())
        return 123
    }
}
