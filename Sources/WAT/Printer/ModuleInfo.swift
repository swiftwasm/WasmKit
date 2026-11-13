import WasmParser
import WasmTypes

/// The sections of a WebAssembly binary module, as the printer needs them.
///
/// Function bodies stay undecoded until printed.
struct ModuleInfo {
    var types: [FunctionType] = []
    var imports: [Import] = []
    var functionTypeIndices: [TypeIndex] = []
    var tables: [Table] = []
    var memories: [Memory] = []
    var globals: [Global] = []
    var exports: [Export] = []
    var start: FunctionIndex? = nil
    var tags: [Tag] = []

    var codes: [Code] = []
    var elements: [ElementSegment] = []
    var dataSegments: [DataSegment] = []

    var dataCount: UInt32? = nil

    var features: WasmFeatureSet = .default

    // Names from the `name` custom section.
    var moduleName: String? = nil
    var functionNames: [UInt32: String] = [:]
    /// Local names by function index, then local index.
    var localNames: [UInt32: [UInt32: String]] = [:]
    /// Label names by function index, then label index.
    var labelNames: [UInt32: [UInt32: String]] = [:]
    var typeNames: [UInt32: String] = [:]
    var tableNames: [UInt32: String] = [:]
    var memoryNames: [UInt32: String] = [:]
    var globalNames: [UInt32: String] = [:]
    var elementNames: [UInt32: String] = [:]
    var dataNames: [UInt32: String] = [:]
    var tagNames: [UInt32: String] = [:]

    init() {}

    struct ImportCounts {
        var functions = 0
        var tables = 0
        var memories = 0
        var globals = 0
        var tags = 0
    }

    var importCounts: ImportCounts {
        var counts = ImportCounts()
        for entry in imports {
            switch entry.descriptor {
            case .function: counts.functions += 1
            case .table: counts.tables += 1
            case .memory: counts.memories += 1
            case .global: counts.globals += 1
            case .tag: counts.tags += 1
            }
        }
        return counts
    }
}

func collectModule<Source: ByteStreamSource>(
    stream: Source, features: WasmFeatureSet = .default
) throws(WasmParserError) -> ModuleInfo {
    var info = ModuleInfo()
    info.features = features
    var parser = WasmParser.Parser(stream: stream, features: features)
    while let payload = try parser.parseNext() {
        switch payload {
        case .header: break
        case .customSection(let custom):
            if custom.name == "name" {
                parseNameSection(custom.bytes, into: &info)
            }
        case .typeSection(let groups):
            info.types = try groups.map { group throws(WasmParserError) in
                guard let subType = group.types.first, group.types.count == 1,
                    subType.isFinal, subType.supertypes.isEmpty, case .function(let type) = subType.body
                else {
                    throw WasmParserError("GC type definitions are not supported")
                }
                return type
            }
        case .importSection(let imports): info.imports = imports
        case .functionSection(let typeIndices): info.functionTypeIndices = typeIndices
        case .tableSection(let tables): info.tables = tables
        case .memorySection(let memories): info.memories = memories
        case .globalSection(let globals): info.globals = globals
        case .tagSection(let tags): info.tags = tags
        case .exportSection(let exports): info.exports = exports
        case .startSection(let start): info.start = start
        case .elementSection(let elements): info.elements = elements
        case .codeSection(let codes): info.codes = codes
        case .dataSection(let dataSegments): info.dataSegments = dataSegments
        case .dataCount(let count): info.dataCount = count
        }
    }
    return info
}

// MARK: - Name section decoding

/// Ignores a malformed name section, as the spec allows for custom sections.
private func parseNameSection(_ bytes: ArraySlice<UInt8>, into info: inout ModuleInfo) {
    var nameParser = NameSectionParser(stream: StaticByteStreamSource(bytes: bytes))
    let parsed: [ParsedNames]
    do {
        parsed = try nameParser.parseAll()
    } catch {
        return
    }
    for names in parsed {
        switch names {
        case .moduleName(let name): info.moduleName = name
        case .functions(let map): info.functionNames = map
        case .locals(let map): info.localNames = map
        case .labels(let map): info.labelNames = map
        case .types(let map): info.typeNames = map
        case .tables(let map): info.tableNames = map
        case .memories(let map): info.memoryNames = map
        case .globals(let map): info.globalNames = map
        case .elements(let map): info.elementNames = map
        case .dataSegments(let map): info.dataNames = map
        case .tags(let map): info.tagNames = map
        }
    }
}
