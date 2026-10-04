import WasmParser
import WasmTypes

protocol WASTConstInstructionVisitor: InstructionVisitor {
    mutating func visitRefExtern(value: UInt32) throws(WatParserError)
    /// Visits `ref.host`, the script notation for a host value that was internalized into `anyref`.
    mutating func visitRefHost(value: UInt32) throws(WatParserError)
}

/// A parser for WAST format.
/// You can find its grammar definition in the [WebAssembly spec repository](https://github.com/WebAssembly/spec/blob/wg-1.0/interpreter/README.md#scripts)
struct WASTParser {
    var parser: Parser
    let features: WasmFeatureSet

    init(_ input: String, features: WasmFeatureSet) {
        self.parser = Parser(input)
        self.features = features
    }

    mutating func nextDirective() throws(WatParserError) -> WASTDirective? {
        var originalParser = parser
        guard (try parser.peek(.leftParen)) != nil else { return nil }
        try parser.consume()
        guard try WASTDirective.peek(wastParser: self) else {
            if try peekModuleField() {
                // Parse inline module, which doesn't include surrounding (module)
                let location = originalParser.lexer.location()
                return .module(
                    ModuleDirective(
                        source: .text(try parseWAT(&originalParser, features: features)), id: nil, location: location
                    ))
            }
            throw WatParserError("unexpected wast directive token", location: parser.lexer.location())
        }
        let directive = try WASTDirective.parse(wastParser: &self)
        return directive
    }

    private func peekModuleField() throws(WatParserError) -> Bool {
        guard let keyword = try parser.peekKeyword() else { return false }
        switch keyword {
        case "data", "elem", "tag", "export", "func",
            "type", "rec", "global", "import", "memory",
            "start", "table":
            return true
        default:
            return false
        }
    }

    mutating func parens<T>(_ body: (inout WASTParser) throws(WatParserError) -> T) throws(WatParserError) -> T {
        try parser.expect(.leftParen)
        let result = try body(&self)
        return result
    }

    struct ConstExpressionCollector: WASTConstInstructionVisitor {
        var binaryOffset: Int = 0
        let addValue: (WASTConstValue) -> Void

        mutating func visitI32Const(value: Int32) throws(WatParserError) { addValue(.i32(UInt32(bitPattern: value))) }
        mutating func visitI64Const(value: Int64) throws(WatParserError) { addValue(.i64(UInt64(bitPattern: value))) }
        mutating func visitF32Const(value: IEEE754.Float32) throws(WatParserError) { addValue(.f32(value.bitPattern)) }
        mutating func visitF64Const(value: IEEE754.Float64) throws(WatParserError) { addValue(.f64(value.bitPattern)) }
        mutating func visitV128Const(value: V128) throws(WatParserError) { addValue(.v128(value)) }
        mutating func visitRefFunc(functionIndex: UInt32) throws(WatParserError) {
            addValue(.refFunc(functionIndex: functionIndex))
        }
        mutating func visitRefNull(type: HeapType) throws(WatParserError) {
            addValue(.refNull(type))
        }
        func visitRefExtern(value: UInt32) throws(WatParserError) {
            addValue(.refExtern(value: value))
        }
        func visitRefHost(value: UInt32) throws(WatParserError) {
            addValue(.refHost(value: value))
        }
    }

    mutating func argumentValues() throws(WatParserError) -> [WASTConstValue] {
        var values: [WASTConstValue] = []
        var collector = ConstExpressionCollector(addValue: { values.append($0) })
        var exprParser = ExpressionParser<ConstExpressionCollector>(lexer: parser.lexer, features: features)
        while try exprParser.parseWastConstInstruction(visitor: &collector) {}
        parser = exprParser.parser
        return values
    }

    mutating func expectationValues() throws(WatParserError) -> [WASTExpectValue] {
        var values: [WASTExpectValue] = []
        var collector = ConstExpressionCollector(addValue: {
            let value: WASTExpectValue
            switch $0 {
            case .i32(let v): value = .i32(v)
            case .i64(let v): value = .i64(v)
            case .f32(let v): value = .f32(v)
            case .f64(let v): value = .f64(v)
            case .v128(let v): value = .v128(v)
            case .refNull(let heapTy): value = .refNull(heapTy)
            case .refFunc(let index): value = .refFunc(functionIndex: index)
            case .refExtern(let v): value = .refExtern(value: v)
            case .refHost(let v): value = .refHost(value: v)
            }
            values.append(value)
        })
        var exprParser = ExpressionParser<ConstExpressionCollector>(lexer: parser.lexer, features: features)
        while true {
            if let expectValue = try exprParser.parseWastExpectValue() {
                values.append(expectValue)
                continue
            }
            if try exprParser.parseWastConstInstruction(visitor: &collector) {
                continue
            }
            break
        }
        parser = exprParser.parser
        return values
    }
}

public enum WASTExecute {
    case invoke(WASTInvoke)
    case wat(Wat)
    case get(module: String?, globalName: String)

    static func parse(wastParser: inout WASTParser) throws(WatParserError) -> WASTExecute {
        let keyword = try wastParser.parser.peekKeyword()
        let execute: WASTExecute
        switch keyword {
        case "invoke":
            execute = .invoke(try WASTInvoke.parse(wastParser: &wastParser))
        case "module":
            try wastParser.parser.consume()
            execute = .wat(try parseWAT(&wastParser.parser, features: wastParser.features))
            try wastParser.parser.skipParenBlock()
        case "get":
            try wastParser.parser.consume()
            let module = try wastParser.parser.takeId()
            let globalName = try wastParser.parser.expectString()
            execute = .get(module: module?.value, globalName: globalName)
            try wastParser.parser.expect(.rightParen)
        case let keyword?:
            throw WatParserError(
                "unexpected wast execute \(keyword)",
                location: wastParser.parser.lexer.location()
            )
        case nil:
            throw WatParserError("unexpected eof", location: wastParser.parser.lexer.location())
        }
        return execute
    }
}

public enum WASTConstValue {
    case i32(UInt32)
    case i64(UInt64)
    case f32(UInt32)
    case f64(UInt64)
    case v128(V128)
    case refNull(HeapType)
    case refFunc(functionIndex: UInt32)
    case refExtern(value: UInt32)
    /// A host value internalized into `anyref`, written `(ref.host N)`.
    case refHost(value: UInt32)
}

public struct WASTInvoke {
    public let module: String?
    public let name: String
    public let args: [WASTConstValue]

    static func parse(wastParser: inout WASTParser) throws(WatParserError) -> WASTInvoke {
        try wastParser.parser.expectKeyword("invoke")
        let module = try wastParser.parser.takeId()
        let name = try wastParser.parser.expectString()
        let args = try wastParser.argumentValues()
        try wastParser.parser.expect(.rightParen)
        let invoke = WASTInvoke(module: module?.value, name: name, args: args)
        return invoke
    }
}

public struct V128Expectation: Equatable {
    public enum Shape: Equatable {
        case f32x4
        case f64x2
    }

    public let shape: Shape?
    public let bytes: [UInt8]
    /// Bit i indicates the i-th float lane expects any NaN.
    public let nanLaneMask: UInt8

    public init(shape: Shape?, bytes: [UInt8], nanLaneMask: UInt8) {
        precondition(bytes.count == V128.byteCount, "V128Expectation must be exactly \(V128.byteCount) bytes")
        self.shape = shape
        self.bytes = bytes
        self.nanLaneMask = nanLaneMask
    }
}

public enum WASTExpectValue {
    case i32(UInt32)
    case i64(UInt64)
    case f32(UInt32)
    case f64(UInt64)
    case v128(V128)
    case v128Pattern(V128Expectation)

    /// A value that is expected to be a null reference,
    /// optionally with a specific type.
    case refNull(HeapType?)
    /// A value that is expected to be a non-null reference
    /// to a function, optionally with a specific index.
    case refFunc(functionIndex: UInt32?)
    /// A value that is expected to be a non-null reference
    /// to an extern, optionally with a specific value.
    case refExtern(value: UInt32?)
    /// A value that is expected to be a non-null reference to a struct.
    case refStruct
    /// A value that is expected to be a non-null reference to an array.
    case refArray
    /// A value that is expected to be a non-null `eqref`: an i31, a struct or an array.
    case refEq
    /// A value that is expected to be a non-null `i31ref`.
    case refI31
    /// A value that is expected to be any non-null internal reference.
    case refAny
    /// A value that is expected to be the host value with the given number, internalized into `anyref`.
    case refHost(value: UInt32)
    /// A value that is expected to be a canonical NaN.
    /// Corresponds to `f32.const nan:canonical` in WAST.
    case f32CanonicalNaN
    /// A value that is expected to be an arithmetic NaN.
    /// Corresponds to `f32.const nan:arithmetic` in WAST.
    case f32ArithmeticNaN
    /// A value that is expected to be a canonical NaN.
    /// Corresponds to `f64.const nan:canonical` in WAST.
    case f64CanonicalNaN
    /// A value that is expected to be an arithmetic NaN.
    /// Corresponds to `f64.const nan:arithmetic` in WAST.
    case f64ArithmeticNaN
    /// A relaxed-SIMD non-deterministic expectation: the result matches if it equals any candidate.
    /// Corresponds to `(either <result>…)` in WAST.
    indirect case either([WASTExpectValue])
}

/// A directive in a WAST script.
public enum WASTDirective {
    case module(ModuleDirective)
    /// Instantiate a module defined by `(module definition ...)`.
    ///
    /// Example: `(module instance $I $M)` instantiates the definition `$M` and names the
    /// instance `$I`. Without a module name, the most recent definition is instantiated.
    case moduleInstance(instance: String?, module: String?)
    case assertInvalid(module: ModuleDirective, message: String)
    case assertMalformed(module: ModuleDirective, message: String)
    case assertReturn(execute: WASTExecute, results: [WASTExpectValue])
    case assertTrap(execute: WASTExecute, message: String)
    case assertExhaustion(call: WASTInvoke, message: String)
    case assertException(execute: WASTExecute)
    /// Assert that running `execute` consumes exactly `fuel` units of fuel.
    ///
    /// Example: `(assert_fuel 3 (invoke "f"))`, or `(assert_fuel 5 (module (func $f) (start $f)))`
    /// to measure instantiation. Only meaningful on an engine configured for fuel metering; the
    /// runner turns metering on for a script that uses this directive.
    case assertFuel(execute: WASTExecute, fuel: UInt64)
    /// Assert that running `execute` with a budget of `fuel` units exhausts it.
    ///
    /// Example: `(assert_out_of_fuel 1000 (invoke "spin"))`. The budget is named by the directive
    /// because a run that is supposed to never finish needs a finite one to stop against.
    case assertOutOfFuel(execute: WASTExecute, fuel: UInt64)
    case assertUnlinkable(module: Wat, message: String)
    case register(name: String, moduleId: String?)
    case invoke(WASTInvoke)

    static func peek(wastParser: WASTParser) throws(WatParserError) -> Bool {
        guard let keyword = try wastParser.parser.peekKeyword() else { return false }
        return keyword.starts(with: "assert_") || keyword == "module" || keyword == "register" || keyword == "invoke"
    }

    /// Parse a directive in a WAST script from "keyword ...)" form.
    /// Leading left parenthesis is already consumed, and the trailing right parenthesis should be consumed by this function.
    static func parse(wastParser: inout WASTParser) throws(WatParserError) -> WASTDirective {
        let keyword = try wastParser.parser.peekKeyword()
        switch keyword {
        case "module":
            var lookahead = wastParser.parser
            try lookahead.consume()
            if try lookahead.takeKeyword("instance") {
                wastParser.parser = lookahead
                let instance = try wastParser.parser.takeId()
                let module = try wastParser.parser.takeId()
                try wastParser.parser.expect(.rightParen)
                return .moduleInstance(instance: instance?.value, module: module?.value)
            }
            return .module(try ModuleDirective.parse(wastParser: &wastParser))
        case "assert_invalid":
            try wastParser.parser.consume()
            let module = try wastParser.parens { wastParser throws(WatParserError) in try ModuleDirective.parse(wastParser: &wastParser) }
            let message = try wastParser.parser.expectString()
            try wastParser.parser.expect(.rightParen)
            return .assertInvalid(module: module, message: message)
        case "assert_malformed", "assert_malformed_custom":
            try wastParser.parser.consume()
            let module = try wastParser.parens { wastParser throws(WatParserError) in try ModuleDirective.parse(wastParser: &wastParser) }
            let message = try wastParser.parser.expectString()
            try wastParser.parser.expect(.rightParen)
            return .assertMalformed(module: module, message: message)
        case "assert_return":
            try wastParser.parser.consume()
            let execute = try wastParser.parens { wastParser throws(WatParserError) in try WASTExecute.parse(wastParser: &wastParser) }
            let results = try wastParser.expectationValues()
            try wastParser.parser.expect(.rightParen)
            return .assertReturn(execute: execute, results: results)
        case "assert_trap":
            try wastParser.parser.consume()
            let execute = try wastParser.parens { wastParser throws(WatParserError) in try WASTExecute.parse(wastParser: &wastParser) }
            let message = try wastParser.parser.expectString()
            try wastParser.parser.expect(.rightParen)
            return .assertTrap(execute: execute, message: message)
        case "assert_exhaustion":
            try wastParser.parser.consume()
            let call = try wastParser.parens { wastParser throws(WatParserError) in try WASTInvoke.parse(wastParser: &wastParser) }
            let message = try wastParser.parser.expectString()
            try wastParser.parser.expect(.rightParen)
            return .assertExhaustion(call: call, message: message)
        case "assert_fuel":
            try wastParser.parser.consume()
            let fuel = try wastParser.parser.expectUnsignedInt(UInt64.self)
            let execute = try wastParser.parens { wastParser throws(WatParserError) in try WASTExecute.parse(wastParser: &wastParser) }
            try wastParser.parser.expect(.rightParen)
            return .assertFuel(execute: execute, fuel: fuel)
        case "assert_out_of_fuel":
            try wastParser.parser.consume()
            let fuel = try wastParser.parser.expectUnsignedInt(UInt64.self)
            let execute = try wastParser.parens { wastParser throws(WatParserError) in try WASTExecute.parse(wastParser: &wastParser) }
            try wastParser.parser.expect(.rightParen)
            return .assertOutOfFuel(execute: execute, fuel: fuel)
        case "assert_exception":
            try wastParser.parser.consume()
            let execute = try wastParser.parens { wastParser throws(WatParserError) in try WASTExecute.parse(wastParser: &wastParser) }
            try wastParser.parser.expect(.rightParen)
            return .assertException(execute: execute)
        case "assert_unlinkable":
            try wastParser.parser.consume()
            let features = wastParser.features
            let module = try wastParser.parens { wastParser throws(WatParserError) in
                try wastParser.parser.expectKeyword("module")
                let wat = try parseWAT(&wastParser.parser, features: features)
                try wastParser.parser.skipParenBlock()
                return wat
            }
            let message = try wastParser.parser.expectString()
            try wastParser.parser.expect(.rightParen)
            return .assertUnlinkable(module: module, message: message)
        case "register":
            try wastParser.parser.consume()
            let name = try wastParser.parser.expectString()
            let module = try wastParser.parser.takeId()
            try wastParser.parser.expect(.rightParen)
            return .register(name: name, moduleId: module?.value)
        case "invoke":
            let invoke = try WASTInvoke.parse(wastParser: &wastParser)
            return .invoke(invoke)
        case let keyword?:
            throw WatParserError(
                "unexpected wast directive \(keyword)",
                location: wastParser.parser.lexer.location()
            )
        case nil:
            throw WatParserError("unexpected eof", location: wastParser.parser.lexer.location())
        }
    }
}

/// A module representation in "(module ...)" form in WAST.
public struct ModuleDirective {
    /// The source of the module
    public let source: ModuleSource
    /// The name of the module specified in $id form
    public let id: String?
    /// The location of the module in the source
    public let location: Location
    /// Whether this is a `(module definition ...)`, which is validated but not instantiated
    /// until a `(module instance ...)` directive names it.
    public let isDefinition: Bool

    init(source: ModuleSource, id: String?, location: Location, isDefinition: Bool = false) {
        self.source = source
        self.id = id
        self.location = location
        self.isDefinition = isDefinition
    }

    static func parse(wastParser: inout WASTParser) throws(WatParserError) -> ModuleDirective {
        let location = wastParser.parser.lexer.location()
        try wastParser.parser.expectKeyword("module")
        let isDefinition = try wastParser.parser.takeKeyword("definition")
        let id = try wastParser.parser.takeId()
        var source = try ModuleSource.parse(wastParser: &wastParser)
        if let id, case .text(var wat) = source, wat.id == nil {
            wat.id = .identifier(id.value)
            source = .text(wat)
        }
        return ModuleDirective(source: source, id: id?.value, location: location, isDefinition: isDefinition)
    }
}

/// The source of a module in WAST.
public enum ModuleSource {
    /// A parsed WAT module
    case text(Wat)
    /// A text form of WAT module
    case quote([UInt8])
    /// A binary form of WebAssembly module
    case binary([UInt8])

    static func parse(wastParser: inout WASTParser) throws(WatParserError) -> ModuleSource {
        if let rawSource = try wastParser.parser.parseBinaryOrQuote() {
            switch rawSource {
            case .binary(let bytes): return .binary(bytes)
            case .quote(let bytes): return .quote(bytes)
            }
        }

        let nameAnnot = try wastParser.parser.takeNameAnnotation()
        if nameAnnot != nil, try wastParser.parser.takeNameAnnotation() != nil {
            throw WatParserError("@name annotation: multiple module names", location: wastParser.parser.lexer.location())
        }

        var watModule = try parseWAT(&wastParser.parser, features: wastParser.features)

        if let nameAnnot {
            watModule.id = .annotation(nameAnnot)
        }

        try wastParser.parser.skipParenBlock()
        return .text(watModule)
    }
}
