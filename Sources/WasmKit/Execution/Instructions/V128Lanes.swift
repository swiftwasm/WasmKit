import WasmTypes

extension Sp {
    @inline(__always)
    func loadV128(at reg: VReg) -> V128Storage {
        V128Storage(lo: self[Int(reg)], hi: self[Int(reg) + 1])
    }

    @inline(__always)
    func storeV128(_ value: V128Storage, at reg: VReg) {
        self[Int(reg)] = value.lo
        self[Int(reg) + 1] = value.hi
    }
}

struct V128Lanes {
    @inline(__always)
    static func laneMask(widthBits: Int) -> UInt64 {
        precondition(widthBits == 8 || widthBits == 16 || widthBits == 32 || widthBits == 64)
        if widthBits == 64 { return UInt64.max }
        return (UInt64(1) << UInt64(widthBits)) &- 1
    }

    @inline(__always)
    static func boolMask(widthBits: Int, truth: Bool) -> UInt64 {
        truth ? laneMask(widthBits: widthBits) : 0
    }

    @inline(__always)
    static func extract(_ v: V128Storage, widthBits: Int, laneCount: Int) -> [UInt64] {
        let mask = laneMask(widthBits: widthBits)
        var lanes: [UInt64] = []
        lanes.reserveCapacity(laneCount)
        for i in 0..<laneCount {
            let bitOffset = i * widthBits
            let value: UInt64
            if bitOffset < 64 {
                value = (v.lo >> UInt64(bitOffset)) & mask
            } else {
                value = (v.hi >> UInt64(bitOffset - 64)) & mask
            }
            lanes.append(value)
        }
        return lanes
    }

    @inline(__always)
    static func pack(_ lanes: [UInt64], widthBits: Int, laneCount: Int) -> V128Storage {
        precondition(lanes.count == laneCount)
        let mask = laneMask(widthBits: widthBits)
        var lo: UInt64 = 0
        var hi: UInt64 = 0
        for i in 0..<laneCount {
            let bitOffset = i * widthBits
            let v = lanes[i] & mask
            if bitOffset < 64 {
                lo |= v << UInt64(bitOffset)
            } else {
                hi |= v << UInt64(bitOffset - 64)
            }
        }
        return V128Storage(lo: lo, hi: hi)
    }

    @inline(__always)
    static func map(
        _ v: V128Storage,
        widthBits: Int,
        laneCount: Int,
        _ f: (UInt64) throws -> UInt64
    ) rethrows -> V128Storage {
        let lanes = extract(v, widthBits: widthBits, laneCount: laneCount)
        let out = try lanes.map(f)
        return pack(out, widthBits: widthBits, laneCount: laneCount)
    }

    @inline(__always)
    static func zip(
        _ a: V128Storage,
        _ b: V128Storage,
        widthBits: Int,
        laneCount: Int,
        _ f: (UInt64, UInt64) throws -> UInt64
    ) rethrows -> V128Storage {
        let la = extract(a, widthBits: widthBits, laneCount: laneCount)
        let lb = extract(b, widthBits: widthBits, laneCount: laneCount)
        var out: [UInt64] = []
        out.reserveCapacity(laneCount)
        for i in 0..<laneCount {
            out.append(try f(la[i], lb[i]))
        }
        return pack(out, widthBits: widthBits, laneCount: laneCount)
    }

    @inline(__always)
    static func zip3(
        _ a: V128Storage,
        _ b: V128Storage,
        _ c: V128Storage,
        widthBits: Int,
        laneCount: Int,
        _ f: (UInt64, UInt64, UInt64) throws -> UInt64
    ) rethrows -> V128Storage {
        let la = extract(a, widthBits: widthBits, laneCount: laneCount)
        let lb = extract(b, widthBits: widthBits, laneCount: laneCount)
        let lc = extract(c, widthBits: widthBits, laneCount: laneCount)
        var out: [UInt64] = []
        out.reserveCapacity(laneCount)
        for i in 0..<laneCount {
            out.append(try f(la[i], lb[i], lc[i]))
        }
        return pack(out, widthBits: widthBits, laneCount: laneCount)
    }
}
