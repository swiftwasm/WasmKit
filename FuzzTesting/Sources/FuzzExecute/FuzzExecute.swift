@_spi(Fuzzing) import WasmKit

struct FuzzerResourceLimiter: ResourceLimiter {
    func limitMemoryGrowth(to desired: Int) throws -> Bool {
        return desired < 1024 * 1024 * 1024
    }
    func limitTableGrowth(to desired: Int) throws -> Bool {
        return desired < 1024 * 1024
    }
}

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let bytes = Array(UnsafeBufferPointer(start: start, count: count))
    do {
        var module = try WasmKit.parseWasm(bytes: bytes)
        let runtime = WasmKit.Runtime()
        runtime.store.resourceLimiter = FuzzerResourceLimiter()
        let instance = try runtime.instantiate(module: module)
        for (name, export) in instance.exports {
            guard case let .function(fn) = export else {
                continue
            }
            let type = fn.type
            let arguments = type.parameters.map { $0.defaultValue }
            _ = try fn.invoke(arguments, runtime: runtime)
        }
    } catch {
        // Ignore errors
    }
    return 0
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
