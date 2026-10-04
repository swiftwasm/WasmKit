// # Stack maps
//
// A collection can only happen at a safepoint: a call, where the callee may
// allocate, or an instruction that allocates. At each one the translator
// records which slots of the frame may hold a reference to a GC object, so the
// collector reads exactly those slots, and updates them if the object moves.
// The slots are the frame's parameters and locals of a reference type that is
// not a function reference, which are the same at every safepoint, and the
// value-stack entries of such a type that are materialized in a slot at that
// point. An entry that stands for a local or a constant is not in a slot of
// its own; the local's slot covers it.
//
// The arguments of a call belong to the callee, whose frame maps them as its
// parameters. The operands of an allocating instruction are still read after
// the allocation, so its map includes them.
//
// A caller frame's safepoint is found from the return address its callee saved,
// by binary search in the function's call sites. An allocating instruction
// carries the index of its map as an immediate.

extension ValueType {
    /// Whether a value of the type may be a reference to a GC object: a
    /// reference that is not a function reference. Exceptions are objects, and
    /// an internal or external reference may point to a struct or an array.
    var mayReferToObject: Bool {
        guard case .ref(let referenceType) = self else { return false }
        return referenceType.heapType.topType != .funcRef
    }
}

/// The stack maps of one function.
final class GCStackMaps {
    /// The slots of the parameters and locals that may hold an object reference,
    /// relative to `sp`.
    let frameSlots: [Int32]
    /// The value-stack slots of each safepoint, relative to `sp`.
    let maps: [[Int32]]
    /// The return offsets of the call sites, in code slots from the start of the
    /// function's instructions, in increasing order, with the map of each.
    let callSiteOffsets: [Int32]
    let callSiteMaps: [Int32]

    init(frameSlots: [Int32], maps: [[Int32]], callSiteOffsets: [Int32], callSiteMaps: [Int32]) {
        self.frameSlots = frameSlots
        self.maps = maps
        self.callSiteOffsets = callSiteOffsets
        self.callSiteMaps = callSiteMaps
    }

    /// The map of the call site that returns to `returnOffset`, or `nil` if
    /// there is none.
    func callSiteMap(returnOffset: Int) -> Int? {
        var low = 0
        var high = callSiteOffsets.count
        while low < high {
            let middle = (low + high) / 2
            if Int(callSiteOffsets[middle]) < returnOffset {
                low = middle + 1
            } else {
                high = middle
            }
        }
        guard low < callSiteOffsets.count, Int(callSiteOffsets[low]) == returnOffset else { return nil }
        return Int(callSiteMaps[low])
    }
}

/// Collects the stack maps of a function while it is translated.
struct GCStackMapBuilder {
    let frameSlots: [Int32]
    private(set) var maps: [[Int32]] = []
    private var callSiteOffsets: [Int32] = []
    private var callSiteMaps: [Int32] = []
    /// Whether any map has a value-stack slot.
    private var hasStackSlots = false
    /// Whether the function allocates.
    private var hasAllocationSites = false

    init(frameSlots: [Int32]) {
        self.frameSlots = frameSlots
    }

    /// Adds a map and returns its index.
    mutating func addMap(_ slots: [Int32], isAllocationSite: Bool) -> Int32 {
        hasStackSlots = hasStackSlots || !slots.isEmpty
        hasAllocationSites = hasAllocationSites || isAllocationSite
        maps.append(slots)
        return Int32(maps.count - 1)
    }

    mutating func addCallSite(returnOffset: Int, map: Int32) {
        // A rewind may drop the instructions of a call site recorded before it.
        while let last = callSiteOffsets.last, Int(last) >= returnOffset {
            callSiteOffsets.removeLast()
            callSiteMaps.removeLast()
        }
        callSiteOffsets.append(Int32(returnOffset))
        callSiteMaps.append(map)
    }

    /// The maps, or `nil` if no frame of the function can ever hold an object reference.
    func finish() -> GCStackMaps? {
        guard !frameSlots.isEmpty || hasStackSlots || hasAllocationSites else { return nil }
        return GCStackMaps(frameSlots: frameSlots, maps: maps, callSiteOffsets: callSiteOffsets, callSiteMaps: callSiteMaps)
    }
}

/// The stack maps of every function a store translated, by the address of its code.
final class GCStackMapTable {
    var maps: [Pc: GCStackMaps] = [:]
}

/// Where a collection happens: a frame and the index of its map.
struct GCSafepoint {
    let sp: Sp
    let map: Int
}

extension GCHeap {
    /// Whether a value-slot or table bit pattern is a reference to an object of
    /// this heap, given that its type may refer to one.
    @inline(__always)
    static func isObjectReference(_ bits: UInt64) -> Bool {
        bits & (1 << 63 | 0b11) == 0 && bits != 0
    }

    /// Calls `visit` with each value slot of the Wasm frames that may hold an
    /// object reference: those of `safepoint`, then of its callers, then of every
    /// frame that called out to the host and has not returned yet.
    func forEachFrameRootSlot(
        from safepoint: GCSafepoint?, _ visit: (UnsafeMutablePointer<UInt64>) -> Void
    ) {
        if let safepoint {
            visitFrames(sp: safepoint.sp, map: safepoint.map, visit)
        }
        for suspended in suspendedFrames {
            guard let function = suspended.sp.currentFunction else { continue }
            if let maps = stackMaps(of: function), let map = maps.callSiteMap(returnOffset: Self.offset(of: suspended.pc, in: function)) {
                visitFrames(sp: suspended.sp, map: map, visit)
            } else {
                visitCallers(of: suspended.sp, visit)
            }
        }
    }

    private static func codeBase(of function: EntityHandle<WasmFunctionEntity>) -> Pc? {
        function.withValue { function -> Pc? in
            switch function.code {
            case .compiled(let iseq), .debuggable(_, let iseq): return iseq.baseAddress
            case .uncompiled: return nil
            }
        }
    }

    private func stackMaps(of function: EntityHandle<WasmFunctionEntity>) -> GCStackMaps? {
        guard let base = Self.codeBase(of: function) else { return nil }
        return stackMapTable.maps[base]
    }

    private static func offset(of pc: Pc, in function: EntityHandle<WasmFunctionEntity>) -> Int {
        guard let base = codeBase(of: function) else { return -1 }
        return base.distance(to: pc)
    }

    /// Visits the frame at `sp` with the map at `map`, then its callers.
    private func visitFrames(sp: Sp, map: Int, _ visit: (UnsafeMutablePointer<UInt64>) -> Void) {
        if let function = sp.currentFunction, let maps = stackMaps(of: function) {
            Self.visit(frame: sp, maps: maps, map: map, visit)
        }
        visitCallers(of: sp, visit)
    }

    private func visitCallers(of sp: Sp, _ visit: (UnsafeMutablePointer<UInt64>) -> Void) {
        var callee = sp
        while let caller = callee.previousSP, let returnPC = callee.returnPC {
            if let function = caller.currentFunction, let maps = stackMaps(of: function) {
                guard let map = maps.callSiteMap(returnOffset: Self.offset(of: returnPC, in: function)) else {
                    preconditionFailure("No stack map for a call site")
                }
                Self.visit(frame: caller, maps: maps, map: map, visit)
            }
            callee = caller
        }
    }

    private static func visit(frame sp: Sp, maps: GCStackMaps, map: Int, _ visit: (UnsafeMutablePointer<UInt64>) -> Void) {
        for slot in maps.frameSlots {
            visit(sp + Int(slot))
        }
        for slot in maps.maps[map] {
            visit(sp + Int(slot))
        }
    }
}
