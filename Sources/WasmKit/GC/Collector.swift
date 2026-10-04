// # The collector
//
// The collector is a stop-the-world, mark-compact one. It runs at a safepoint,
// when an allocation does not fit, and keeps the heap dense:
//
// 1. Mark. Starting from the roots (see `forEachRoot`), it follows the
//    reference fields of every object it reaches. A side bitmap has one bit per
//    8 bytes of the heap, and marking an object sets the bits of all of its
//    words, so that the bitmap also tells how many live bytes precede any
//    offset.
// 2. Compute new offsets. Live objects slide down in address order, so an
//    object's new offset is the heap's start plus the live bytes before it:
//    a prefix count per bitmap word, plus the bits before the object in its own
//    word. Objects need no forwarding word.
// 3. Update every root and every reference field of a live object to the new
//    offsets, while the objects are still where they were.
// 4. Slide each live object to its new offset, in address order, and zero the
//    space freed at the end, where the next allocations go.
//
// In stress mode the live objects are copied into a new region instead, at
// offsets shifted by a gap that alternates between collections, and the old
// region is poisoned. Every live object then moves at every collection, so a
// root that the stack maps miss reads garbage and fails a test.

extension GCHeap {
    private static var nullBit: UInt64 { 1 << 63 }

    /// The size of the object at `object`, header included, rounded up to 8.
    func objectSize(_ object: UInt32) -> Int {
        let entry = typeRegistry.entry(typeID(of: object))
        let size: Int
        switch kind(of: object) {
        case .structObject:
            size = entry.structLayout.unsafelyUnwrapped.size
        case .arrayObject:
            size = Self.arrayElementsOffset + Int(arrayLength(object)) * entry.arrayElement.unsafelyUnwrapped.size
        case .exceptionObject:
            guard case .function(let type) = entry.subType.body else { preconditionFailure() }
            size = Self.exceptionLayout(parameters: type.parameters).size
        }
        return (size + 7) & ~7
    }

    /// Calls `visit` with the address of each reference field of `object` that
    /// may hold a reference to an object.
    private func forEachTracedField(_ object: UInt32, _ visit: (UnsafeMutableRawPointer) -> Void) {
        let base = address(object)
        let entry = typeRegistry.entry(typeID(of: object))
        switch kind(of: object) {
        case .structObject:
            for field in entry.structLayout.unsafelyUnwrapped.fields where field.isTraced {
                visit(base + field.offset)
            }
        case .arrayObject:
            guard entry.isArrayElementTraced else { return }
            let elements = base + Self.arrayElementsOffset
            for index in 0..<Int(arrayLength(object)) {
                visit(elements + index * FieldStorage.reference.size)
            }
        case .exceptionObject:
            guard case .function(let type) = entry.subType.body else { return }
            for field in Self.exceptionLayout(parameters: type.parameters).fields where field.isTraced {
                visit(base + field.offset)
            }
        }
    }

    /// The marks of a collection, and the new offsets they give.
    private struct MarkBitmap {
        var words: [UInt64]
        /// The number of live 8-byte words before each bitmap word.
        var prefix: [UInt32] = []

        init(heapSize: Int) {
            words = [UInt64](repeating: 0, count: (heapSize / 8 + 63) / 64)
        }

        func isMarked(_ object: UInt32) -> Bool {
            let word = Int(object) / 8
            return words[word / 64] >> UInt64(word % 64) & 1 != 0
        }

        mutating func mark(_ object: UInt32, size: Int) {
            for word in (Int(object) / 8)..<((Int(object) + size) / 8) {
                words[word / 64] |= 1 << UInt64(word % 64)
            }
        }

        mutating func computePrefix() -> Int {
            prefix = []
            prefix.reserveCapacity(words.count)
            var live: UInt32 = 0
            for word in words {
                prefix.append(live)
                live += UInt32(word.nonzeroBitCount)
            }
            return Int(live) * 8
        }

        /// The new offset of the live object at `object`, if the live objects
        /// start at `start`.
        func forwarded(_ object: UInt32, start: UInt32) -> UInt32 {
            let word = Int(object) / 8
            let bits = words[word / 64] & ((1 << UInt64(word % 64)) &- 1)
            return start + (prefix[word / 64] + UInt32(bits.nonzeroBitCount)) * 8
        }
    }

    /// Frees the objects that nothing reachable from the roots at `safepoint`
    /// refers to, and moves the others to the start of the heap.
    func collect(at safepoint: GCSafepoint?) {
        guard base != nil else { return }
        var bitmap = MarkBitmap(heapSize: top)
        var worklist: [UInt32] = []
        func mark(_ object: UInt32) {
            precondition(isObject(object), "GC reference \(object) does not point to an object")
            guard !bitmap.isMarked(object) else { return }
            bitmap.mark(object, size: objectSize(object))
            worklist.append(object)
        }
        forEachRoot(from: safepoint) { object in mark(object) }
        while let object = worklist.popLast() {
            forEachTracedField(object) { field in
                let value = field.loadUnaligned(as: UInt64.self) ^ Self.nullBit
                if Self.isObjectReference(value) {
                    mark(UInt32(truncatingIfNeeded: value))
                }
            }
        }

        let liveSize = bitmap.computePrefix()
        let start: UInt32 = isStressMode && stressGapFlag ? 8 + Self.stressGap : 8
        if isStressMode {
            stressGapFlag.toggle()
        }
        forEachRoot(from: safepoint) { object in object = bitmap.forwarded(object, start: start) }
        var object = objectsStart
        while Int(object) < top {
            let size = objectSize(object)
            if bitmap.isMarked(object) {
                forEachTracedField(object) { field in
                    let value = field.loadUnaligned(as: UInt64.self) ^ Self.nullBit
                    if Self.isObjectReference(value) {
                        let forwarded = bitmap.forwarded(UInt32(truncatingIfNeeded: value), start: start)
                        field.storeBytes(of: UInt64(forwarded) ^ Self.nullBit, as: UInt64.self)
                    }
                }
            }
            object += UInt32(size)
        }

        let newTop = Int(start) + liveSize
        if isStressMode {
            moveToNewRegion(bitmap: bitmap, start: start, newTop: newTop)
        } else {
            var object = objectsStart
            while Int(object) < top {
                let size = objectSize(object)
                if bitmap.isMarked(object) {
                    let destination = bitmap.forwarded(object, start: start)
                    if destination != object {
                        address(destination).copyMemory(from: address(object), byteCount: size)
                    }
                }
                object += UInt32(size)
            }
            address(UInt32(newTop)).initializeMemory(as: UInt8.self, repeating: 0, count: top - newTop)
        }
        top = newTop
        objectsStart = start
    }

    private static var stressGap: UInt32 { 64 }

    /// Copies the live objects into a new region and poisons the old one.
    private func moveToNewRegion(bitmap: MarkBitmap, start: UInt32, newTop: Int) {
        let newCapacity = max(capacity, newTop) + Int(Self.stressGap)
        let newBase = UnsafeMutableRawPointer.allocate(byteCount: newCapacity, alignment: 16)
        newBase.initializeMemory(as: UInt8.self, repeating: 0, count: newCapacity)
        var object = objectsStart
        while Int(object) < top {
            let size = objectSize(object)
            if bitmap.isMarked(object) {
                (newBase + Int(bitmap.forwarded(object, start: start))).copyMemory(from: address(object), byteCount: size)
            }
            object += UInt32(size)
        }
        base.unsafelyUnwrapped.initializeMemory(as: UInt8.self, repeating: 0xA5, count: capacity)
        base.unsafelyUnwrapped.deallocate()
        base = newBase
        capacity = newCapacity
    }
}
