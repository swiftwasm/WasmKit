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

    /// Define a set of values to be imported by the given module.
    /// - Parameters:
    ///   - module: The module name to be used for resolving the imports.
    ///   - values: The values to be imported keyed by their name.
    public mutating func define(module: String, _ values: Instance.Exports) {
        definitions[module, default: [:]].merge(values, uniquingKeysWith: { _, new in new })
    }

    mutating func define(_ importEntry: Import, _ value: ExternalValue) {
        define(module: importEntry.module, name: importEntry.name, value)
    }

    /// Lookup a value to be imported by the given module and name.
    func lookup(module: String, name: String) -> (InternalExternalValue, StoreAllocator)? {
        definitions[module]?[name]?.internalize()
    }
}

/// A value that can be imported or exported from an instance.
public protocol ExternalValueConvertible {
    var externalValue: ExternalValue { get }
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

extension Imports: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public struct Value: ExpressibleByDictionaryLiteral {
        public typealias Key = String
        public typealias Value = ExternalValueConvertible

        let definitions: [String: ExternalValue]

        public init(dictionaryLiteral elements: (String, any Value)...) {
            self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.externalValue) })
        }
    }

    public init(dictionaryLiteral elements: (String, Value)...) {
        self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.definitions) })
    }
}
