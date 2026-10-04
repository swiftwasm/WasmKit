/// How a `struct.get`, `struct.set`, `array.get` or similar instruction reads
/// or writes a field: the field's storage, whether a packed value is
/// sign-extended, and for a struct field its offset in the object.
struct GCFieldAccess {
    let offset: Int
    let storage: FieldStorage
    let signed: Bool

    init(offset: Int = 0, storage: FieldStorage, signed: Bool = false) {
        self.offset = offset
        self.storage = storage
        self.signed = signed
    }

    /// The access of a struct field, packed into a `UInt32`.
    init(structField encoded: UInt32) {
        self.init(offset: Int(encoded >> 8), storage: FieldStorage(rawValue: UInt8(truncatingIfNeeded: encoded >> 1) & 0x7F).unsafelyUnwrapped, signed: encoded & 1 != 0)
    }

    /// The access of an array element, packed into a `UInt8`.
    init(arrayElement encoded: UInt8) {
        self.init(storage: FieldStorage(rawValue: encoded >> 1).unsafelyUnwrapped, signed: encoded & 1 != 0)
    }

    var structField: UInt32 { UInt32(offset) << 8 | UInt32(storage.rawValue) << 1 | (signed ? 1 : 0) }
    var arrayElement: UInt8 { storage.rawValue << 1 | (signed ? 1 : 0) }
}

/// The reference type a `ref.test` or `ref.cast` checks against, packed into
/// a `UInt32`: bit 31 makes the type nullable, bit 30 means the heap type is
/// abstract, with `AbstractHeapType.rawValue` in the low bits, and otherwise
/// the low bits are a canonical type ID. Bit 29 negates the test, which
/// `br_on_cast_fail` uses.
struct CastTarget {
    let type: ReferenceType
    let negated: Bool

    private static let nullableBit: UInt32 = 1 << 31
    private static let abstractBit: UInt32 = 1 << 30
    private static let negatedBit: UInt32 = 1 << 29
    private static let payloadMask: UInt32 = (1 << 29) - 1

    init(type: ReferenceType, negated: Bool = false) {
        self.type = type
        self.negated = negated
    }

    init(encoded: UInt32) {
        let payload = encoded & Self.payloadMask
        let heapType: HeapType =
            encoded & Self.abstractBit != 0
            ? .abstract(AbstractHeapType(rawValue: UInt8(payload)).unsafelyUnwrapped) : .concrete(typeIndex: payload)
        self.type = ReferenceType(isNullable: encoded & Self.nullableBit != 0, heapType: heapType)
        self.negated = encoded & Self.negatedBit != 0
    }

    var encoded: UInt32 {
        var encoded: UInt32
        switch type.heapType {
        case .abstract(let abstract): encoded = Self.abstractBit | UInt32(abstract.rawValue)
        case .concrete(let id): encoded = id
        }
        if type.isNullable { encoded |= Self.nullableBit }
        if negated { encoded |= Self.negatedBit }
        return encoded
    }
}

extension GCHeap {
    /// Whether `value`, of a type in the target's hierarchy, is a value of the target type.
    func matches(_ value: UntypedValue, _ target: CastTarget) -> Bool {
        guard !value.isNullRef else { return target.type.isNullable }
        let storage = value.storage
        switch target.type.heapType {
        case .abstract(let abstract):
            switch abstract {
            case .any, .funcRef, .externRef, .exnRef: return true
            case .eq: return storage & 0b11 != 0b10
            case .i31: return storage & 1 == 1
            case .structRef: return storage & 0b11 == 0 && kind(of: UInt32(truncatingIfNeeded: storage)) == .structObject
            case .arrayRef: return storage & 0b11 == 0 && kind(of: UInt32(truncatingIfNeeded: storage)) == .arrayObject
            case .noneRef, .noFunc, .noExtern, .noExn: return false
            }
        case .concrete(let targetID):
            let actualID: UInt32
            if targetID & TypeRegistry.functionTypeBit != 0 {
                actualID = InternalFunction(bitPattern: Int(truncatingIfNeeded: storage)).type.id
            } else {
                guard storage & 0b11 == 0 else { return false }
                actualID = typeID(of: UInt32(truncatingIfNeeded: storage))
            }
            return actualID == targetID || typeRegistry.isSubtype(.concrete(typeIndex: actualID), of: target.type.heapType)
        }
    }
}

/// > Note:
/// <https://webassembly.github.io/gc/core/exec/instructions.html#aggregate-reference-instructions>
extension Execution {
    mutating func refTest(sp: Sp, immediate: Instruction.RefTestOperand) {
        let target = CastTarget(encoded: immediate.target)
        let matches = gcHeap.matches(sp[immediate.value], target)
        sp[immediate.result] = .i32(matches != target.negated ? 1 : 0)
    }

    mutating func refCast(sp: Sp, immediate: Instruction.RefCastOperand) throws {
        let value = sp[immediate.value]
        guard gcHeap.matches(value, CastTarget(encoded: immediate.target)) else {
            throw Trap(.castFailure)
        }
        sp[immediate.result] = value
    }

    private var gcHeap: GCHeap { store.value.allocator.gcHeap }

    /// The object a non-null reference points to.
    private func object(_ value: UntypedValue, ifNull reason: TrapReason) throws -> UInt32 {
        guard !value.isNullRef else {
            throw Trap(reason)
        }
        return UInt32(truncatingIfNeeded: value.storage)
    }

    /// Reads a value of `storage` from `slot`, and returns the slot after it.
    private func readOperand(sp: Sp, _ slot: VReg, _ storage: FieldStorage) -> (lo: UInt64, hi: UInt64, next: VReg) {
        if storage.isV128 {
            return (sp[slot].storage, sp[slot.nextSlot].storage, slot + VReg(slotIndex: 2))
        }
        return (sp[slot].storage, 0, slot.nextSlot)
    }

    private func writeResult(sp: Sp, _ slot: VReg, _ value: (lo: UInt64, hi: UInt64), _ storage: FieldStorage) {
        sp[slot] = UntypedValue(storage: value.lo)
        if storage.isV128 {
            sp[slot.nextSlot] = UntypedValue(storage: value.hi)
        }
    }

    /// Checks that `count` elements from `offset` are within `length` elements.
    private func checkArrayRange(offset: UInt32, count: UInt32, length: UInt32) throws {
        guard UInt64(offset) + UInt64(count) <= UInt64(length) else {
            throw Trap(.arrayOutOfBounds)
        }
    }

    private func safepoint(_ sp: Sp, _ map: UInt32) -> GCSafepoint {
        GCSafepoint(sp: sp, map: Int(map))
    }

    mutating func structNew(sp: Sp, immediate: Instruction.StructNewOperand) throws {
        let layout = gcHeap.typeRegistry.entry(immediate.typeID).structLayout.unsafelyUnwrapped
        let heap = gcHeap
        let object = try heap.allocateStruct(
            type: immediate.typeID, layout: layout, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        let base = heap.address(object)
        var slot = immediate.operands
        for field in layout.fields {
            let (lo, hi, next) = readOperand(sp: sp, slot, field.storage)
            field.storage.store(lo: lo, hi: hi, to: base + field.offset)
            slot = next
        }
        sp[immediate.result] = UntypedValue(storage: UInt64(object))
    }

    mutating func structNewDefault(sp: Sp, immediate: Instruction.StructNewDefaultOperand) throws {
        let layout = gcHeap.typeRegistry.entry(immediate.typeID).structLayout.unsafelyUnwrapped
        let object = try gcHeap.allocateStruct(
            type: immediate.typeID, layout: layout, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        sp[immediate.result] = UntypedValue(storage: UInt64(object))
    }

    mutating func structGet(sp: Sp, immediate: Instruction.StructGetOperand) throws {
        let object = try object(sp[immediate.object], ifNull: .nullStructReference)
        let access = GCFieldAccess(structField: immediate.field)
        let value = access.storage.load(from: gcHeap.address(object) + access.offset, signed: access.signed)
        writeResult(sp: sp, immediate.result, value, access.storage)
    }

    mutating func structSet(sp: Sp, immediate: Instruction.StructSetOperand) throws {
        let object = try object(sp[immediate.object], ifNull: .nullStructReference)
        let access = GCFieldAccess(structField: immediate.field)
        let (lo, hi, _) = readOperand(sp: sp, immediate.value, access.storage)
        access.storage.store(lo: lo, hi: hi, to: gcHeap.address(object) + access.offset)
    }

    mutating func arrayNew(sp: Sp, immediate: Instruction.ArrayNewOperand) throws {
        let element = gcHeap.typeRegistry.entry(immediate.typeID).arrayElement.unsafelyUnwrapped
        let length = sp[immediate.operands + VReg(slotIndex: element.isV128 ? 2 : 1)].i32
        let heap = gcHeap
        let array = try heap.allocateArray(
            type: immediate.typeID, element: element, count: length, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        // Read after the allocation, which may move the object a reference refers to.
        let (lo, hi, _) = readOperand(sp: sp, immediate.operands, element)
        for index in 0..<length {
            element.store(lo: lo, hi: hi, to: heap.arrayElement(array, at: index, element: element))
        }
        sp[immediate.result] = UntypedValue(storage: UInt64(array))
    }

    mutating func arrayNewDefault(sp: Sp, immediate: Instruction.ArrayNewDefaultOperand) throws {
        let element = gcHeap.typeRegistry.entry(immediate.typeID).arrayElement.unsafelyUnwrapped
        let array = try gcHeap.allocateArray(
            type: immediate.typeID, element: element, count: sp[immediate.length].i32, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        sp[immediate.result] = UntypedValue(storage: UInt64(array))
    }

    mutating func arrayNewFixed(sp: Sp, immediate: Instruction.ArrayNewFixedOperand) throws {
        let element = gcHeap.typeRegistry.entry(immediate.typeID).arrayElement.unsafelyUnwrapped
        let heap = gcHeap
        let array = try heap.allocateArray(
            type: immediate.typeID, element: element, count: immediate.count, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        var slot = immediate.operands
        for index in 0..<immediate.count {
            let (lo, hi, next) = readOperand(sp: sp, slot, element)
            element.store(lo: lo, hi: hi, to: heap.arrayElement(array, at: index, element: element))
            slot = next
        }
        sp[immediate.result] = UntypedValue(storage: UInt64(array))
    }

    mutating func arrayNewData(sp: Sp, immediate: Instruction.ArrayNewDataOperand) throws {
        let element = gcHeap.typeRegistry.entry(immediate.typeID).arrayElement.unsafelyUnwrapped
        let offset = sp[immediate.operands].i32
        let length = sp[immediate.operands.nextSlot].i32
        let data = currentInstance(sp: sp).dataSegments[Int(immediate.segmentIndex)].data
        let byteCount = UInt64(length) * UInt64(element.size)
        guard UInt64(offset) + byteCount <= UInt64(data.count) else {
            throw Trap(.memoryOutOfBounds)
        }
        let heap = gcHeap
        let array = try heap.allocateArray(
            type: immediate.typeID, element: element, count: length, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        copyData(data, from: Int(offset), to: heap.arrayElement(array, at: 0, element: element), byteCount: Int(byteCount))
        try chargeBytesCopied(byteCount)
        sp[immediate.result] = UntypedValue(storage: UInt64(array))
    }

    mutating func arrayNewElem(sp: Sp, immediate: Instruction.ArrayNewElemOperand) throws {
        let offset = sp[immediate.operands].i32
        let length = sp[immediate.operands.nextSlot].i32
        let segment = currentInstance(sp: sp).elementSegments[Int(immediate.segmentIndex)]
        guard UInt64(offset) + UInt64(length) <= UInt64(segment.references.count) else {
            throw Trap(.tableOutOfBounds(Int(offset)))
        }
        let heap = gcHeap
        let array = try heap.allocateArray(
            type: immediate.typeID, element: .reference, count: length, resourceLimiter: store.value.resourceLimiter,
            safepoint: safepoint(sp, immediate.safepoint))
        // Read after the allocation, which may move the objects the segment refers to.
        let references = segment.references
        for index in 0..<length {
            let value = UntypedValue(.ref(references[Int(offset + index)]))
            FieldStorage.reference.store(lo: value.storage, hi: 0, to: heap.arrayElement(array, at: index, element: .reference))
        }
        try chargeElementsCopied(UInt64(length))
        sp[immediate.result] = UntypedValue(storage: UInt64(array))
    }

    mutating func arrayGet(sp: Sp, immediate: Instruction.ArrayGetOperand) throws {
        let array = try object(sp[immediate.operands], ifNull: .nullArrayReference)
        let index = sp[immediate.operands.nextSlot].i32
        let heap = gcHeap
        guard index < heap.arrayLength(array) else {
            throw Trap(.arrayOutOfBounds)
        }
        let access = GCFieldAccess(arrayElement: immediate.element)
        let value = access.storage.load(from: heap.arrayElement(array, at: index, element: access.storage), signed: access.signed)
        writeResult(sp: sp, immediate.result, value, access.storage)
    }

    mutating func arraySet(sp: Sp, immediate: Instruction.ArraySetOperand) throws {
        let array = try object(sp[immediate.operands], ifNull: .nullArrayReference)
        let index = sp[immediate.operands.nextSlot].i32
        let heap = gcHeap
        guard index < heap.arrayLength(array) else {
            throw Trap(.arrayOutOfBounds)
        }
        let element = GCFieldAccess(arrayElement: immediate.element).storage
        let (lo, hi, _) = readOperand(sp: sp, immediate.operands + VReg(slotIndex: 2), element)
        element.store(lo: lo, hi: hi, to: heap.arrayElement(array, at: index, element: element))
    }

    mutating func arrayLen(sp: Sp, immediate: Instruction.ArrayLenOperand) throws {
        let array = try object(sp[immediate.array], ifNull: .nullArrayReference)
        sp[immediate.result] = .i32(gcHeap.arrayLength(array))
    }

    mutating func arrayFill(sp: Sp, immediate: Instruction.ArrayFillOperand) throws {
        let array = try object(sp[immediate.operands], ifNull: .nullArrayReference)
        let offset = sp[immediate.operands.nextSlot].i32
        let element = GCFieldAccess(arrayElement: immediate.element).storage
        let (lo, hi, lengthSlot) = readOperand(sp: sp, immediate.operands + VReg(slotIndex: 2), element)
        let count = sp[lengthSlot].i32
        let heap = gcHeap
        try checkArrayRange(offset: offset, count: count, length: heap.arrayLength(array))
        for index in offset..<(offset + count) {
            element.store(lo: lo, hi: hi, to: heap.arrayElement(array, at: index, element: element))
        }
        try chargeElementsCopied(UInt64(count))
    }

    mutating func arrayCopy(sp: Sp, immediate: Instruction.ArrayCopyOperand) throws {
        let operands = immediate.operands
        let destination = try object(sp[operands], ifNull: .nullArrayReference)
        let destinationOffset = sp[operands + VReg(slotIndex: 1)].i32
        let source = try object(sp[operands + VReg(slotIndex: 2)], ifNull: .nullArrayReference)
        let sourceOffset = sp[operands + VReg(slotIndex: 3)].i32
        let count = sp[operands + VReg(slotIndex: 4)].i32
        let heap = gcHeap
        try checkArrayRange(offset: destinationOffset, count: count, length: heap.arrayLength(destination))
        try checkArrayRange(offset: sourceOffset, count: count, length: heap.arrayLength(source))
        let element = GCFieldAccess(arrayElement: immediate.element).storage
        // The ranges may overlap, which `copyMemory` allows.
        heap.arrayElement(destination, at: destinationOffset, element: element).copyMemory(
            from: heap.arrayElement(source, at: sourceOffset, element: element), byteCount: Int(count) * element.size)
        try chargeElementsCopied(UInt64(count))
    }

    mutating func arrayInitData(sp: Sp, immediate: Instruction.ArrayInitDataOperand) throws {
        let operands = immediate.operands
        let array = try object(sp[operands], ifNull: .nullArrayReference)
        let destinationOffset = sp[operands + VReg(slotIndex: 1)].i32
        let sourceOffset = sp[operands + VReg(slotIndex: 2)].i32
        let count = sp[operands + VReg(slotIndex: 3)].i32
        let heap = gcHeap
        try checkArrayRange(offset: destinationOffset, count: count, length: heap.arrayLength(array))
        let element = GCFieldAccess(arrayElement: immediate.element).storage
        let data = currentInstance(sp: sp).dataSegments[Int(immediate.segmentIndex)].data
        let byteCount = UInt64(count) * UInt64(element.size)
        guard UInt64(sourceOffset) + byteCount <= UInt64(data.count) else {
            throw Trap(.memoryOutOfBounds)
        }
        copyData(data, from: Int(sourceOffset), to: heap.arrayElement(array, at: destinationOffset, element: element), byteCount: Int(byteCount))
        try chargeBytesCopied(byteCount)
    }

    mutating func arrayInitElem(sp: Sp, immediate: Instruction.ArrayInitElemOperand) throws {
        let operands = immediate.operands
        let array = try object(sp[operands], ifNull: .nullArrayReference)
        let destinationOffset = sp[operands + VReg(slotIndex: 1)].i32
        let sourceOffset = sp[operands + VReg(slotIndex: 2)].i32
        let count = sp[operands + VReg(slotIndex: 3)].i32
        let heap = gcHeap
        try checkArrayRange(offset: destinationOffset, count: count, length: heap.arrayLength(array))
        let references = currentInstance(sp: sp).elementSegments[Int(immediate.segmentIndex)].references
        guard UInt64(sourceOffset) + UInt64(count) <= UInt64(references.count) else {
            throw Trap(.tableOutOfBounds(Int(sourceOffset)))
        }
        for index in 0..<count {
            let value = UntypedValue(.ref(references[Int(sourceOffset + index)]))
            FieldStorage.reference.store(
                lo: value.storage, hi: 0, to: heap.arrayElement(array, at: destinationOffset + index, element: .reference))
        }
        try chargeElementsCopied(UInt64(count))
    }

    /// Copies bytes of a data segment into an array. The elements of an array
    /// are little-endian like the data.
    private func copyData(_ data: ArraySlice<UInt8>, from offset: Int, to destination: UnsafeMutableRawPointer, byteCount: Int) {
        guard byteCount > 0 else { return }
        data.withUnsafeBytes { bytes in
            destination.copyMemory(from: bytes.baseAddress.unsafelyUnwrapped + offset, byteCount: byteCount)
        }
    }
}
