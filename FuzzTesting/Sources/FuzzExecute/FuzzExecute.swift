@_spi(Fuzzing) import WasmKit
import WasmKitFuzzing

@_cdecl("LLVMFuzzerTestOneInput")
public func FuzzCheck(_ start: UnsafePointer<UInt8>, _ count: Int) -> CInt {
    let bytes = Array(UnsafeBufferPointer(start: start, count: count))
    do {
        let module = try WasmKit.parseWasm(bytes: bytes)
        let engine = WasmKit.Engine()
        let store = WasmKit.Store(engine: engine)
        store.resourceLimiter = FuzzerResourceLimiter()
        let instance = try module.instantiate(store: store)
        for export in instance.exports.values {
            guard case let .function(fn) = export else {
                continue
            }
            let type = fn.type
            let arguments = type.parameters.map { $0.defaultValue }
            _ = try fn(arguments)
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
        case .v128:
            return .v128(V128(bytes: Array(repeating: 0, count: V128.byteCount)))
        case .ref(let referenceType):
            switch referenceType.heapType {
            case .abstract(.funcRef):
                return .ref(.function(nil))
            case .abstract(.externRef):
                return .ref(.extern(nil))
            case .concrete:
                // We don't model GC reference heap types yet; use a null externref.
                return .ref(.extern(nil))
            }
        }
    }
}
