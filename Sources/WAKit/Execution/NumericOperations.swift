protocol ValueConvertible: Numeric {}

extension Int32: ValueConvertible {}
extension Int64: ValueConvertible {}
extension Int: ValueConvertible {}
extension Float32: ValueConvertible {}
extension Float64: ValueConvertible {}

extension Value {
    var type: ValueType {
        switch self {
        case .i32: return .i32
        case .i64: return .i64
        case .f32: return .f32
        case .f64: return .f64
        }
    }
}

extension ValueType {
    func value<V: ValueConvertible>(_ value: V) -> Value {
        switch (self, value) {
        case let (.i32, v as Int32): return Value.i32(v)
        case let (.i64, v as Int64): return Value.i64(v)
        case let (.i32, v as Int): return Value.i32(Int32(v))
        case let (.i64, v as Int): return Value.i64(Int64(v))
        case let (.f32, v as Float32): return Value.f32(v)
        case let (.f64, v as Float64): return Value.f64(v)
        default: fatalError("Unknown ValueConvertible")
        }
    }
}

extension Value {
    func signed() throws -> Value {
        switch self {
        case let .i32(v):
            if v < 2 << 31 {
                return .i32(v)
            } else {
                return .i32(v - 2 << 32)
            }
        case let .i64(v):
            if v < 2 << 63 {
                return .i64(v)
            } else {
                return .i64(v - 2 << 64)
            }
        default:
            throw ExecutionError.genericError
        }
    }
}

extension Value {
    var isInteger: Bool {
        switch self {
        case .i32, .i64: return true
        case .f32, .f64: return false
        }
    }

    var isFloat: Bool {
        switch self {
        case .i32, .i64: return false
        case .f32, .f64: return true
        }
    }
}

extension ValueType {
    var isInteger: Bool {
        switch self {
        case .i32, .i64: return true
        case .f32, .f64: return false
        }
    }

    var isFloat: Bool {
        switch self {
        case .i32, .i64: return false
        case .f32, .f64: return true
        }
    }
}

extension Value {
    static func < (lhs: Value, rhs: Value) throws -> Bool {
        switch (lhs, rhs) {
        case let (.i32(l), .i32(r)): return l < r
        case let (.i64(l), .i64(r)): return l < r
        case let (.f32(l), .f32(r)): return l < r
        case let (.f64(l), .f64(r)): return l < r
        default: throw ExecutionError.genericError
        }
    }

    static func <= (lhs: Value, rhs: Value) throws -> Bool {
        return try lhs < rhs || lhs == rhs
    }

    static func > (lhs: Value, rhs: Value) throws -> Bool {
        return try !(lhs <= rhs)
    }

    static func >= (lhs: Value, rhs: Value) throws -> Bool {
        return try !(lhs < rhs)
    }
}

extension Value {
    static func + (lhs: Value, rhs: Value) throws -> Value {
        switch (lhs, rhs) {
        case let (.i32(l), .i32(r)): return .i32(l + r)
        case let (.i64(l), .i64(r)): return .i64(l + r)
        case let (.f32(l), .f32(r)): return .f32(l + r)
        case let (.f64(l), .f64(r)): return .f64(l + r)
        default: throw ExecutionError.genericError
        }
    }
}

extension Value {
    func leadingZeroBitCount() throws -> Int {
        switch self {
        case let .i32(v): return v.leadingZeroBitCount
        case let .i64(v): return v.leadingZeroBitCount
        default: throw ExecutionError.genericError
        }
    }

    func trailingZeroBitCount() throws -> Int {
        switch self {
        case let .i32(v): return v.trailingZeroBitCount
        case let .i64(v): return v.trailingZeroBitCount
        default: throw ExecutionError.genericError
        }
    }

    func nonzeroBitCount() throws -> Int {
        switch self {
        case let .i32(v): return v.nonzeroBitCount
        case let .i64(v): return v.nonzeroBitCount
        default: throw ExecutionError.genericError
        }
    }
}
