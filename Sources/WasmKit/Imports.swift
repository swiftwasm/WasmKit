import struct WasmParser.Import

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
public struct Imports<MemorySpace: GuestMemory> {
    private var definitions: [String: [String: ExternalValue<MemorySpace>]] = [:]

    /// Initializes a new instance of `Imports`.
    public init() {
    }

    /// Define a value to be imported by the given module and name.
    public mutating func define<Extern: ExternalValueConvertible>(module: String, name: String, _ value: Extern<MemorySpace>) {
        definitions[module, default: [:]][name] = value.externalValue
    }

    /// Define a set of values to be imported by the given module.
    /// - Parameters:
    ///   - module: The module name to be used for resolving the imports.
    ///   - values: The values to be imported keyed by their name.
    public mutating func define(module: String, _ values: Exports<MemorySpace>) {
        definitions[module, default: [:]].merge(values.map { ($0, $1) }, uniquingKeysWith: { _, new in new })
    }

    mutating func define(_ importEntry: Import, _ value: ExternalValue<MemorySpace>) {
        define(module: importEntry.module, name: importEntry.name, value)
    }

    /// Lookup a value to be imported by the given module and name.
    func lookup(module: String, name: String) -> (InternalExternalValue, StoreAllocator)? {
        definitions[module]?[name]?.internalize()
    }
}

/// A value that can be imported or exported from an instance.
public protocol ExternalValueConvertible<MemorySpace> {
    associatedtype MemorySpace: GuestMemory
    var externalValue: ExternalValue<MemorySpace> { get }
}

extension ExternalValue: ExternalValueConvertible<MemorySpace> {
    public var externalValue: ExternalValue<MemorySpace> { self }
}

extension Memory: ExternalValueConvertible<MemorySpace> {
    public var externalValue: ExternalValue<MemorySpace> { .memory(self) }
}

extension Table: ExternalValueConvertible<MemorySpace> {
    public var externalValue: ExternalValue<MemorySpace> { .table(self) }
}

extension Global: ExternalValueConvertible<MemorySpace> {
    public var externalValue: ExternalValue<MemorySpace> { .global(self) }
}

extension Function: ExternalValueConvertible<MemorySpace> {
    public var externalValue: ExternalValue<MemorySpace> { .function(self) }
}

extension Imports: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public struct Value: ExpressibleByDictionaryLiteral {
        public typealias Key = String
        public typealias Value = ExternalValueConvertible

        let definitions: [String: ExternalValue<MemorySpace>]

        public init(dictionaryLiteral elements: (String, any Value)...) {
            self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.externalValue) })
        }
    }

    public init(dictionaryLiteral elements: (String, Value)...) {
        self.definitions = Dictionary(uniqueKeysWithValues: elements.map { ($0.0, $0.1.definitions) })
    }
}
