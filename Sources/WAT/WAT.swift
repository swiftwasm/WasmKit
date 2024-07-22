import WasmParser

/// Transforms a WebAssembly text format (WAT) string into a WebAssembly binary format byte array.
/// - Parameter input: The WAT string to transform
/// - Returns: The WebAssembly binary format byte array
///
/// ```swift
/// import WAT
///
/// let wasm = try wat2wasm("""
/// (module
///   (func $add (param i32 i32) (result i32)
///     local.get 0
///     local.get 1
///     i32.add)
///   (export "add" (func $add))
/// )
/// """)
/// ```
public func wat2wasm(_ input: String) throws -> [UInt8] {
    var wat = try parseWAT(input)
    return try encode(module: &wat)
}

/// A WAT module representation.
public struct WatModule {
    var types: TypesMap
    let functionsMap: NameMapping<WatParser.FunctionDecl>
    let tablesMap: NameMapping<WatParser.TableDecl>
    let tables: [Table]
    let memories: NameMapping<WatParser.MemoryDecl>
    let globals: NameMapping<WatParser.GlobalDecl>
    let elementsMap: NameMapping<WatParser.ElementDecl>
    let data: NameMapping<WatParser.DataSegmentDecl>
    let start: FunctionIndex?
    let imports: [Import]
    let exports: [Export]
    let customSections = [CustomSection]()

    let parser: Parser

    static func empty() -> WatModule {
        WatModule(
            types: TypesMap(),
            functionsMap: NameMapping<WatParser.FunctionDecl>(),
            tablesMap: NameMapping<WatParser.TableDecl>(),
            tables: [],
            memories: NameMapping<WatParser.MemoryDecl>(),
            globals: NameMapping<WatParser.GlobalDecl>(),
            elementsMap: NameMapping<WatParser.ElementDecl>(),
            data: NameMapping<WatParser.DataSegmentDecl>(),
            start: nil,
            imports: [],
            exports: [],
            parser: Parser("")
        )
    }

    /// Encodes the module into a WebAssembly binary format byte array.
    ///
    /// - Returns: The WebAssembly binary format byte array
    ///
    /// This method effectively consumes the module value, encoding it into a
    /// binary format byte array. If you need to encode the module multiple times,
    /// you should create a copy of the module value before encoding it.
    public mutating func encode() throws -> [UInt8] {
        try WAT.encode(module: &self)
    }
}

/// Parses a WebAssembly text format (WAT) string into a `WatModule` instance.
/// - Parameter input: The WAT string to parse
/// - Returns: The parsed `WatModule` instance
///
/// The `WatModule` instance can be used to encode the module into a WebAssembly binary format byte array.
///
/// ```swift
/// import WAT
///
/// var wat = try parseWAT("""
/// (module
///   (func $add (param i32 i32) (result i32)
///     local.get 0
///     local.get 1
///     i32.add)
///   (export "add" (func $add))
/// )
/// """)
///
/// let wasm = try wat.encode()
/// ```
public func parseWAT(_ input: String) throws -> WatModule {
    var parser = Parser(input)
    try parser.expect(.leftParen)
    try parser.expectKeyword("module")
    let watModule = try parseWAT(&parser)
    try parser.skipParenBlock()
    return watModule
}

/// A WAST script representation.
public struct Wast {
    var parser: WastParser

    init(_ input: String) {
        self.parser = WastParser(input)
    }

    /// Parses the next directive in the WAST script.
    ///
    /// - Returns: A tuple containing the parsed directive and its location in the WAST script
    ///   or `nil` if there are no more directives to parse.
    public mutating func nextDirective() throws -> (directive: WastDirective, location: Location)? {
        let location = try parser.parser.peek()?.location(in: parser.parser.lexer) ?? parser.parser.lexer.location()
        if let directive = try parser.nextDirective() {
            return (directive, location)
        } else {
            return nil
        }
    }
}

/// Parses a WebAssembly script test format (WAST) string into a `Wast` instance.
///
/// - Parameter input: The WAST string to parse
/// - Returns: The parsed `Wast` instance
///
/// The returned `Wast` instance can be used to iterate over the directives in the WAST script.
///
/// ```swift
/// var wast = try parseWAST("""
/// (module
///   (func $add (param i32 i32) (result i32)
///     local.get 0
///     local.get 1
///     i32.add)
///   (export "add" (func $add))
/// )
/// (assert_return (invoke "add" (i32.const 1) (i32.const 2)) (i32.const 3))
/// """)
///
/// while let (directive, location) = try wast.nextDirective() {
///     print("\(location): \(directive)")
/// }
/// ```
public func parseWAST(_ input: String) throws -> Wast {
    return Wast(input)
}

func parseWAT(_ parser: inout Parser) throws -> WatModule {
    // This parser is 2-pass: first it collects all module items and creates a mapping of names to indices.

    let initialParser = parser

    var importFactories: [() throws -> Import] = []
    var typesMap = TypesMap()
    var functionsMap = NameMapping<WatParser.FunctionDecl>()
    var tablesMap = NameMapping<WatParser.TableDecl>()
    var memoriesMap = NameMapping<WatParser.MemoryDecl>()
    var elementSegmentsMap = NameMapping<WatParser.ElementDecl>()
    var dataSegmentsMap = NameMapping<WatParser.DataSegmentDecl>()
    var globalsMap = NameMapping<WatParser.GlobalDecl>()
    var start: Parser.IndexOrId?

    var exportDecls: [WatParser.ExportDecl] = []

    func visitDecl(decl: WatParser.ModuleField) throws {
        let location = decl.location

        func addExports(_ exports: [String], index: Int, kind: WatParser.ExternalKind) {
            for export in exports {
                exportDecls.append(WatParser.ExportDecl(name: export, id: .index(UInt32(index), location), kind: kind))
            }
        }

        func addImport(_ importNames: WatParser.ImportNames, makeDescriptor: @escaping () throws -> ImportDescriptor) {
            importFactories.append {
                return Import(
                    module: importNames.module, name: importNames.name,
                    descriptor: try makeDescriptor()
                )
            }
        }

        switch decl.kind {
        case let .type(decl):
            typesMap.add(decl)
        case let .function(decl):
            let index = functionsMap.add(decl)
            addExports(decl.exports, index: index, kind: .function)
            switch decl.kind {
            case .definition: break
            case .imported(let importNames):
                addImport(importNames) {
                    let typeIndex = try typesMap.resolveIndex(use: decl.typeUse)
                    return .function(TypeIndex(typeIndex))
                }
            }
        case let .table(decl):
            let index = tablesMap.add(decl)
            addExports(decl.exports, index: index, kind: .table)
            if var inlineElement = decl.inlineElement {
                inlineElement.mode = .active(
                    table: .index(UInt32(index), location), offset: .synthesized(0)
                )
                elementSegmentsMap.add(inlineElement)
            }
            if let importNames = decl.importNames {
                addImport(importNames) { .table(decl.type) }
            }
        case let .memory(decl):
            let index = memoriesMap.add(decl)
            if var inlineData = decl.inlineData {
                // Associate the memory with the inline data
                inlineData.memory = .index(UInt32(index), location)
                inlineData.offset = .synthesized(0)
                dataSegmentsMap.add(inlineData)
            }
            addExports(decl.exports, index: index, kind: .memory)
            if let importNames = decl.importNames {
                addImport(importNames) { .memory(decl.type) }
            }
        case let .global(decl):
            let index = globalsMap.add(decl)
            addExports(decl.exports, index: index, kind: .global)
            switch decl.kind {
            case .definition: break
            case .imported(let importNames):
                addImport(importNames) { .global(decl.type) }
            }
        case let .element(decl):
            elementSegmentsMap.add(decl)
        case let .export(decl):
            exportDecls.append(decl)
        case let .data(decl):
            dataSegmentsMap.add(decl)
        case let .start(startIndex):
            start = startIndex
        }
    }

    // 1. Collect module decls and create name -> index mapping
    var watParser = WatParser(parser: initialParser)
    while let decl = try watParser.next() {
        try visitDecl(decl: decl)
    }

    // 2. Resolve a part of module items that reference other module items.
    // Remaining items like $id references like (call $func) are resolved during encoding.
    let exports: [Export] = try exportDecls.compactMap {
        let descriptor: ExportDescriptor
        switch $0.kind {
        case .function:
            descriptor = try .function(FunctionIndex(functionsMap.resolveIndex(use: $0.id)))
        case .table:
            descriptor = try .table(TableIndex(tablesMap.resolveIndex(use: $0.id)))
        case .memory:
            descriptor = try .memory(MemoryIndex(memoriesMap.resolveIndex(use: $0.id)))
        case .global:
            descriptor = try .global(GlobalIndex(globalsMap.resolveIndex(use: $0.id)))
        }
        return Export(name: $0.name, descriptor: descriptor)
    }

    let imports = try importFactories.map { try $0() }
    let startIndex = try start.map { try FunctionIndex(functionsMap.resolveIndex(use: $0)) }

    parser = watParser.parser

    return WatModule(
        types: typesMap,
        functionsMap: functionsMap,
        tablesMap: tablesMap,
        tables: tablesMap.map {
            Table(type: $0.type)
        },
        memories: memoriesMap,
        globals: globalsMap,
        elementsMap: elementSegmentsMap,
        data: dataSegmentsMap,
        start: startIndex,
        imports: imports,
        exports: exports,
        parser: parser
    )
}
