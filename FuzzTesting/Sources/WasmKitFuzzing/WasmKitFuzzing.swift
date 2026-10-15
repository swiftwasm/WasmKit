// This module defines utilities for fuzzing WasmKit.

@_spi(Fuzzing) import WasmKit

/// A resource limiter that restricts allocations to fuzzer limits.
public final class FuzzerResourceLimiter: ResourceLimiter {
    public init() {}

    public func limitMemoryGrowth(to desired: Int) throws -> Bool {
        return desired < 1024 * 1024 * 1024
    }
    public func limitTableGrowth(to desired: Int) throws -> Bool {
        return desired < 1024 * 1024
    }
}

/// Check if a Wasm module can be instantiated without crashing.
///
/// - Parameter bytes: The bytes of the Wasm module.
public func fuzzInstantiation(bytes: [UInt8]) throws {
    var module = try WasmKit.parseWasm(bytes: bytes, features: .all)
    // To ensure that the module instantiation will stop eventually.
    module.dropStartFunction()

    let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
    let store = Store(engine: engine)
    store.resourceLimiter = FuzzerResourceLimiter()

    // Prepare dummy imports
    var imports = Imports()
    for importEntry in module.imports {
        let value: ExternalValueConvertible
        switch importEntry.descriptor {
        case .function(let typeIndex):
            guard let type = module.functionType(at: typeIndex) else {
                // Skip if import type index does not name a function type
                return
            }
            value = Function(store: store, type: type) { _, _ in
                // Provide "start function" with empty results
                if type.results.isEmpty { return [] }
                fatalError("Unexpected function call")
            }
        case .global(let globalType):
            value = try Global(store: store, type: globalType, value: .i32(0))
        case .memory(let memoryType):
            value = try Memory(store: store, type: memoryType)
        case .table(let tableType):
            value = try Table(store: store, type: tableType)
        case .tag(let typeIndex):
            guard let type = module.functionType(at: typeIndex) else { return }
            value = Tag(store: store, type: type)
        }
        imports.define(module: importEntry.module, name: importEntry.name, value.externalValue)
    }

    // Instantiate the module
    _ = try module.instantiate(store: store, imports: imports)
}
