import WasmParser
import WasmTypes

/// Collected information from all sections of a WebAssembly binary module.
struct ModuleInfo {
    var types: [FunctionType] = []
    var imports: [Import] = []
    /// Type indices from the function section (one per local function).
    var functionTypeIndices: [TypeIndex] = []
    var tables: [Table] = []
    var memories: [Memory] = []
    var globals: [Global] = []
    var exports: [Export] = []
    var start: FunctionIndex? = nil
    var elements: [ElementSegment] = []
    /// Code bodies for local functions (parallel to functionTypeIndices).
    var codes: [Code] = []
    var data: [DataSegment] = []
    /// Function names from the `name` custom section (index → name).
    var functionNames: [UInt32: String] = [:]
    /// Local variable names from the `name` custom section
    /// (function index → (local index → name)).
    var localNames: [UInt32: [UInt32: String]] = [:]

    /// Total number of functions (imports + local definitions).
    var functionCount: Int {
        let importedFunctions = imports.filter {
            if case .function = $0.descriptor { return true }
            return false
        }.count
        return importedFunctions + functionTypeIndices.count
    }

    /// Number of imported functions (occupy the first N function indices).
    var importedFunctionCount: Int {
        imports.filter {
            if case .function = $0.descriptor { return true }
            return false
        }.count
    }
}

/// Parses a WebAssembly binary and collects all sections into a `ModuleInfo`.
///
/// - Parameters:
///   - bytes: The raw bytes of the WebAssembly binary.
///   - features: The feature set to use while parsing.
/// - Returns: A populated `ModuleInfo`.
func collectModule<Stream: ByteStream>(stream: Stream, features: WasmFeatureSet = .default) throws -> ModuleInfo {
    var info = ModuleInfo()
    var parser = WasmParser.Parser(stream: stream, features: features)
    while let payload = try parser.parseNext() {
        switch payload {
        case .header:
            break
        case .typeSection(let types):
            info.types = types
        case .importSection(let imports):
            info.imports = imports
        case .functionSection(let indices):
            info.functionTypeIndices = indices
        case .tableSection(let tables):
            info.tables = tables
        case .memorySection(let memories):
            info.memories = memories
        case .globalSection(let globals):
            info.globals = globals
        case .exportSection(let exports):
            info.exports = exports
        case .startSection(let start):
            info.start = start
        case .elementSection(let elements):
            info.elements = elements
        case .codeSection(let codes):
            info.codes = codes
        case .dataSection(let data):
            info.data = data
        case .dataCount:
            break
        case .customSection(let section) where section.name == "name":
            parseNameSection(section.bytes, into: &info)
        case .customSection:
            break
        }
    }
    return info
}

// MARK: - Name section decoding

private func parseNameSection(_ bytes: ArraySlice<UInt8>, into info: inout ModuleInfo) {
    let stream = StaticByteStream(bytes: bytes)
    let nameParser = NameSectionParser(stream: stream)
    guard let parsedNames = try? nameParser.parseAll() else { return }
    for parsedName in parsedNames {
        if case .functions(let nameMap) = parsedName {
            info.functionNames = nameMap
        }
    }
}
