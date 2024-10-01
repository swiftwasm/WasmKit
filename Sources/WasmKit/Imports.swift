import struct WasmParser.Import

/// A set of entities used to import values when instantiating a module.
public struct Imports {
    private var definitions: [String: [String: ExternalValue]] = [:]

    /// Initializes a new instance of `Imports`.
    public init() {
    }

    /// Define a value to be imported by the given module and name.
    public mutating func define(module: String, name: String, _ value: ExternalValue) {
        definitions[module, default: [:]][name] = value
    }

    mutating func define(_ importEntry: Import, _ value: ExternalValue) {
        define(module: importEntry.module, name: importEntry.name, value)
    }

    /// Lookup a value to be imported by the given module and name.
    func lookup(module: String, name: String) -> (InternalExternalValue, StoreAllocator)? {
        definitions[module]?[name]?.internalize()
    }
}

extension Imports: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = [String: ExternalValue]

    public init(dictionaryLiteral elements: (String, [String: ExternalValue])...) {
        self.definitions = Dictionary(uniqueKeysWithValues: elements)
    }
}
