import WasmParser
import WasmTypes

/// The sections of a WebAssembly binary module, as the printer needs them.
///
/// Code, data and element sections stay undecoded until printed. The input
/// stream keeps every byte it reads, so the whole module stays in memory.
package struct ModuleInfo {
    package var types: [FunctionType] = []
    package var imports: [Import] = []
    package var functionTypeIndices: [TypeIndex] = []
    package var tables: [Table] = []
    package var memories: [Memory] = []
    package var globals: [Global] = []
    package var exports: [Export] = []
    package var start: FunctionIndex? = nil
    package var tags: [Tag] = []

    package var codeSection: RawSection? = nil
    package var dataSection: RawSection? = nil
    package var elementSection: RawSection? = nil

    package var dataCount: UInt32? = nil

    package var features: WasmFeatureSet = .default

    // Names from the `name` custom section.
    package var moduleName: String? = nil
    package var functionNames: [UInt32: String] = [:]
    /// Local names by function index, then local index.
    package var localNames: [UInt32: [UInt32: String]] = [:]
    /// Label names by function index, then label index.
    package var labelNames: [UInt32: [UInt32: String]] = [:]
    package var typeNames: [UInt32: String] = [:]
    package var tableNames: [UInt32: String] = [:]
    package var memoryNames: [UInt32: String] = [:]
    package var globalNames: [UInt32: String] = [:]
    package var elementNames: [UInt32: String] = [:]
    package var dataNames: [UInt32: String] = [:]
    package var tagNames: [UInt32: String] = [:]

    package init() {}

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

package func collectModule<Source: ByteStreamSource>(
    stream: Source, features: WasmFeatureSet = .default
) throws(WasmParserError) -> ModuleInfo {
    var info = ModuleInfo()
    info.features = features
    var parser = WasmParser.Parser(stream: stream, features: features)
    while let section = try parser.parseNextRawSection() {
        switch section.kind {
        case .custom:
            let custom = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseCustomSection(size: UInt32(section.body.count))
            }
            if custom.name == "name" {
                parseNameSection(custom.bytes, into: &info)
            }
        case .type:
            info.types = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseTypeSection().map { group throws(WasmParserError) in
                    guard let subType = group.types.first, group.types.count == 1,
                        subType.isFinal, subType.supertypes.isEmpty, case .function(let type) = subType.body
                    else {
                        throw WasmParserError("GC type definitions are not supported")
                    }
                    return type
                }
            }
        case .`import`:
            info.imports = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseImportSection()
            }
        case .function:
            info.functionTypeIndices = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseFunctionSection()
            }
        case .table:
            info.tables = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseTableSection()
            }
        case .memory:
            info.memories = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseMemorySection()
            }
        case .global:
            info.globals = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseGlobalSection()
            }
        case .export:
            info.exports = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseExportSection()
            }
        case .start:
            info.start = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseStartSection()
            }
        case .element:
            info.elementSection = section
        case .code:
            info.codeSection = section
        case .data:
            info.dataSection = section
        case .dataCount:
            // `parseDataCountSection` is internal to WasmParser.
            info.dataCount = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseUnsigned(UInt32.self)
            }
        case .tag:
            info.tags = try section.parse(features: features) { parser throws(WasmParserError) in
                try parser.parseTagSection()
            }
        }
    }
    return info
}

// MARK: - Name section decoding

/// Ignores a malformed name section, as the spec allows for custom sections.
private func parseNameSection(_ bytes: ArraySlice<UInt8>, into info: inout ModuleInfo) {
    var nameParser = NameSectionParser(stream: StaticByteStreamSource(bytes: bytes))
    let parsed: (names: [ParsedNames], tagNames: NameMap)
    do {
        parsed = try nameParser.parseAllIncludingTagNames()
    } catch {
        return
    }
    info.tagNames = parsed.tagNames
    for names in parsed.names {
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
        }
    }
}
