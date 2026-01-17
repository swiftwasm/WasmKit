import WasmTypes

extension Execution {
    @inline(__always)
    private func boundsCheck(_ start: UInt64, length: UInt64, ms: Ms) throws {
        let (end, overflow) = start.addingReportingOverflow(length)
        if _fastPath(!overflow && end <= UInt64(ms)) { return }
        try throwOutOfBoundsMemoryAccess()
    }

    @inline(__always)
    private func loadU8(md: Md, address: UInt64) -> UInt8 {
        md.unsafelyUnwrapped.load(fromByteOffset: Int(address), as: UInt8.self)
    }

    @inline(__always)
    private func loadU16(md: Md, address: UInt64) -> UInt16 {
        md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Int(address), as: UInt16.self)
    }

    @inline(__always)
    private func loadU32(md: Md, address: UInt64) -> UInt32 {
        md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Int(address), as: UInt32.self)
    }

    @inline(__always)
    private func loadU64(md: Md, address: UInt64) -> UInt64 {
        md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Int(address), as: UInt64.self)
    }

    mutating func simdExecuteMemoryAndLane(
        opcode: SIMDOpcode,
        sp: Sp,
        md: Md,
        ms: Ms,
        immediate: Instruction.SimdOperand
    ) throws -> Bool {
        @inline(__always)
        func storeI32(_ value: UInt32) { sp[immediate.result] = UntypedValue.i32(value) }
        @inline(__always)
        func storeI64(_ value: UInt64) { sp[immediate.result] = UntypedValue.i64(value) }
        @inline(__always)
        func storeF32(_ bits: UInt32) { sp[immediate.result] = UntypedValue.rawF32(bits) }
        @inline(__always)
        func storeF64(_ bits: UInt64) { sp[immediate.result] = UntypedValue.rawF64(bits) }

        switch opcode {
        case .v128Load:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 16, ms: ms)
            let lo = loadU64(md: md, address: addr)
            let hi = loadU64(md: md, address: addr &+ 8)
            sp.storeV128(V128Storage(lo: lo, hi: hi), at: immediate.result)
            return true

        case .v128Store:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 16, ms: ms)
            let v = sp.loadV128(at: immediate.input1)
            md.unsafelyUnwrapped.advanced(by: Int(addr)).bindMemory(to: UInt64.self, capacity: 1).pointee = v.lo.littleEndian
            md.unsafelyUnwrapped.advanced(by: Int(addr &+ 8)).bindMemory(to: UInt64.self, capacity: 1).pointee = v.hi.littleEndian
            return true

        case .v128Load8X8S, .v128Load8X8U:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 8, ms: ms)
            var lanes: [UInt64] = []
            lanes.reserveCapacity(8)
            for i in 0..<8 {
                let b = loadU8(md: md, address: addr &+ UInt64(i))
                if opcode == .v128Load8X8S {
                    lanes.append(UInt64(UInt16(bitPattern: Int16(Int8(bitPattern: b)))))
                } else {
                    lanes.append(UInt64(UInt16(b)))
                }
            }
            let v = V128Lanes.pack(lanes, widthBits: 16, laneCount: 8)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load16X4S, .v128Load16X4U:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 8, ms: ms)
            var lanes: [UInt64] = []
            lanes.reserveCapacity(4)
            for i in 0..<4 {
                let w = loadU16(md: md, address: addr &+ UInt64(i * 2))
                if opcode == .v128Load16X4S {
                    lanes.append(UInt64(UInt32(bitPattern: Int32(Int16(bitPattern: w)))))
                } else {
                    lanes.append(UInt64(UInt32(w)))
                }
            }
            let v = V128Lanes.pack(lanes, widthBits: 32, laneCount: 4)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load32X2S, .v128Load32X2U:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 8, ms: ms)
            var lanes: [UInt64] = []
            lanes.reserveCapacity(2)
            for i in 0..<2 {
                let d = loadU32(md: md, address: addr &+ UInt64(i * 4))
                if opcode == .v128Load32X2S {
                    lanes.append(UInt64(bitPattern: Int64(Int32(bitPattern: d))))
                } else {
                    lanes.append(UInt64(d))
                }
            }
            let v = V128Lanes.pack(lanes, widthBits: 64, laneCount: 2)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load8Splat:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 1, ms: ms)
            let b = loadU8(md: md, address: addr)
            let v = V128Lanes.pack([UInt64](repeating: UInt64(b), count: 16), widthBits: 8, laneCount: 16)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load16Splat:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 2, ms: ms)
            let w = loadU16(md: md, address: addr)
            let v = V128Lanes.pack([UInt64](repeating: UInt64(w), count: 8), widthBits: 16, laneCount: 8)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load32Splat:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 4, ms: ms)
            let d = loadU32(md: md, address: addr)
            let v = V128Lanes.pack([UInt64](repeating: UInt64(d), count: 4), widthBits: 32, laneCount: 4)
            sp.storeV128(v, at: immediate.result)
            return true

        case .v128Load64Splat:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 8, ms: ms)
            let q = loadU64(md: md, address: addr)
            sp.storeV128(V128Storage(lo: q, hi: q), at: immediate.result)
            return true

        case .v128Load32Zero:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 4, ms: ms)
            let d = loadU32(md: md, address: addr)
            var lanes = [UInt64](repeating: 0, count: 4)
            lanes[0] = UInt64(d)
            sp.storeV128(V128Lanes.pack(lanes, widthBits: 32, laneCount: 4), at: immediate.result)
            return true

        case .v128Load64Zero:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            try boundsCheck(addr, length: 8, ms: ms)
            let q = loadU64(md: md, address: addr)
            sp.storeV128(V128Storage(lo: q, hi: 0), at: immediate.result)
            return true

        case .v128Load8Lane, .v128Load16Lane, .v128Load32Lane, .v128Load64Lane:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            var vec = sp.loadV128(at: immediate.input1)
            let lane = Int(immediate.lane)
            switch opcode {
            case .v128Load8Lane:
                try boundsCheck(addr, length: 1, ms: ms)
                var bytes = V128Lanes.extract(vec, widthBits: 8, laneCount: 16)
                bytes[lane] = UInt64(loadU8(md: md, address: addr))
                vec = V128Lanes.pack(bytes, widthBits: 8, laneCount: 16)
            case .v128Load16Lane:
                try boundsCheck(addr, length: 2, ms: ms)
                var lanes = V128Lanes.extract(vec, widthBits: 16, laneCount: 8)
                lanes[lane] = UInt64(loadU16(md: md, address: addr))
                vec = V128Lanes.pack(lanes, widthBits: 16, laneCount: 8)
            case .v128Load32Lane:
                try boundsCheck(addr, length: 4, ms: ms)
                var lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
                lanes[lane] = UInt64(loadU32(md: md, address: addr))
                vec = V128Lanes.pack(lanes, widthBits: 32, laneCount: 4)
            case .v128Load64Lane:
                try boundsCheck(addr, length: 8, ms: ms)
                var lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
                lanes[lane] = loadU64(md: md, address: addr)
                vec = V128Lanes.pack(lanes, widthBits: 64, laneCount: 2)
            default:
                break
            }
            sp.storeV128(vec, at: immediate.result)
            return true

        case .v128Store8Lane, .v128Store16Lane, .v128Store32Lane, .v128Store64Lane:
            let addr = sp[immediate.input0].asAddressOffset() &+ immediate.offset
            let vec = sp.loadV128(at: immediate.input1)
            let lane = Int(immediate.lane)
            switch opcode {
            case .v128Store8Lane:
                try boundsCheck(addr, length: 1, ms: ms)
                let bytes = V128Lanes.extract(vec, widthBits: 8, laneCount: 16)
                md.unsafelyUnwrapped.storeBytes(of: UInt8(truncatingIfNeeded: bytes[lane]), toByteOffset: Int(addr), as: UInt8.self)
            case .v128Store16Lane:
                try boundsCheck(addr, length: 2, ms: ms)
                let lanes = V128Lanes.extract(vec, widthBits: 16, laneCount: 8)
                let v = UInt16(truncatingIfNeeded: lanes[lane]).littleEndian
                md.unsafelyUnwrapped.advanced(by: Int(addr)).bindMemory(to: UInt16.self, capacity: 1).pointee = v
            case .v128Store32Lane:
                try boundsCheck(addr, length: 4, ms: ms)
                let lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
                let v = UInt32(truncatingIfNeeded: lanes[lane]).littleEndian
                md.unsafelyUnwrapped.advanced(by: Int(addr)).bindMemory(to: UInt32.self, capacity: 1).pointee = v
            case .v128Store64Lane:
                try boundsCheck(addr, length: 8, ms: ms)
                let lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
                let v = lanes[lane].littleEndian
                md.unsafelyUnwrapped.advanced(by: Int(addr)).bindMemory(to: UInt64.self, capacity: 1).pointee = v
            default:
                break
            }
            return true

        case .i8x16ExtractLaneS:
            let vec = sp.loadV128(at: immediate.input0)
            let bytes = V128Lanes.extract(vec, widthBits: 8, laneCount: 16)
            let b = UInt8(truncatingIfNeeded: bytes[Int(immediate.lane)])
            storeI32(UInt32(bitPattern: Int32(Int8(bitPattern: b))))
            return true
        case .i8x16ExtractLaneU:
            let vec = sp.loadV128(at: immediate.input0)
            let bytes = V128Lanes.extract(vec, widthBits: 8, laneCount: 16)
            storeI32(UInt32(bytes[Int(immediate.lane)]))
            return true
        case .i8x16ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var bytes = V128Lanes.extract(vec, widthBits: 8, laneCount: 16)
            bytes[Int(immediate.lane)] = UInt64(UInt8(truncatingIfNeeded: sp[immediate.input1].i32))
            vec = V128Lanes.pack(bytes, widthBits: 8, laneCount: 16)
            sp.storeV128(vec, at: immediate.result)
            return true

        case .i16x8ExtractLaneS:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 16, laneCount: 8)
            let w = UInt16(truncatingIfNeeded: lanes[Int(immediate.lane)])
            storeI32(UInt32(bitPattern: Int32(Int16(bitPattern: w))))
            return true
        case .i16x8ExtractLaneU:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 16, laneCount: 8)
            storeI32(UInt32(UInt16(truncatingIfNeeded: lanes[Int(immediate.lane)])))
            return true
        case .i16x8ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var lanes = V128Lanes.extract(vec, widthBits: 16, laneCount: 8)
            lanes[Int(immediate.lane)] = UInt64(UInt16(truncatingIfNeeded: sp[immediate.input1].i32))
            vec = V128Lanes.pack(lanes, widthBits: 16, laneCount: 8)
            sp.storeV128(vec, at: immediate.result)
            return true

        case .i32x4ExtractLane:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
            storeI32(UInt32(truncatingIfNeeded: lanes[Int(immediate.lane)]))
            return true
        case .i32x4ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
            lanes[Int(immediate.lane)] = UInt64(sp[immediate.input1].i32)
            vec = V128Lanes.pack(lanes, widthBits: 32, laneCount: 4)
            sp.storeV128(vec, at: immediate.result)
            return true

        case .i64x2ExtractLane:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
            storeI64(lanes[Int(immediate.lane)])
            return true
        case .i64x2ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
            lanes[Int(immediate.lane)] = sp[immediate.input1].i64
            vec = V128Lanes.pack(lanes, widthBits: 64, laneCount: 2)
            sp.storeV128(vec, at: immediate.result)
            return true

        case .f32x4ExtractLane:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
            storeF32(UInt32(truncatingIfNeeded: lanes[Int(immediate.lane)]))
            return true
        case .f32x4ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var lanes = V128Lanes.extract(vec, widthBits: 32, laneCount: 4)
            lanes[Int(immediate.lane)] = UInt64(sp[immediate.input1].rawF32)
            vec = V128Lanes.pack(lanes, widthBits: 32, laneCount: 4)
            sp.storeV128(vec, at: immediate.result)
            return true

        case .f64x2ExtractLane:
            let vec = sp.loadV128(at: immediate.input0)
            let lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
            storeF64(lanes[Int(immediate.lane)])
            return true
        case .f64x2ReplaceLane:
            var vec = sp.loadV128(at: immediate.input0)
            var lanes = V128Lanes.extract(vec, widthBits: 64, laneCount: 2)
            lanes[Int(immediate.lane)] = sp[immediate.input1].rawF64
            vec = V128Lanes.pack(lanes, widthBits: 64, laneCount: 2)
            sp.storeV128(vec, at: immediate.result)
            return true

        default:
            return false
        }
    }
}

