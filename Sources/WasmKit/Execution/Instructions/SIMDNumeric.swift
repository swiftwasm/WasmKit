import WasmTypes

private func saturatingAddSigned<T: FixedWidthInteger>(_ a: T, _ b: T) -> T {
    let (res, overflow) = a.addingReportingOverflow(b)
    guard overflow else { return res }
    return b.signum() >= 0 ? T.max : T.min
}

private func saturatingSubSigned<T: FixedWidthInteger>(_ a: T, _ b: T) -> T {
    let (res, overflow) = a.subtractingReportingOverflow(b)
    guard overflow else { return res }
    return b.signum() >= 0 ? T.min : T.max
}

private func saturatingAddUnsigned<T: FixedWidthInteger & UnsignedInteger>(_ a: T, _ b: T) -> T {
    let (res, overflow) = a.addingReportingOverflow(b)
    return overflow ? T.max : res
}

private func saturatingSubUnsigned<T: FixedWidthInteger & UnsignedInteger>(_ a: T, _ b: T) -> T {
    let (res, overflow) = a.subtractingReportingOverflow(b)
    return overflow ? T.min : res
}

private func pmin<T: BinaryFloatingPoint>(_ a: T, _ b: T) -> T {
    // SIMD spec: defined as `b < a ? b : a`.
    b < a ? b : a
}

private func pmax<T: BinaryFloatingPoint>(_ a: T, _ b: T) -> T {
    // SIMD spec: defined as `a < b ? b : a`.
    a < b ? b : a
}

extension Execution {
    mutating func simdExecuteNumeric(
        opcode: SIMDOpcode,
        sp: Sp,
        immediate: Instruction.SimdOperand
    ) throws -> Bool {
        @inline(__always)
        func v128Unary(_ body: (V128Storage) throws -> V128Storage) rethrows {
            let v0 = sp.loadV128(at: immediate.input0)
            sp.storeV128(try body(v0), at: immediate.result)
        }

        @inline(__always)
        func v128Binary(_ body: (V128Storage, V128Storage) throws -> V128Storage) rethrows {
            let lhs = sp.loadV128(at: immediate.input0)
            let rhs = sp.loadV128(at: immediate.input1)
            sp.storeV128(try body(lhs, rhs), at: immediate.result)
        }

        @inline(__always)
        func v128Ternary(_ body: (V128Storage, V128Storage, V128Storage) throws -> V128Storage) rethrows {
            let a = sp.loadV128(at: immediate.input0)
            let b = sp.loadV128(at: immediate.input1)
            let c = sp.loadV128(at: immediate.input2)
            sp.storeV128(try body(a, b, c), at: immediate.result)
        }

        @inline(__always)
        func storeI32(_ value: UInt32) { sp[immediate.result] = UntypedValue.i32(value) }

        switch opcode {
        case .v128Not:
            v128Unary { .init(lo: ~$0.lo, hi: ~$0.hi) }
            return true
        case .v128And:
            v128Binary { .init(lo: $0.lo & $1.lo, hi: $0.hi & $1.hi) }
            return true
        case .v128Andnot:
            v128Binary { .init(lo: $0.lo & ~$1.lo, hi: $0.hi & ~$1.hi) }
            return true
        case .v128Or:
            v128Binary { .init(lo: $0.lo | $1.lo, hi: $0.hi | $1.hi) }
            return true
        case .v128Xor:
            v128Binary { .init(lo: $0.lo ^ $1.lo, hi: $0.hi ^ $1.hi) }
            return true
        case .v128Bitselect:
            v128Ternary { a, b, mask in
                .init(
                    lo: (a.lo & mask.lo) | (b.lo & ~mask.lo),
                    hi: (a.hi & mask.hi) | (b.hi & ~mask.hi)
                )
            }
            return true

        case .v128AnyTrue:
            let v = sp.loadV128(at: immediate.input0)
            storeI32((v.lo | v.hi) == 0 ? 0 : 1)
            return true

        case .i8x16AllTrue:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 8, laneCount: 16)
            storeI32(lanes.contains(0) ? 0 : 1)
            return true
        case .i16x8AllTrue:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 16, laneCount: 8)
            storeI32(lanes.contains(0) ? 0 : 1)
            return true
        case .i32x4AllTrue:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 32, laneCount: 4)
            storeI32(lanes.contains(0) ? 0 : 1)
            return true
        case .i64x2AllTrue:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 64, laneCount: 2)
            storeI32(lanes.contains(0) ? 0 : 1)
            return true

        case .i8x16Bitmask:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 8, laneCount: 16)
            var mask: UInt32 = 0
            for i in 0..<16 { mask |= UInt32((lanes[i] >> 7) & 1) << UInt32(i) }
            storeI32(mask)
            return true
        case .i16x8Bitmask:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 16, laneCount: 8)
            var mask: UInt32 = 0
            for i in 0..<8 { mask |= UInt32((lanes[i] >> 15) & 1) << UInt32(i) }
            storeI32(mask)
            return true
        case .i32x4Bitmask:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 32, laneCount: 4)
            var mask: UInt32 = 0
            for i in 0..<4 { mask |= UInt32((lanes[i] >> 31) & 1) << UInt32(i) }
            storeI32(mask)
            return true
        case .i64x2Bitmask:
            let v = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(v, widthBits: 64, laneCount: 2)
            var mask: UInt32 = 0
            for i in 0..<2 { mask |= UInt32((lanes[i] >> 63) & 1) << UInt32(i) }
            storeI32(mask)
            return true

        case .i8x16Swizzle:
            v128Binary { lhs, rhs in
                let lhsBytes = V128Lanes.extract(lhs, widthBits: 8, laneCount: 16)
                let rhsBytes = V128Lanes.extract(rhs, widthBits: 8, laneCount: 16)
                var out: [UInt64] = []
                out.reserveCapacity(16)
                for i in 0..<16 {
                    let idx = Int(rhsBytes[i])
                    out.append(idx < 16 ? lhsBytes[idx] : 0)
                }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true

        case .i8x16Splat:
            let scalar = UInt8(truncatingIfNeeded: sp[immediate.input0].i32)
            sp.storeV128(V128Lanes.pack([UInt64](repeating: UInt64(scalar), count: 16), widthBits: 8, laneCount: 16), at: immediate.result)
            return true
        case .i16x8Splat:
            let scalar = UInt16(truncatingIfNeeded: sp[immediate.input0].i32)
            sp.storeV128(V128Lanes.pack([UInt64](repeating: UInt64(scalar), count: 8), widthBits: 16, laneCount: 8), at: immediate.result)
            return true
        case .i32x4Splat:
            let scalar = sp[immediate.input0].i32
            sp.storeV128(V128Lanes.pack([UInt64](repeating: UInt64(scalar), count: 4), widthBits: 32, laneCount: 4), at: immediate.result)
            return true
        case .i64x2Splat:
            let scalar = sp[immediate.input0].i64
            sp.storeV128(V128Storage(lo: scalar, hi: scalar), at: immediate.result)
            return true
        case .f32x4Splat:
            let scalar = sp[immediate.input0].rawF32
            sp.storeV128(V128Lanes.pack([UInt64](repeating: UInt64(scalar), count: 4), widthBits: 32, laneCount: 4), at: immediate.result)
            return true
        case .f64x2Splat:
            let scalar = sp[immediate.input0].rawF64
            sp.storeV128(V128Storage(lo: scalar, hi: scalar), at: immediate.result)
            return true

        case .i8x16Eq, .i8x16Ne, .i8x16LtS, .i8x16LtU, .i8x16GtS, .i8x16GtU, .i8x16LeS, .i8x16LeU, .i8x16GeS, .i8x16GeU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 8, laneCount: 16)
                let b = V128Lanes.extract(rhs, widthBits: 8, laneCount: 16)
                var out: [UInt64] = []
                out.reserveCapacity(16)
                for i in 0..<16 {
                    let aU = UInt8(truncatingIfNeeded: a[i])
                    let bU = UInt8(truncatingIfNeeded: b[i])
                    let aS = Int8(bitPattern: aU)
                    let bS = Int8(bitPattern: bU)
                    let cond: Bool
                    switch opcode {
                    case .i8x16Eq: cond = aU == bU
                    case .i8x16Ne: cond = aU != bU
                    case .i8x16LtS: cond = aS < bS
                    case .i8x16LtU: cond = aU < bU
                    case .i8x16GtS: cond = aS > bS
                    case .i8x16GtU: cond = aU > bU
                    case .i8x16LeS: cond = aS <= bS
                    case .i8x16LeU: cond = aU <= bU
                    case .i8x16GeS: cond = aS >= bS
                    case .i8x16GeU: cond = aU >= bU
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 8, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true

        case .i16x8Eq, .i16x8Ne, .i16x8LtS, .i16x8LtU, .i16x8GtS, .i16x8GtU, .i16x8LeS, .i16x8LeU, .i16x8GeS, .i16x8GeU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let aU = UInt16(truncatingIfNeeded: a[i])
                    let bU = UInt16(truncatingIfNeeded: b[i])
                    let aS = Int16(bitPattern: aU)
                    let bS = Int16(bitPattern: bU)
                    let cond: Bool
                    switch opcode {
                    case .i16x8Eq: cond = aU == bU
                    case .i16x8Ne: cond = aU != bU
                    case .i16x8LtS: cond = aS < bS
                    case .i16x8LtU: cond = aU < bU
                    case .i16x8GtS: cond = aS > bS
                    case .i16x8GtU: cond = aU > bU
                    case .i16x8LeS: cond = aS <= bS
                    case .i16x8LeU: cond = aU <= bU
                    case .i16x8GeS: cond = aS >= bS
                    case .i16x8GeU: cond = aU >= bU
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 16, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4Eq, .i32x4Ne, .i32x4LtS, .i32x4LtU, .i32x4GtS, .i32x4GtU, .i32x4LeS, .i32x4LeU, .i32x4GeS, .i32x4GeU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let aU = UInt32(truncatingIfNeeded: a[i])
                    let bU = UInt32(truncatingIfNeeded: b[i])
                    let aS = Int32(bitPattern: aU)
                    let bS = Int32(bitPattern: bU)
                    let cond: Bool
                    switch opcode {
                    case .i32x4Eq: cond = aU == bU
                    case .i32x4Ne: cond = aU != bU
                    case .i32x4LtS: cond = aS < bS
                    case .i32x4LtU: cond = aU < bU
                    case .i32x4GtS: cond = aS > bS
                    case .i32x4GtU: cond = aU > bU
                    case .i32x4LeS: cond = aS <= bS
                    case .i32x4LeU: cond = aU <= bU
                    case .i32x4GeS: cond = aS >= bS
                    case .i32x4GeU: cond = aU >= bU
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 32, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i64x2Eq, .i64x2Ne, .i64x2LtS, .i64x2GtS, .i64x2LeS, .i64x2GeS:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 64, laneCount: 2)
                let b = V128Lanes.extract(rhs, widthBits: 64, laneCount: 2)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let aU = a[i]
                    let bU = b[i]
                    let aS = Int64(bitPattern: aU)
                    let bS = Int64(bitPattern: bU)
                    let cond: Bool
                    switch opcode {
                    case .i64x2Eq: cond = aU == bU
                    case .i64x2Ne: cond = aU != bU
                    case .i64x2LtS: cond = aS < bS
                    case .i64x2GtS: cond = aS > bS
                    case .i64x2LeS: cond = aS <= bS
                    case .i64x2GeS: cond = aS >= bS
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 64, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .f32x4Eq, .f32x4Ne, .f32x4Lt, .f32x4Gt, .f32x4Le, .f32x4Ge:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let fa = Float32(bitPattern: UInt32(truncatingIfNeeded: a[i]))
                    let fb = Float32(bitPattern: UInt32(truncatingIfNeeded: b[i]))
                    let cond: Bool
                    switch opcode {
                    case .f32x4Eq: cond = fa == fb
                    case .f32x4Ne: cond = fa != fb
                    case .f32x4Lt: cond = fa < fb
                    case .f32x4Gt: cond = fa > fb
                    case .f32x4Le: cond = fa <= fb
                    case .f32x4Ge: cond = fa >= fb
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 32, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f64x2Eq, .f64x2Ne, .f64x2Lt, .f64x2Gt, .f64x2Le, .f64x2Ge:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 64, laneCount: 2)
                let b = V128Lanes.extract(rhs, widthBits: 64, laneCount: 2)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let fa = Float64(bitPattern: a[i])
                    let fb = Float64(bitPattern: b[i])
                    let cond: Bool
                    switch opcode {
                    case .f64x2Eq: cond = fa == fb
                    case .f64x2Ne: cond = fa != fb
                    case .f64x2Lt: cond = fa < fb
                    case .f64x2Gt: cond = fa > fb
                    case .f64x2Le: cond = fa <= fb
                    case .f64x2Ge: cond = fa >= fb
                    default: cond = false
                    }
                    out.append(V128Lanes.boolMask(widthBits: 64, truth: cond))
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i8x16Abs:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 8, laneCount: 16)
                var out: [UInt64] = []
                out.reserveCapacity(16)
                for x in a {
                    let v = Int8(bitPattern: UInt8(truncatingIfNeeded: x))
                    let y = v == .min ? v : Swift.abs(v)
                    out.append(UInt64(UInt8(bitPattern: y)))
                }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true
        case .i8x16Neg:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 8, laneCount: 16)
                let out = a.map { UInt64(UInt8(bitPattern: 0 &- Int8(bitPattern: UInt8(truncatingIfNeeded: $0)))) }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true

        case .i16x8Abs:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for x in a {
                    let v = Int16(bitPattern: UInt16(truncatingIfNeeded: x))
                    let y = v == .min ? v : Swift.abs(v)
                    out.append(UInt64(UInt16(bitPattern: y)))
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true
        case .i16x8Neg:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 16, laneCount: 8)
                let out = a.map { UInt64(UInt16(bitPattern: 0 &- Int16(bitPattern: UInt16(truncatingIfNeeded: $0)))) }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4Abs:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for x in a {
                    let v = Int32(bitPattern: UInt32(truncatingIfNeeded: x))
                    let y = v == .min ? v : Swift.abs(v)
                    out.append(UInt64(UInt32(bitPattern: y)))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true
        case .i32x4Neg:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let out = a.map { UInt64(UInt32(bitPattern: 0 &- Int32(bitPattern: UInt32(truncatingIfNeeded: $0)))) }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i64x2Abs:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 64, laneCount: 2)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for x in a {
                    let v = Int64(bitPattern: x)
                    let y = v == .min ? v : Swift.abs(v)
                    out.append(UInt64(bitPattern: y))
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true
        case .i64x2Neg:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 64, laneCount: 2)
                let out = a.map { UInt64(bitPattern: 0 &- Int64(bitPattern: $0)) }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i8x16Add, .i8x16Sub, .i8x16AddSatS, .i8x16AddSatU, .i8x16SubSatS, .i8x16SubSatU,
            .i8x16MinS, .i8x16MinU, .i8x16MaxS, .i8x16MaxU, .i8x16AvgrU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 8, laneCount: 16)
                let b = V128Lanes.extract(rhs, widthBits: 8, laneCount: 16)
                var out: [UInt64] = []
                out.reserveCapacity(16)
                for i in 0..<16 {
                    let aU = UInt8(truncatingIfNeeded: a[i])
                    let bU = UInt8(truncatingIfNeeded: b[i])
                    let value: UInt8
                    switch opcode {
                    case .i8x16Add: value = aU &+ bU
                    case .i8x16Sub: value = aU &- bU
                    case .i8x16AddSatS:
                        value = UInt8(bitPattern: saturatingAddSigned(Int8(bitPattern: aU), Int8(bitPattern: bU)))
                    case .i8x16AddSatU:
                        value = saturatingAddUnsigned(aU, bU)
                    case .i8x16SubSatS:
                        value = UInt8(bitPattern: saturatingSubSigned(Int8(bitPattern: aU), Int8(bitPattern: bU)))
                    case .i8x16SubSatU:
                        value = saturatingSubUnsigned(aU, bU)
                    case .i8x16MinS:
                        value = UInt8(bitPattern: Swift.min(Int8(bitPattern: aU), Int8(bitPattern: bU)))
                    case .i8x16MinU:
                        value = Swift.min(aU, bU)
                    case .i8x16MaxS:
                        value = UInt8(bitPattern: Swift.max(Int8(bitPattern: aU), Int8(bitPattern: bU)))
                    case .i8x16MaxU:
                        value = Swift.max(aU, bU)
                    case .i8x16AvgrU:
                        value = UInt8(((UInt16(aU) + UInt16(bU) + 1) >> 1) & 0xFF)
                    default:
                        value = 0
                    }
                    out.append(UInt64(value))
                }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true

        case .i16x8Add, .i16x8Sub, .i16x8Mul, .i16x8AddSatS, .i16x8AddSatU, .i16x8SubSatS, .i16x8SubSatU,
            .i16x8MinS, .i16x8MinU, .i16x8MaxS, .i16x8MaxU, .i16x8AvgrU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let aU = UInt16(truncatingIfNeeded: a[i])
                    let bU = UInt16(truncatingIfNeeded: b[i])
                    let value: UInt16
                    switch opcode {
                    case .i16x8Add: value = aU &+ bU
                    case .i16x8Sub: value = aU &- bU
                    case .i16x8Mul: value = UInt16(truncatingIfNeeded: UInt32(aU) * UInt32(bU))
                    case .i16x8AddSatS:
                        value = UInt16(bitPattern: saturatingAddSigned(Int16(bitPattern: aU), Int16(bitPattern: bU)))
                    case .i16x8AddSatU:
                        value = saturatingAddUnsigned(aU, bU)
                    case .i16x8SubSatS:
                        value = UInt16(bitPattern: saturatingSubSigned(Int16(bitPattern: aU), Int16(bitPattern: bU)))
                    case .i16x8SubSatU:
                        value = saturatingSubUnsigned(aU, bU)
                    case .i16x8MinS:
                        value = UInt16(bitPattern: Swift.min(Int16(bitPattern: aU), Int16(bitPattern: bU)))
                    case .i16x8MinU:
                        value = Swift.min(aU, bU)
                    case .i16x8MaxS:
                        value = UInt16(bitPattern: Swift.max(Int16(bitPattern: aU), Int16(bitPattern: bU)))
                    case .i16x8MaxU:
                        value = Swift.max(aU, bU)
                    case .i16x8AvgrU:
                        value = UInt16(((UInt32(aU) + UInt32(bU) + 1) >> 1) & 0xFFFF)
                    default:
                        value = 0
                    }
                    out.append(UInt64(value))
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4Add, .i32x4Sub, .i32x4Mul, .i32x4MinS, .i32x4MinU, .i32x4MaxS, .i32x4MaxU:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let aU = UInt32(truncatingIfNeeded: a[i])
                    let bU = UInt32(truncatingIfNeeded: b[i])
                    let value: UInt32
                    switch opcode {
                    case .i32x4Add: value = aU &+ bU
                    case .i32x4Sub: value = aU &- bU
                    case .i32x4Mul: value = UInt32(truncatingIfNeeded: UInt64(aU) * UInt64(bU))
                    case .i32x4MinS: value = UInt32(bitPattern: Swift.min(Int32(bitPattern: aU), Int32(bitPattern: bU)))
                    case .i32x4MinU: value = Swift.min(aU, bU)
                    case .i32x4MaxS: value = UInt32(bitPattern: Swift.max(Int32(bitPattern: aU), Int32(bitPattern: bU)))
                    case .i32x4MaxU: value = Swift.max(aU, bU)
                    default: value = 0
                    }
                    out.append(UInt64(value))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i64x2Add, .i64x2Sub, .i64x2Mul:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 64, laneCount: 2)
                let b = V128Lanes.extract(rhs, widthBits: 64, laneCount: 2)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let value: UInt64
                    switch opcode {
                    case .i64x2Add: value = a[i] &+ b[i]
                    case .i64x2Sub: value = a[i] &- b[i]
                    case .i64x2Mul: value = a[i] &* b[i]
                    default: value = 0
                    }
                    out.append(value)
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i8x16Shl, .i8x16ShrS, .i8x16ShrU,
            .i16x8Shl, .i16x8ShrS, .i16x8ShrU,
            .i32x4Shl, .i32x4ShrS, .i32x4ShrU,
            .i64x2Shl, .i64x2ShrS, .i64x2ShrU:
            let shift32 = sp[immediate.input1].i32
            let (widthBits, laneCount, shiftMask): (Int, Int, UInt32) = switch opcode {
            case .i8x16Shl, .i8x16ShrS, .i8x16ShrU: (8, 16, 7)
            case .i16x8Shl, .i16x8ShrS, .i16x8ShrU: (16, 8, 15)
            case .i32x4Shl, .i32x4ShrS, .i32x4ShrU: (32, 4, 31)
            default: (64, 2, 63)
            }
            let shift = Int(shift32 & shiftMask)
            v128Unary { input in
                let lanes = V128Lanes.extract(input, widthBits: widthBits, laneCount: laneCount)
                var out: [UInt64] = []
                out.reserveCapacity(laneCount)
                let mask = V128Lanes.laneMask(widthBits: widthBits)
                for x in lanes {
                    let r: UInt64
                    switch opcode {
                    case .i8x16Shl, .i16x8Shl, .i32x4Shl, .i64x2Shl:
                        r = (x << UInt64(shift)) & mask
                    case .i8x16ShrU, .i16x8ShrU, .i32x4ShrU, .i64x2ShrU:
                        r = x >> UInt64(shift)
                    default:
                        // signed shift-right
                        switch widthBits {
                        case 8:
                            r = UInt64(UInt8(bitPattern: Int8(bitPattern: UInt8(truncatingIfNeeded: x)) >> shift))
                        case 16:
                            r = UInt64(UInt16(bitPattern: Int16(bitPattern: UInt16(truncatingIfNeeded: x)) >> shift))
                        case 32:
                            r = UInt64(UInt32(bitPattern: Int32(bitPattern: UInt32(truncatingIfNeeded: x)) >> shift))
                        default:
                            r = UInt64(bitPattern: Int64(bitPattern: x) >> shift)
                        }
                    }
                    out.append(r)
                }
                return V128Lanes.pack(out, widthBits: widthBits, laneCount: laneCount)
            }
            return true

        case .i8x16NarrowI16X8S, .i8x16NarrowI16X8U:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(16)
                for i in 0..<8 {
                    let aW = UInt16(truncatingIfNeeded: a[i])
                    let bW = UInt16(truncatingIfNeeded: b[i])
                    if opcode == .i8x16NarrowI16X8S {
                        out.append(UInt64(UInt8(bitPattern: Int8(clamping: Int16(bitPattern: aW)))))
                        out.append(UInt64(UInt8(bitPattern: Int8(clamping: Int16(bitPattern: bW)))))
                    } else {
                        let aS = Int32(Int16(bitPattern: aW))
                        let bS = Int32(Int16(bitPattern: bW))
                        out.append(UInt64(UInt8(clamping: aS)))
                        out.append(UInt64(UInt8(clamping: bS)))
                    }
                }
                // out is interleaved; need low-half then high-half
                let low = out.enumerated().compactMap { $0.offset % 2 == 0 ? $0.element : nil }
                let high = out.enumerated().compactMap { $0.offset % 2 == 1 ? $0.element : nil }
                return V128Lanes.pack(low + high, widthBits: 8, laneCount: 16)
            }
            return true

        case .i16x8NarrowI32X4S, .i16x8NarrowI32X4U:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                var outLow: [UInt64] = []
                var outHigh: [UInt64] = []
                outLow.reserveCapacity(4)
                outHigh.reserveCapacity(4)
                for i in 0..<4 {
                    let aD = UInt32(truncatingIfNeeded: a[i])
                    let bD = UInt32(truncatingIfNeeded: b[i])
                    if opcode == .i16x8NarrowI32X4S {
                        outLow.append(UInt64(UInt16(bitPattern: Int16(clamping: Int32(bitPattern: aD)))))
                        outHigh.append(UInt64(UInt16(bitPattern: Int16(clamping: Int32(bitPattern: bD)))))
                    } else {
                        outLow.append(UInt64(UInt16(clamping: Int64(Int32(bitPattern: aD)))))
                        outHigh.append(UInt64(UInt16(clamping: Int64(Int32(bitPattern: bD)))))
                    }
                }
                return V128Lanes.pack(outLow + outHigh, widthBits: 16, laneCount: 8)
            }
            return true

        case .i16x8ExtendLowI8X16S, .i16x8ExtendHighI8X16S, .i16x8ExtendLowI8X16U, .i16x8ExtendHighI8X16U:
            v128Unary { input in
                let bytes = V128Lanes.extract(input, widthBits: 8, laneCount: 16)
                let base = (opcode == .i16x8ExtendHighI8X16S || opcode == .i16x8ExtendHighI8X16U) ? 8 : 0
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let b = UInt8(truncatingIfNeeded: bytes[base + i])
                    if opcode == .i16x8ExtendLowI8X16S || opcode == .i16x8ExtendHighI8X16S {
                        out.append(UInt64(UInt16(bitPattern: Int16(Int8(bitPattern: b)))))
                    } else {
                        out.append(UInt64(UInt16(b)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4ExtendLowI16X8S, .i32x4ExtendHighI16X8S, .i32x4ExtendLowI16X8U, .i32x4ExtendHighI16X8U:
            v128Unary { input in
                let w = V128Lanes.extract(input, widthBits: 16, laneCount: 8)
                let base = (opcode == .i32x4ExtendHighI16X8S || opcode == .i32x4ExtendHighI16X8U) ? 4 : 0
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let lane = UInt16(truncatingIfNeeded: w[base + i])
                    if opcode == .i32x4ExtendLowI16X8S || opcode == .i32x4ExtendHighI16X8S {
                        out.append(UInt64(UInt32(bitPattern: Int32(Int16(bitPattern: lane)))))
                    } else {
                        out.append(UInt64(UInt32(lane)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i64x2ExtendLowI32X4S, .i64x2ExtendHighI32X4S, .i64x2ExtendLowI32X4U, .i64x2ExtendHighI32X4U:
            v128Unary { input in
                let d = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let base = (opcode == .i64x2ExtendHighI32X4S || opcode == .i64x2ExtendHighI32X4U) ? 2 : 0
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let lane = UInt32(truncatingIfNeeded: d[base + i])
                    if opcode == .i64x2ExtendLowI32X4S || opcode == .i64x2ExtendHighI32X4S {
                        out.append(UInt64(bitPattern: Int64(Int32(bitPattern: lane))))
                    } else {
                        out.append(UInt64(lane))
                    }
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i32x4DotI16X8S:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let a0 = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: a[i * 2])))
                    let a1 = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: a[i * 2 + 1])))
                    let b0 = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: b[i * 2])))
                    let b1 = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: b[i * 2 + 1])))
                    out.append(UInt64(UInt32(bitPattern: a0 &* b0 &+ a1 &* b1)))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i16x8Q15MulrSatS:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let x = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: a[i])))
                    let y = Int32(Int16(bitPattern: UInt16(truncatingIfNeeded: b[i])))
                    let prod = x * y
                    let rounded = (prod + 0x4000) >> 15
                    out.append(UInt64(UInt16(bitPattern: Int16(clamping: rounded))))
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i8x16Popcnt:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 8, laneCount: 16)
                let out = a.map { UInt64(UInt8(UInt8(truncatingIfNeeded: $0).nonzeroBitCount)) }
                return V128Lanes.pack(out, widthBits: 8, laneCount: 16)
            }
            return true

        case .i16x8ExtaddPairwiseI8X16S, .i16x8ExtaddPairwiseI8X16U:
            v128Unary { input in
                let b = V128Lanes.extract(input, widthBits: 8, laneCount: 16)
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let b0 = UInt8(truncatingIfNeeded: b[i * 2])
                    let b1 = UInt8(truncatingIfNeeded: b[i * 2 + 1])
                    if opcode == .i16x8ExtaddPairwiseI8X16S {
                        out.append(UInt64(UInt16(bitPattern: Int16(Int8(bitPattern: b0)) + Int16(Int8(bitPattern: b1)))))
                    } else {
                        out.append(UInt64(UInt16(b0) + UInt16(b1)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4ExtaddPairwiseI16X8S, .i32x4ExtaddPairwiseI16X8U:
            v128Unary { input in
                let w = V128Lanes.extract(input, widthBits: 16, laneCount: 8)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let w0 = UInt16(truncatingIfNeeded: w[i * 2])
                    let w1 = UInt16(truncatingIfNeeded: w[i * 2 + 1])
                    if opcode == .i32x4ExtaddPairwiseI16X8S {
                        out.append(UInt64(UInt32(bitPattern: Int32(Int16(bitPattern: w0)) + Int32(Int16(bitPattern: w1)))))
                    } else {
                        out.append(UInt64(UInt32(w0) + UInt32(w1)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i16x8ExtmulLowI8X16S, .i16x8ExtmulHighI8X16S, .i16x8ExtmulLowI8X16U, .i16x8ExtmulHighI8X16U:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 8, laneCount: 16)
                let b = V128Lanes.extract(rhs, widthBits: 8, laneCount: 16)
                let base = (opcode == .i16x8ExtmulHighI8X16S || opcode == .i16x8ExtmulHighI8X16U) ? 8 : 0
                var out: [UInt64] = []
                out.reserveCapacity(8)
                for i in 0..<8 {
                    let x = UInt8(truncatingIfNeeded: a[base + i])
                    let y = UInt8(truncatingIfNeeded: b[base + i])
                    if opcode == .i16x8ExtmulLowI8X16S || opcode == .i16x8ExtmulHighI8X16S {
                        out.append(UInt64(UInt16(bitPattern: Int16(Int8(bitPattern: x)) * Int16(Int8(bitPattern: y)))))
                    } else {
                        out.append(UInt64(UInt16(x) * UInt16(y)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 16, laneCount: 8)
            }
            return true

        case .i32x4ExtmulLowI16X8S, .i32x4ExtmulHighI16X8S, .i32x4ExtmulLowI16X8U, .i32x4ExtmulHighI16X8U:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 16, laneCount: 8)
                let b = V128Lanes.extract(rhs, widthBits: 16, laneCount: 8)
                let base = (opcode == .i32x4ExtmulHighI16X8S || opcode == .i32x4ExtmulHighI16X8U) ? 4 : 0
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let x = UInt16(truncatingIfNeeded: a[base + i])
                    let y = UInt16(truncatingIfNeeded: b[base + i])
                    if opcode == .i32x4ExtmulLowI16X8S || opcode == .i32x4ExtmulHighI16X8S {
                        out.append(UInt64(UInt32(bitPattern: Int32(Int16(bitPattern: x)) * Int32(Int16(bitPattern: y)))))
                    } else {
                        out.append(UInt64(UInt32(x) * UInt32(y)))
                    }
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .i64x2ExtmulLowI32X4S, .i64x2ExtmulHighI32X4S, .i64x2ExtmulLowI32X4U, .i64x2ExtmulHighI32X4U:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                let base = (opcode == .i64x2ExtmulHighI32X4S || opcode == .i64x2ExtmulHighI32X4U) ? 2 : 0
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let x = UInt32(truncatingIfNeeded: a[base + i])
                    let y = UInt32(truncatingIfNeeded: b[base + i])
                    if opcode == .i64x2ExtmulLowI32X4S || opcode == .i64x2ExtmulHighI32X4S {
                        out.append(UInt64(bitPattern: Int64(Int32(bitPattern: x)) * Int64(Int32(bitPattern: y))))
                    } else {
                        out.append(UInt64(x) * UInt64(y))
                    }
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .f32x4Ceil, .f32x4Floor, .f32x4Trunc, .f32x4Nearest, .f32x4Abs, .f32x4Neg, .f32x4Sqrt:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let out = a.map { bits -> UInt64 in
                    let x = Float32(bitPattern: UInt32(truncatingIfNeeded: bits))
                    let y: Float32 = switch opcode {
                    case .f32x4Ceil: x.ceil
                    case .f32x4Floor: x.floor
                    case .f32x4Trunc: x.trunc
                    case .f32x4Nearest: x.nearest
                    case .f32x4Abs: x.abs
                    case .f32x4Neg: x.neg
                    default: x.sqrt
                    }
                    return UInt64(y.bitPattern)
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f64x2Ceil, .f64x2Floor, .f64x2Trunc, .f64x2Nearest, .f64x2Abs, .f64x2Neg, .f64x2Sqrt:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 64, laneCount: 2)
                let out = a.map { bits -> UInt64 in
                    let x = Float64(bitPattern: bits)
                    let y: Float64 = switch opcode {
                    case .f64x2Ceil: x.ceil
                    case .f64x2Floor: x.floor
                    case .f64x2Trunc: x.trunc
                    case .f64x2Nearest: x.nearest
                    case .f64x2Abs: x.abs
                    case .f64x2Neg: x.neg
                    default: x.sqrt
                    }
                    return y.bitPattern
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .f32x4Add, .f32x4Sub, .f32x4Mul, .f32x4Div, .f32x4Min, .f32x4Max, .f32x4Pmin, .f32x4Pmax:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 32, laneCount: 4)
                let b = V128Lanes.extract(rhs, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(4)
                for i in 0..<4 {
                    let x = Float32(bitPattern: UInt32(truncatingIfNeeded: a[i]))
                    let y = Float32(bitPattern: UInt32(truncatingIfNeeded: b[i]))
                    let z: Float32 = switch opcode {
                    case .f32x4Add: x + y
                    case .f32x4Sub: x - y
                    case .f32x4Mul: x * y
                    case .f32x4Div: x / y
                    case .f32x4Min: x.min(y)
                    case .f32x4Max: x.max(y)
                    case .f32x4Pmin: pmin(x, y)
                    default: pmax(x, y)
                    }
                    out.append(UInt64(z.bitPattern))
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f64x2Add, .f64x2Sub, .f64x2Mul, .f64x2Div, .f64x2Min, .f64x2Max, .f64x2Pmin, .f64x2Pmax:
            v128Binary { lhs, rhs in
                let a = V128Lanes.extract(lhs, widthBits: 64, laneCount: 2)
                let b = V128Lanes.extract(rhs, widthBits: 64, laneCount: 2)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let x = Float64(bitPattern: a[i])
                    let y = Float64(bitPattern: b[i])
                    let z: Float64 = switch opcode {
                    case .f64x2Add: x + y
                    case .f64x2Sub: x - y
                    case .f64x2Mul: x * y
                    case .f64x2Div: x / y
                    case .f64x2Min: x.min(y)
                    case .f64x2Max: x.max(y)
                    case .f64x2Pmin: pmin(x, y)
                    default: pmax(x, y)
                    }
                    out.append(z.bitPattern)
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i32x4TruncSatF32X4S, .i32x4TruncSatF32X4U:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let out = a.map { bits -> UInt64 in
                    let x = Float32(bitPattern: UInt32(truncatingIfNeeded: bits))
                    let y: UInt32 = opcode == .i32x4TruncSatF32X4S ? (try! x.truncSatToI32S) : (try! x.truncSatToI32U)
                    return UInt64(y)
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f32x4ConvertI32X4S, .f32x4ConvertI32X4U:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let out = a.map { bits -> UInt64 in
                    let x = UInt32(truncatingIfNeeded: bits)
                    let y: Float32 = opcode == .f32x4ConvertI32X4S ? x.convertToF32S : x.convertToF32U
                    return UInt64(y.bitPattern)
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f64x2ConvertLowI32X4S, .f64x2ConvertLowI32X4U:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                var out: [UInt64] = []
                out.reserveCapacity(2)
                for i in 0..<2 {
                    let x = UInt32(truncatingIfNeeded: a[i])
                    let y: Float64 = opcode == .f64x2ConvertLowI32X4S ? x.convertToF64S : x.convertToF64U
                    out.append(y.bitPattern)
                }
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        case .i32x4TruncSatF64X2SZero, .i32x4TruncSatF64X2UZero:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 64, laneCount: 2)
                var out: [UInt64] = [0, 0, 0, 0]
                for i in 0..<2 {
                    let x = Float64(bitPattern: a[i])
                    let y: UInt32 = opcode == .i32x4TruncSatF64X2SZero ? (try! x.truncSatToI32S) : (try! x.truncSatToI32U)
                    out[i] = UInt64(y)
                }
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f32x4DemoteF64X2Zero:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 64, laneCount: 2)
                let out: [UInt64] = [
                    UInt64(Float32(Float64(bitPattern: a[0])).bitPattern),
                    UInt64(Float32(Float64(bitPattern: a[1])).bitPattern),
                    0,
                    0,
                ]
                return V128Lanes.pack(out, widthBits: 32, laneCount: 4)
            }
            return true

        case .f64x2PromoteLowF32X4:
            v128Unary { input in
                let a = V128Lanes.extract(input, widthBits: 32, laneCount: 4)
                let out: [UInt64] = [
                    Float64(Float32(bitPattern: UInt32(truncatingIfNeeded: a[0]))).bitPattern,
                    Float64(Float32(bitPattern: UInt32(truncatingIfNeeded: a[1]))).bitPattern,
                ]
                return V128Lanes.pack(out, widthBits: 64, laneCount: 2)
            }
            return true

        default:
            return false
        }
    }
}

