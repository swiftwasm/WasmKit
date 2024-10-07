import WasmCAPI
import WasmKit
import WAT
import SystemPackage
import Foundation

protocol Engine {
    func run(moduleBytes: [UInt8]) throws -> ExecResult
}

struct ExecResult {
    let values: [Value]?
    let trap: String?
    let memory: [UInt8]?

    var hasTrap: Bool {
        return trap != nil
    }

    static func check(_ lhs: ExecResult, _ rhs: ExecResult) -> Bool {
        guard lhs.hasTrap == rhs.hasTrap else {
            print("Traps do not match: \(lhs.trap ?? "nil") vs \(rhs.trap ?? "nil")")
            return false
        }
        guard lhs.memory == rhs.memory else {
            guard lhs.memory?.count == rhs.memory?.count else {
                print("Memory sizes do not match: \(lhs.memory?.count ?? 0) vs \(rhs.memory?.count ?? 0)")
                return false
            }
            for (i, (lhsByte, rhsByte)) in zip(lhs.memory ?? [], rhs.memory ?? []).enumerated() {
                if lhsByte != rhsByte {
                    print("Memory byte \(i) does not match: \(lhsByte) vs \(rhsByte)")
                }
            }
            return false
        }
        guard lhs.values?.count == rhs.values?.count else {
            print("Value counts do not match: \(lhs.values?.count ?? 0) vs \(rhs.values?.count ?? 0)")
            return false
        }
        for (i, (lhsValue, rhsValue)) in zip(lhs.values ?? [], rhs.values ?? []).enumerated() {
            if !Value.bitwiseEqual(lhsValue, rhsValue) {
                print("Value \(i) does not match: \(lhsValue) vs \(rhsValue)")
                return false
            }
        }
        return true
    }
}

struct ExecError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}

extension ValueType {
    var defaultValue: Value {
        switch self {
        case .i32: return .i32(0)
        case .i64: return .i64(0)
        case .f32: return .f32(0)
        case .f64: return .f64(0)
        case .ref(.funcRef): return .ref(.function(0))
        case .ref(.externRef): return .ref(.extern(0))
        }
    }
}

extension Value {
    static func bitwiseEqual(_ lhs: Value, _ rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs == rhs
        case let (.i64(lhs), .i64(rhs)): return lhs == rhs
        case let (.f32(lhs), .f32(rhs)): return lhs == rhs
        case let (.f64(lhs), .f64(rhs)): return lhs == rhs
        case let (.ref(lhs), .ref(rhs)): return lhs == rhs
        default: return false
        }
    }
}

extension wasm_name_t {
    var string: String {
        return data.withMemoryRebound(to: UInt8.self, capacity: Int(size)) {
            String(decoding: UnsafeBufferPointer(start: $0, count: Int(size)), as: UTF8.self)
        }
    }
}

struct WasmKitEngine: Engine {
    func run(moduleBytes: [UInt8]) throws -> ExecResult {
        let module = try WasmKit.parseWasm(bytes: moduleBytes)
        let engine = WasmKit.Engine()
        let store = WasmKit.Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let exports = instance.exports.sorted(by: { $0.name < $1.name })
        let memories: [Memory] = exports.compactMap {
            guard case let .memory(memory) = $0.value else {
                return nil
            }
            return memory
        }
        guard memories.count <= 1 else {
            throw ExecError("Multiple memories are not supported")
        }
        let memory = memories.first
        let funcs: [Function] = exports.compactMap {
            guard case let .function(fn) = $0.value else {
                return nil
            }
            return fn
        }
        guard let fn = funcs.first else {
            throw ExecError("No functions found")
        }
        let type = fn.type
        let arguments = type.parameters.map { $0.defaultValue }
        do {
            let results = try fn(arguments)
            return ExecResult(values: results, trap: nil, memory: memory?.data)
        } catch {
            return ExecResult(values: nil, trap: String(describing: error), memory: memory?.data)
        }
    }
}

struct ReferenceEngine: Engine {
    func run(moduleBytes: [UInt8]) throws -> ExecResult {
        return try moduleBytes.withUnsafeBytes { (module: UnsafeRawBufferPointer) -> ExecResult in
            try run(module: module)
        }
    }

    func run(module: UnsafeRawBufferPointer) throws -> ExecResult {
        let engine = WasmCAPI.wasm_engine_new()
        let store = WasmCAPI.wasm_store_new(engine)
        var bytes = WasmCAPI.wasm_byte_vec_t()
        wasm_byte_vec_new(&bytes, module.count, module.baseAddress)
        defer { wasm_byte_vec_delete(&bytes) }

        guard let module = WasmCAPI.wasm_module_new(store, &bytes) else {
            throw ExecError("Failed to create module")
        }
        defer { WasmCAPI.wasm_module_delete(module) }

        var rawExportTypes = WasmCAPI.wasm_exporttype_vec_t()
        WasmCAPI.wasm_module_exports(module, &rawExportTypes)
        defer { WasmCAPI.wasm_exporttype_vec_delete(&rawExportTypes) }

        var imports = WasmCAPI.wasm_extern_vec_t()

        guard let instance = WasmCAPI.wasm_instance_new(store, module, &imports, nil) else {
            throw ExecError("Failed to create instance")
        }
        defer { WasmCAPI.wasm_instance_delete(instance) }

        var rawExports = WasmCAPI.wasm_extern_vec_t()
        WasmCAPI.wasm_instance_exports(instance, &rawExports)
        defer { WasmCAPI.wasm_extern_vec_delete(&rawExports) }

        var memory: OpaquePointer?
        var fn: OpaquePointer?

        let exportTypes = UnsafeBufferPointer(start: rawExportTypes.data, count: Int(rawExportTypes.size))
        let exports = UnsafeBufferPointer(start: rawExports.data, count: Int(rawExports.size))
        func compareExportIndices(lhs: (OpaquePointer?, OpaquePointer?), rhs: (OpaquePointer?, OpaquePointer?)) -> Bool {
            let name1 = WasmCAPI.wasm_exporttype_name(lhs.0).pointee.string
            let name2 = WasmCAPI.wasm_exporttype_name(rhs.0).pointee.string
            return name1 < name2
        }
        let sortedExports: [OpaquePointer?] = zip(exportTypes, exports).sorted(by: compareExportIndices).map { $0.1 }
        for export in sortedExports {
            let kind = WasmCAPI.wasm_extern_kind(export)
            switch wasm_externkind_enum(rawValue: UInt32(kind)) {
            case WASM_EXTERN_FUNC:
                guard fn == nil else { continue }
                fn = WasmCAPI.wasm_extern_as_func(export)
            case WASM_EXTERN_MEMORY:
                guard memory == nil else { continue }
                memory = WasmCAPI.wasm_extern_as_memory(export)
            default:
                break
            }
        }

        guard let fn = fn else {
            throw ExecError("No functions found")
        }
        let type = WasmCAPI.wasm_func_type(fn)
        let paramTypes = WasmCAPI.wasm_functype_params(type)
        let resultTypes = WasmCAPI.wasm_functype_results(type)
        var arguments = WasmCAPI.wasm_val_vec_t()
        WasmCAPI.wasm_val_vec_new_uninitialized(&arguments, Int(paramTypes?.pointee.size ?? 0))
        defer { WasmCAPI.wasm_val_vec_delete(&arguments) }
        for i in 0..<Int(paramTypes?.pointee.size ?? 0) {
            let kind = wasm_valtype_kind(paramTypes?.pointee.data[i])
            var value = WasmCAPI.wasm_val_t()
            value.kind = kind
            switch wasm_valkind_enum(rawValue: UInt32(kind)) {
            case WASM_I32: value.of.i32 = 0
            case WASM_I64: value.of.i64 = 0
            case WASM_F32: value.of.f32 = 0
            case WASM_F64: value.of.f64 = 0
            case WASM_FUNCREF: value.of.ref = nil
            case WASM_EXTERNREF: value.of.ref = nil
            default:
                throw ExecError("Unsupported value type")
            }
            arguments.data[i] = value
        }
        var results = WasmCAPI.wasm_val_vec_t()
        WasmCAPI.wasm_val_vec_new_uninitialized(&results, Int(resultTypes?.pointee.size ?? 0))

        let trap = WasmCAPI.wasm_func_call(fn, &arguments, &results)
        let memoryData = memory.flatMap { memory in
            let size = WasmCAPI.wasm_memory_data_size(memory)
            let data = WasmCAPI.wasm_memory_data(memory)
            return data?.withMemoryRebound(to: UInt8.self, capacity: Int(size)) {
                Array(UnsafeBufferPointer(start: $0, count: Int(size)))
            }
        }
        if let trap = trap {
            var message = WasmCAPI.wasm_message_t()
            WasmCAPI.wasm_trap_message(trap, &message)
            return ExecResult(values: nil, trap: message.string, memory: memoryData)
        }

        let numberOfResults = Int(resultTypes?.pointee.size ?? 0)
        let values = try (0..<numberOfResults).map { (index) -> Value in
            let kind = wasm_valtype_kind(resultTypes?.pointee.data[index])
            let value = results.data[index]
            switch wasm_valkind_enum(rawValue: UInt32(kind)) {
            case WASM_I32: return .i32(UInt32(bitPattern: value.of.i32))
            case WASM_I64: return .i64(UInt64(bitPattern: value.of.i64))
            case WASM_F32: return .f32(value.of.f32.bitPattern)
            case WASM_F64: return .f64(value.of.f64.bitPattern)
            default:
                throw ExecError("Unsupported value type: \(kind)")
            }
        }
        return ExecResult(values: values, trap: nil, memory: memoryData)
    }
}

@main struct Main {
    static func main() {
        let shrinking = ProcessInfo.processInfo.environment["SHRINKING"] == "1"
        let ok = _main()
        if shrinking {
            // While shrinking, failure is "interesting" and reducer expects non-zero exit code
            // for interesting cases.
            exit(ok ? 1 : 0)
        }
        exit(ok ? 0 : 1)
    }
    static func _main() -> Bool {
        do {
            return try run(moduleFile: CommandLine.arguments[1])
        } catch {
            // Ignore errors
            return true
        }
    }

    static func run(moduleFile: String) throws -> Bool {
        let engines: [Engine] = [
            WasmKitEngine(),
            ReferenceEngine()
        ]
        let moduleBytes: [UInt8]
        if moduleFile.hasSuffix(".wat") {
            moduleBytes = try wat2wasm(String(contentsOf: URL(fileURLWithPath: moduleFile)))
        } else {
            moduleBytes = try Array(Data(contentsOf: URL(fileURLWithPath: moduleFile)))
        }
        let results = try engines.map { try $0.run(moduleBytes: moduleBytes) }
        guard results.count > 1 else {
            throw ExecError("Expected at least two engines")
        }
        return results.dropFirst().allSatisfy({ ExecResult.check(results[0], $0) })
    }
}
