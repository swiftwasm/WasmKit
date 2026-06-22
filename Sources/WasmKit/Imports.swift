import struct WasmParserCore.Import

/// A set of entities used to import values when instantiating a module.
///
/// An `Imports` instance is used to define values that are imported by a
/// WebAssembly module. The values can be functions, memories, tables, or globals.
/// The imported values are defined by their module and name.
///
/// The following example demonstrates how to import a function from the host environment
/// and call it from a WebAssembly module:
///
/// ```swift
/// let imports: Imports = [
///     "printer": [
///         "print_i32": Function(store: store, parameters: [.i32]) { _, args in
///             // This function is called from "print_add" in the WebAssembly module.
///             print(args[0])
///             return []
///         }
///     ]
/// ]
///
/// let instance = try module.instantiate(store: store, imports: imports)
/// ```
public struct Imports {
    #if !$Embedded
    private var definitions: [String: [String: ExternalValue]] = [:]
    #else
    // Embedded Swift: use a flat array instead of nested dictionaries.
    // Dictionary<String,...> uses String.hashValue which pulls in Unicode NFC
    // normalization tables (~31 KB rodata).  Linear search with UTF-8 byte
    // comparison is sufficient for the small number of WASM imports.
    private var embeddedEntries: [(module: String, name: String, value: ExternalValue)] = []
    #endif

    /// Initializes a new instance of `Imports`.
    public init() {
    }

    /// Define a value to be imported by the given module and name.
    public mutating func define<Extern: ExternalValueConvertible>(module: String, name: String, _ value: Extern) {
        #if !$Embedded
        definitions[module, default: [:]][name] = value.externalValue
        #else
        embeddedEntries.append((module: module, name: name, value: value.externalValue))
        #endif
    }

    /// Define a set of values to be imported by the given module.
    /// - Parameters:
    ///   - module: The module name to be used for resolving the imports.
    ///   - values: The values to be imported keyed by their name.
    #if !$Embedded
    public mutating func define(module: String, _ values: Exports) {
        definitions[module, default: [:]].merge(values.map { ($0, $1) }, uniquingKeysWith: { _, new in new })
    }
    #endif

    mutating func define(_ importEntry: Import, _ value: ExternalValue) {
        define(module: importEntry.module, name: importEntry.name, value)
    }

    /// Lookup a value to be imported by the given module and name.
    func lookup(module: String, name: String) -> (InternalExternalValue, StoreAllocator)? {
        #if !$Embedded
        return definitions[module]?[name]?.internalize()
        #else
        // Byte-by-byte UTF-8 comparison avoids String.hashValue and
        // String.== which transitively require Unicode NFC normalization.
        let mBytes = module.utf8
        let nBytes = name.utf8
        for entry in embeddedEntries {
            guard entry.module.utf8.count == mBytes.count,
                  entry.name.utf8.count == nBytes.count else { continue }
            guard entry.module.utf8.elementsEqual(mBytes) else { continue }
            guard entry.name.utf8.elementsEqual(nBytes) else { continue }
            return entry.value.internalize()
        }
        return nil
        #endif
    }
}

/// A value that can be imported or exported from an instance.
public protocol ExternalValueConvertible {
    var externalValue: ExternalValue { get }
}

extension ExternalValue: ExternalValueConvertible {
    public var externalValue: ExternalValue { self }
}

extension Memory: ExternalValueConvertible {
    public var externalValue: ExternalValue { .memory(self) }
}

extension Table: ExternalValueConvertible {
    public var externalValue: ExternalValue { .table(self) }
}

extension Global: ExternalValueConvertible {
    public var externalValue: ExternalValue { .global(self) }
}

extension Function: ExternalValueConvertible {
    public var externalValue: ExternalValue { .function(self) }
}

extension Tag: ExternalValueConvertible {
    public var externalValue: ExternalValue { .tag(self) }
}

#if !$Embedded
extension Imports: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    #if !$Embedded
    public struct Value: ExpressibleByDictionaryLiteral {
        public typealias Key = String
        public typealias Value = ExternalValueConvertible

        let definitions: [String: ExternalValue]

        public init(dictionaryLiteral elements: (String, any Value)...) {
            self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.externalValue) })
        }
    }
    #else
    public struct Value: ExpressibleByDictionaryLiteral {
        public typealias Key = String
        public typealias Value = ExternalValue

        let definitions: [String: ExternalValue]

        public init(dictionaryLiteral elements: (String, ExternalValue)...) {
            self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1) })
        }
    }
    #endif

    public init(dictionaryLiteral elements: (String, Value)...) {
        self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.definitions) })
    }
}
#endif  // !$Embedded
