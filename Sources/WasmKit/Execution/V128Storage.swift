import WasmTypes

struct V128Storage: Equatable, Hashable, Sendable {
    var lo: UInt64
    var hi: UInt64

    init(lo: UInt64, hi: UInt64) {
        self.lo = lo
        self.hi = hi
    }

    init(_ value: WasmTypes.V128) {
        precondition(value.bytes.count == WasmTypes.V128.byteCount)
        var lo: UInt64 = 0
        var hi: UInt64 = 0
        for i in 0..<8 {
            lo |= UInt64(value.bytes[i]) << (UInt64(i) * 8)
        }
        for i in 0..<8 {
            hi |= UInt64(value.bytes[8 + i]) << (UInt64(i) * 8)
        }
        self.lo = lo
        self.hi = hi
    }

    var value: WasmTypes.V128 {
        var bytes = [UInt8](repeating: 0, count: WasmTypes.V128.byteCount)
        for i in 0..<8 {
            bytes[i] = UInt8(truncatingIfNeeded: lo >> (UInt64(i) * 8))
        }
        for i in 0..<8 {
            bytes[8 + i] = UInt8(truncatingIfNeeded: hi >> (UInt64(i) * 8))
        }
        return WasmTypes.V128(bytes: bytes)
    }
}

extension WasmTypes.ValueType {
    var stackSlotCount: Int {
        switch self {
        case .v128: return 2
        case .i32, .i64, .f32, .f64, .ref: return 1
        }
    }
}
