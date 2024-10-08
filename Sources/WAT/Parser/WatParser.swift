import WasmParser
import WasmTypes

struct WatParser {
    var parser: Parser

    init(parser: Parser) {
        self.parser = parser
    }

    struct ModuleField {
        let location: Location
        let kind: ModuleFieldKind
    }

    struct ImportNames {
        let module: String
        let name: String
    }

    enum FunctionKind {
        case definition(locals: [LocalDecl], body: Lexer)
        case imported(ImportNames)
    }

    enum GlobalKind {
        case definition(expr: Lexer)
        case imported(ImportNames)
    }

    enum ExternalKind {
        case function
        case table
        case memory
        case global
    }

    struct Parameter: Equatable {
        let id: String?
        let type: ValueType
    }

    struct FunctionType {
        let signature: WasmTypes.FunctionType
        /// Names of the parameters. The number of names must match the number of parameters in `type`.
        let parameterNames: [Name?]
    }

    /// Represents a type use in a function signature.
    /// Note that a type use can have both an index and an inline type at the same time.
    /// In that case, we need to use the information to validate their consistency later.
    struct TypeUse {
        /// The index of the type in the type section specified by `(type ...)`.
        let index: Parser.IndexOrId?
        /// The inline type specified by `(param ...) (result ...)`.
        let inline: FunctionType?
        /// The source location of the type use.
        let location: Location
    }

    struct LocalDecl: NamedModuleFieldDecl {
        var id: Name?
        var type: ValueType
    }

    struct FunctionDecl: NamedModuleFieldDecl, ImportableModuleFieldDecl {
        var id: Name?
        var exports: [String]
        var typeUse: TypeUse
        var kind: FunctionKind

        var importNames: WatParser.ImportNames? {
            switch kind {
            case .definition: return nil
            case .imported(let importNames): return importNames
            }
        }

        /// Parse the function and call corresponding visit methods of the given visitor
        /// This method may modify TypesMap of the given WATModule
        ///
        /// - Returns: Type index of this function
        func parse<V: InstructionVisitor>(visitor: inout V, wat: inout Wat, features: WasmFeatureSet) throws -> Int {
            guard case let .definition(locals, body) = kind else {
                fatalError("Imported functions cannot be parsed")
            }
            let (type, typeIndex) = try wat.types.resolve(use: typeUse)
            var parser = try ExpressionParser<V>(type: type, locals: locals, lexer: body, features: features)
            try parser.parse(visitor: &visitor, wat: &wat)
            // Check if the parser has reached the end of the function body
            guard try parser.parser.isEndOfParen() else {
                throw WatParserError("unexpected token", location: parser.parser.lexer.location())
            }
            return typeIndex
        }
    }

    struct FunctionTypeDecl: NamedModuleFieldDecl {
        let id: Name?
        let type: FunctionType
    }

    struct TableDecl: NamedModuleFieldDecl, ImportableModuleFieldDecl {
        var id: Name?
        var exports: [String]
        var type: TableType
        var importNames: ImportNames?
        var inlineElement: ElementDecl?
    }

    struct ElementDecl: NamedModuleFieldDecl {
        enum Offset {
            case expression(Lexer)
            case singleInstruction(Lexer)
            case synthesized(Int)
        }
        enum Mode {
            case active(table: Parser.IndexOrId?, offset: Offset)
            case declarative
            case passive
            case inline
        }

        enum Indices {
            case functionList(Lexer)
            case elementExprList(Lexer)
        }

        var id: Name?
        var mode: Mode
        var type: ReferenceType
        var indices: Indices
    }

    struct ExportDecl {
        var name: String
        var id: Parser.IndexOrId
        var kind: ExternalKind
    }

    struct GlobalDecl: NamedModuleFieldDecl, ImportableModuleFieldDecl {
        var id: Name?
        var exports: [String]
        var type: GlobalType
        var kind: GlobalKind

        var importNames: WatParser.ImportNames? {
            switch kind {
            case .definition: return nil
            case .imported(let importNames): return importNames
            }
        }
    }

    struct MemoryDecl: NamedModuleFieldDecl, ImportableModuleFieldDecl {
        var id: Name?
        var exports: [String]
        var type: MemoryType
        var importNames: ImportNames?
        var inlineData: DataSegmentDecl?
    }

    struct DataSegmentDecl: NamedModuleFieldDecl {
        var id: Name?
        var memory: Parser.IndexOrId?
        enum Offset {
            case source(Lexer)
            case synthesized(Int)
        }
        var offset: Offset?
        var data: [UInt8]
    }

    enum ModuleFieldKind {
        case type(FunctionTypeDecl)
        case function(FunctionDecl)
        case table(TableDecl)
        case memory(MemoryDecl)
        case global(GlobalDecl)
        case export(ExportDecl)
        case start(id: Parser.IndexOrId)
        case element(ElementDecl)
        case data(DataSegmentDecl)
    }

    mutating func next() throws -> ModuleField? {
        // If we have reached the end of the (module ...) block, return nil
        guard try !parser.isEndOfParen() else { return nil }
        try parser.expect(.leftParen)
        let location = parser.lexer.location()
        let keyword = try parser.expectKeyword()

        let kind: ModuleFieldKind
        switch keyword {
        case "type":
            let id = try parser.takeId()
            let functionType = try funcType()
            kind = .type(FunctionTypeDecl(id: id, type: functionType))
            try parser.expect(.rightParen)
        case "import":
            let importNames = try importNames()
            if try parser.takeParenBlockStart("func") {
                let id = try parser.takeId()
                kind = .function(FunctionDecl(id: id, exports: [], typeUse: try typeUse(mayHaveName: true), kind: .imported(importNames)))
            } else if try parser.takeParenBlockStart("table") {
                let id = try parser.takeId()
                kind = .table(TableDecl(id: id, exports: [], type: try tableType(), importNames: importNames))
            } else if try parser.takeParenBlockStart("memory") {
                let id = try parser.takeId()
                kind = .memory(MemoryDecl(id: id, exports: [], type: try memoryType(), importNames: importNames))
            } else if try parser.takeParenBlockStart("global") {
                let id = try parser.takeId()
                kind = .global(GlobalDecl(id: id, exports: [], type: try globalType(), kind: .imported(importNames)))
            } else {
                throw WatParserError("unexpected token", location: parser.lexer.location())
            }
            try parser.expect(.rightParen)  // closing paren for import description
            try parser.expect(.rightParen)  // closing paren for import
        case "func":
            let id = try parser.takeId()
            let exports = try inlineExports()
            let importNames = try inlineImport()
            let typeUse = try typeUse(mayHaveName: true)
            let functionKind: FunctionKind
            if let importNames = importNames {
                functionKind = .imported(importNames)
            } else {
                let locals = try self.locals()
                functionKind = .definition(locals: locals, body: parser.lexer)
            }
            kind = .function(FunctionDecl(id: id, exports: exports, typeUse: typeUse, kind: functionKind))
            try parser.skipParenBlock()
        case "table":
            let id = try parser.takeId()
            let exports = try inlineExports()
            let importNames = try inlineImport()
            let type: TableType
            var inlineElement: ElementDecl?
            let isMemory64 = try expectAddressSpaceType()

            if let refType = try maybeRefType() {
                guard try parser.takeParenBlockStart("elem") else {
                    throw WatParserError("expected elem", location: parser.lexer.location())
                }
                var numberOfItems: UInt64 = 0
                let indices: ElementDecl.Indices
                if try parser.peek(.leftParen) != nil {
                    // elemexpr ::= '(' 'item' expr ')' | '(' instr ')'
                    indices = .elementExprList(parser.lexer)
                    while try parser.take(.leftParen) {
                        numberOfItems += 1
                        try parser.skipParenBlock()
                    }
                } else {
                    // Consume function indices
                    indices = .functionList(parser.lexer)
                    while try parser.takeIndexOrId() != nil {
                        numberOfItems += 1
                    }
                }
                inlineElement = ElementDecl(
                    mode: .inline, type: refType, indices: indices
                )
                try parser.expect(.rightParen)
                type = TableType(
                    elementType: refType,
                    limits: Limits(
                        min: numberOfItems,
                        max: numberOfItems,
                        isMemory64: isMemory64
                    )
                )
            } else {
                type = try tableType(isMemory64: isMemory64)
            }
            kind = .table(
                TableDecl(
                    id: id, exports: exports, type: type, importNames: importNames, inlineElement: inlineElement
                ))
            try parser.expect(.rightParen)
        case "memory":
            let WASM_PAGE_SIZE: Int = 65536
            func alignUp(_ offset: Int, to align: Int) -> Int {
                let mask = align &- 1
                return (offset &+ mask) & ~mask
            }
            let id = try parser.takeId()
            let exports = try inlineExports()
            let importNames = try inlineImport()

            let isMemory64 = try expectAddressSpaceType()
            let type: MemoryType
            var data: DataSegmentDecl?
            if try parser.takeParenBlockStart("data") {
                let dataBytes = try dataString()
                data = DataSegmentDecl(data: dataBytes)
                // Align up to page size
                let byteSize = alignUp(dataBytes.count, to: WASM_PAGE_SIZE)
                let numberOfPages = byteSize / WASM_PAGE_SIZE
                type = MemoryType(min: UInt64(numberOfPages), max: UInt64(numberOfPages), isMemory64: isMemory64, shared: false)
                try parser.expect(.rightParen)
            } else {
                type = try memoryType(isMemory64: isMemory64)
            }
            kind = .memory(MemoryDecl(id: id, exports: exports, type: type, importNames: importNames, inlineData: data))
            try parser.expect(.rightParen)
        case "global":
            let id = try parser.takeId()
            let exports = try inlineExports()
            let importNames = try inlineImport()
            let type = try globalType()
            let globalKind: GlobalKind
            if let importNames {
                globalKind = .imported(importNames)
                try parser.expect(.rightParen)
            } else {
                globalKind = .definition(expr: parser.lexer)
                try parser.skipParenBlock()
            }
            kind = .global(GlobalDecl(id: id, exports: exports, type: type, kind: globalKind))
        case "export":
            let name = try parser.expectString()
            let decl: ExportDecl
            if try parser.takeParenBlockStart("func") {
                let index = try parser.expectIndexOrId()
                try parser.expect(.rightParen)
                decl = ExportDecl(name: name, id: index, kind: .function)
            } else if try parser.takeParenBlockStart("table") {
                let index = try parser.expectIndexOrId()
                try parser.expect(.rightParen)
                decl = ExportDecl(name: name, id: index, kind: .table)
            } else if try parser.takeParenBlockStart("memory") {
                let index = try parser.expectIndexOrId()
                try parser.expect(.rightParen)
                decl = ExportDecl(name: name, id: index, kind: .memory)
            } else if try parser.takeParenBlockStart("global") {
                let index = try parser.expectIndexOrId()
                try parser.expect(.rightParen)
                decl = ExportDecl(name: name, id: index, kind: .global)
            } else {
                throw WatParserError("unexpected token", location: parser.lexer.location())
            }
            kind = .export(decl)
            try parser.expect(.rightParen)
        case "start":
            let index = try parser.expectIndexOrId()
            kind = .start(id: index)
            try parser.expect(.rightParen)
        case "elem":
            let id = try parser.takeId()
            var table: Parser.IndexOrId?
            let mode: ElementDecl.Mode
            if try parser.takeKeyword("declare") {
                mode = .declarative
            } else {
                table = try tableUse()
                if try parser.takeParenBlockStart("offset") {
                    mode = .active(table: table, offset: .expression(parser.lexer))
                    try parser.skipParenBlock()
                } else {
                    if try parser.peek(.leftParen) != nil {
                        // abbreviated offset instruction
                        mode = .active(table: table, offset: .singleInstruction(parser.lexer))
                        try parser.consume()  // consume (
                        try parser.skipParenBlock()  // skip offset expr
                    } else {
                        mode = .passive
                    }
                }
            }

            // elemlist ::= reftype elemexpr* | 'func' funcidx*
            //            | funcidx* (iff the tableuse is omitted)
            let indices: ElementDecl.Indices
            let type: ReferenceType
            if let refType = try maybeRefType() {
                indices = .elementExprList(parser.lexer)
                type = refType
            } else if try parser.takeKeyword("func") || table == nil {
                indices = .functionList(parser.lexer)
                type = .funcRef
            } else {
                throw WatParserError("expected element list", location: parser.lexer.location())
            }

            try parser.skipParenBlock()
            kind = .element(ElementDecl(id: id, mode: mode, type: type, indices: indices))
        case "data":
            let id = try parser.takeId()
            let memory = try memoryUse()
            var offset: DataSegmentDecl.Offset?
            if try parser.takeParenBlockStart("offset") {
                offset = .source(parser.lexer)
                try parser.skipParenBlock()
            } else if try parser.peek(.leftParen) != nil {
                try parser.consume()  // consume (
                offset = .source(parser.lexer)
                try parser.skipParenBlock()  // skip offset expr
            }
            let data = try dataString()
            kind = .data(DataSegmentDecl(id: id, memory: memory, offset: offset, data: data))
            try parser.expect(.rightParen)
        default:
            throw WatParserError("unexpected module field \(keyword)", location: location)
        }
        return ModuleField(location: location, kind: kind)
    }

    mutating func locals() throws -> [LocalDecl] {
        var decls: [LocalDecl] = []
        while try parser.takeParenBlockStart("local") {
            if let id = try parser.takeId() {
                let type = try valueType()
                try parser.expect(.rightParen)
                decls.append(LocalDecl(id: id, type: type))
            } else {
                while try !parser.take(.rightParen) {
                    let type = try valueType()
                    decls.append(LocalDecl(type: type))
                }
            }
        }
        return decls
    }

    mutating func inlineExports() throws -> [String] {
        var exports: [String] = []
        while try parser.takeParenBlockStart("export") {
            let name = try parser.expectString()
            try parser.expect(.rightParen)
            exports.append(name)
        }
        return exports
    }

    mutating func inlineImport() throws -> ImportNames? {
        guard try parser.takeParenBlockStart("import") else { return nil }
        let names = try importNames()
        try parser.expect(.rightParen)
        return names
    }

    mutating func importNames() throws -> ImportNames {
        let module = try parser.expectString()
        let name = try parser.expectString()
        return ImportNames(module: module, name: name)
    }

    mutating func typeUse(mayHaveName: Bool) throws -> TypeUse {
        let location = parser.lexer.location()
        var index: Parser.IndexOrId?
        if try parser.takeParenBlockStart("type") {
            index = try parser.expectIndexOrId()
            try parser.expect(.rightParen)
        }
        let inline = try optionalFunctionType(mayHaveName: mayHaveName)
        return TypeUse(index: index, inline: inline, location: location)
    }

    mutating func tableUse() throws -> Parser.IndexOrId? {
        var index: Parser.IndexOrId?
        if try parser.takeParenBlockStart("table") {
            index = try parser.expectIndexOrId()
            try parser.expect(.rightParen)
        }
        return index
    }

    mutating func memoryUse() throws -> Parser.IndexOrId? {
        var index: Parser.IndexOrId?
        if try parser.takeParenBlockStart("memory") {
            index = try parser.expectIndexOrId()
            try parser.expect(.rightParen)
        }
        return index
    }

    mutating func dataString() throws -> [UInt8] {
        var data: [UInt8] = []
        while let bytes = try parser.takeStringBytes() {
            data.append(contentsOf: bytes)
        }
        return data
    }

    /// Expect "i32", "i64", or any other
    /// - Returns: `true` if "i64", otherwise `false`
    mutating func expectAddressSpaceType() throws -> Bool {
        let isMemory64: Bool
        if try parser.takeKeyword("i64") {
            isMemory64 = true
        } else {
            _ = try parser.takeKeyword("i32")
            isMemory64 = false
        }
        return isMemory64
    }

    mutating func tableType() throws -> TableType {
        return try tableType(isMemory64: expectAddressSpaceType())
    }

    mutating func tableType(isMemory64: Bool) throws -> TableType {
        let limits: Limits
        if isMemory64 {
            limits = try limit64()
        } else {
            limits = try limit32()
        }
        let elementType = try refType()
        return TableType(elementType: elementType, limits: limits)
    }

    mutating func memoryType() throws -> MemoryType {
        return try memoryType(isMemory64: expectAddressSpaceType())
    }

    mutating func memoryType(isMemory64: Bool) throws -> MemoryType {
        let limits: Limits
        if isMemory64 {
            limits = try limit64()
        } else {
            limits = try limit32()
        }
        let shared = try parser.takeKeyword("shared")
        return Limits(min: limits.min, max: limits.max, isMemory64: limits.isMemory64, shared: shared)
    }

    /// globaltype ::= t:valtype | '(' 'mut' t:valtype ')'
    mutating func globalType() throws -> GlobalType {
        let mutability: Mutability
        if try parser.takeParenBlockStart("mut") {
            mutability = .variable
        } else {
            mutability = .constant
        }
        let valueType = try valueType()
        if mutability == .variable {
            try parser.expect(.rightParen)
        }
        return GlobalType(mutability: mutability, valueType: valueType)
    }

    mutating func limit32() throws -> Limits {
        let min = try parser.expectUnsignedInt(UInt32.self)
        let max: UInt32? = try parser.takeUnsignedInt(UInt32.self)
        return Limits(min: UInt64(min), max: max.map(UInt64.init), isMemory64: false)
    }

    mutating func limit64() throws -> Limits {
        let min = try parser.expectUnsignedInt(UInt64.self)
        let max: UInt64? = try parser.takeUnsignedInt(UInt64.self)
        return Limits(min: min, max: max, isMemory64: true)
    }

    /// functype ::= '(' 'func' t1*:vec(param) t2*:vec(result) ')' => [t1*] -> [t2*]
    mutating func funcType() throws -> FunctionType {
        try parser.expect(.leftParen)
        try parser.expectKeyword("func")
        let (params, names) = try params(mayHaveName: true)
        let results = try results()
        try parser.expect(.rightParen)
        return FunctionType(signature: WasmTypes.FunctionType(parameters: params, results: results), parameterNames: names)
    }

    mutating func optionalFunctionType(mayHaveName: Bool) throws -> FunctionType? {
        let (params, names) = try params(mayHaveName: mayHaveName)
        let results = try results()
        if results.isEmpty, params.isEmpty {
            return nil
        }
        return FunctionType(signature: WasmTypes.FunctionType(parameters: params, results: results), parameterNames: names)
    }

    mutating func params(mayHaveName: Bool) throws -> ([ValueType], [Name?]) {
        var types: [ValueType] = []
        var names: [Name?] = []
        while try parser.takeParenBlockStart("param") {
            if mayHaveName {
                if let id = try parser.takeId() {
                    let valueType = try valueType()
                    types.append(valueType)
                    names.append(id)
                    try parser.expect(.rightParen)
                    continue
                }
            }
            while try !parser.take(.rightParen) {
                let valueType = try valueType()
                types.append(valueType)
                names.append(nil)
            }
        }
        return (types, names)
    }

    mutating func results() throws -> [ValueType] {
        var results: [ValueType] = []
        while try parser.takeParenBlockStart("result") {
            while try !parser.take(.rightParen) {
                let valueType = try valueType()
                results.append(valueType)
            }
        }
        return results
    }

    mutating func valueType() throws -> ValueType {
        let keyword = try parser.expectKeyword()
        switch keyword {
        case "i32": return .i32
        case "i64": return .i64
        case "f32": return .f32
        case "f64": return .f64
        default:
            if let refType = refType(keyword: keyword) { return .ref(refType) }
            throw WatParserError("unexpected value type \(keyword)", location: parser.lexer.location())
        }
    }

    mutating func refType(keyword: String) -> ReferenceType? {
        switch keyword {
        case "funcref": return .funcRef
        case "externref": return .externRef
        default: return nil
        }
    }

    mutating func refType() throws -> ReferenceType {
        let keyword = try parser.expectKeyword()
        guard let refType = refType(keyword: keyword) else {
            throw WatParserError("unexpected ref type \(keyword)", location: parser.lexer.location())
        }
        return refType
    }

    mutating func maybeRefType() throws -> ReferenceType? {
        if try parser.takeKeyword("funcref") {
            return .funcRef
        } else if try parser.takeKeyword("externref") {
            return .externRef
        }
        return nil
    }
}
