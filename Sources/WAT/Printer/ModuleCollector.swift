import WasmParser
import WasmTypes

/// Collected information from all sections of a WebAssembly binary module.
///
/// "Big" sections (code, data, element) are captured as raw byte slices and
/// streamed during emit. "Small" sections (type, import, function, table,
/// memory, global, export, start, tag, dataCount) are eagerly materialised
/// because their entries are bounded.
package struct ModuleInfo {
    package var types: [FunctionType] = []
    package var imports: [Import] = []
    /// Type indices from the function section (one per local function).
    package var functionTypeIndices: [TypeIndex] = []
    package var tables: [Table] = []
    package var memories: [Memory] = []
    package var globals: [Global] = []
    package var exports: [Export] = []
    package var start: FunctionIndex? = nil
    /// Tags from the EH proposal's tag section.
    package var tags: [Tag] = []

    /// Raw byte slices for the big sections; sub-parsed during emit.
    package var codeSectionBytes: ArraySlice<UInt8>? = nil
    package var dataSectionBytes: ArraySlice<UInt8>? = nil
    package var elementSectionBytes: ArraySlice<UInt8>? = nil

    /// DataCount value (when the data-count section is present); validated
    /// against the data section's actual segment count during emit.
    package var dataCount: UInt32? = nil

    /// Threaded so the per-section sub-parsers in WatPrinter use the same
    /// feature set as the original parse.
    package var features: WasmFeatureSet = .default

    // Names from the `name` custom section (all 10 ParsedNames cases).
    package var moduleName: String? = nil
    /// Function names (index → name).
    package var functionNames: [UInt32: String] = [:]
    /// Local variable names (function index → (local index → name)).
    package var localNames: [UInt32: [UInt32: String]] = [:]
    /// Label names per-function (function index → (label index → name)).
    package var labelNames: [UInt32: [UInt32: String]] = [:]
    package var typeNames: [UInt32: String] = [:]
    package var tableNames: [UInt32: String] = [:]
    package var memoryNames: [UInt32: String] = [:]
    package var globalNames: [UInt32: String] = [:]
    package var elementNames: [UInt32: String] = [:]
    package var dataNames: [UInt32: String] = [:]

    package init() {}

    /// Total number of functions (imports + local definitions).
    package var functionCount: Int {
        let importedFunctions = imports.filter {
            if case .function = $0.descriptor { return true }
            return false
        }.count
        return importedFunctions + functionTypeIndices.count
    }

    /// Number of imported functions (occupy the first N function indices).
    package var importedFunctionCount: Int {
        imports.filter {
            if case .function = $0.descriptor { return true }
            return false
        }.count
    }
}

/// Parses a WebAssembly binary and collects all sections into a `ModuleInfo`.
/// Big sections (code, data, element) are captured as raw slices and parsed
/// later during emit; small sections are sub-parsed eagerly.
package func collectModule<Stream: ByteStream>(stream: Stream, features: WasmFeatureSet = .default) throws -> ModuleInfo {
    var info = ModuleInfo()
    info.features = features
    var parser = WasmParser.Parser(stream: stream, features: features)
    while let section = try parser.parseNextRawSection() {
        // Exhaustive switch over RawSection.Kind: adding a new section kind
        // forces an update here at compile time.
        switch section.kind {
        case .custom:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            let custom = try sub.parseCustomSection(size: UInt32(section.body.count))
            try assertFullyConsumed(sub, kind: .custom)
            if custom.name == "name" {
                parseNameSection(custom.bytes, into: &info)
            }
        case .type:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.types = try sub.parseTypeSection()
            try assertFullyConsumed(sub, kind: .type)
        case .`import`:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.imports = try sub.parseImportSection()
            try assertFullyConsumed(sub, kind: .`import`)
        case .function:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.functionTypeIndices = try sub.parseFunctionSection()
            try assertFullyConsumed(sub, kind: .function)
        case .table:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.tables = try sub.parseTableSection()
            try assertFullyConsumed(sub, kind: .table)
        case .memory:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.memories = try sub.parseMemorySection()
            try assertFullyConsumed(sub, kind: .memory)
        case .global:
            var sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.globals = try sub.parseGlobalSection()
            try assertFullyConsumed(sub, kind: .global)
        case .export:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.exports = try sub.parseExportSection()
            try assertFullyConsumed(sub, kind: .export)
        case .start:
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.start = try sub.parseStartSection()
            try assertFullyConsumed(sub, kind: .start)
        case .element:
            info.elementSectionBytes = section.body
        case .code:
            info.codeSectionBytes = section.body
        case .data:
            info.dataSectionBytes = section.body
        case .dataCount:
            // Body is a single u32 LEB128; inline rather than widen
            // `parseDataCountSection`.
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.dataCount = try sub.parseUnsigned()
            try assertFullyConsumed(sub, kind: .dataCount)
        case .tag:
            // Gating on `.exceptionHandling` happens in `parseNextRawSection`,
            // so reaching this branch implies the feature is enabled.
            let sub = WasmParser.Parser(sectionBodyBytes: section.body, features: features)
            info.tags = try sub.parseTagSection()
            try assertFullyConsumed(sub, kind: .tag)
        }
    }
    return info
}

/// Verifies a sub-parser consumed exactly the section body it was handed.
/// Throws a `sectionSizeMismatch`-shaped error if extra bytes remain.
func assertFullyConsumed(_ sub: WasmParser.Parser<StaticByteStream>, kind: RawSection.Kind) throws(WasmParserError) {
    guard try sub.hasReachedEnd() else {
        throw WasmParserError(
            "section \(kind) (id \(kind.rawValue)) declared size larger than parsed body"
        )
    }
}

// MARK: - Name section decoding

/// Reads the name custom section into `info`, extracting all 10
/// `ParsedNames` cases. The Wasm spec treats custom sections, including
/// the name section, as advisory: a malformed name section is silently
/// ignored so the rest of the module still round-trips.
private func parseNameSection(_ bytes: ArraySlice<UInt8>, into info: inout ModuleInfo) {
    let stream = StaticByteStream(bytes: bytes)
    let nameParser = NameSectionParser(stream: stream)
    let parsedNames: [ParsedNames]
    do {
        parsedNames = try nameParser.parseAll()
    } catch {
        return
    }
    for parsed in parsedNames {
        switch parsed {
        case .moduleName(let name):    info.moduleName = name
        case .functions(let map):      info.functionNames = map
        case .locals(let map):         info.localNames = map
        case .labels(let map):         info.labelNames = map
        case .types(let map):          info.typeNames = map
        case .tables(let map):         info.tableNames = map
        case .memories(let map):       info.memoryNames = map
        case .globals(let map):        info.globalNames = map
        case .elements(let map):       info.elementNames = map
        case .dataSegments(let map):   info.dataNames = map
        }
    }
}
