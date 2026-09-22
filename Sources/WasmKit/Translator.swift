import WasmParser
import WasmTypes

class ISeqAllocator {

    private var buffers: [UnsafeMutableRawBufferPointer] = []

    func allocateBrTable(capacity: Int) -> UnsafeMutableBufferPointer<Instruction.BrTableOperand.Entry> {
        assert(_isPOD(Instruction.BrTableOperand.Entry.self), "Instruction.BrTableOperand.Entry must be POD")
        let buffer = UnsafeMutableBufferPointer<Instruction.BrTableOperand.Entry>.allocate(capacity: capacity)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return buffer
    }

    func allocateCatchTable(capacity: Int) -> UnsafeMutableBufferPointer<CatchTableEntry> {
        assert(_isPOD(CatchTableEntry.self), "CatchTableEntry must be POD")
        let buffer = UnsafeMutableBufferPointer<CatchTableEntry>.allocate(capacity: capacity)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return buffer
    }

    /// Allocates the frame-initialisation image of a function: `localSlots`
    /// slots holding the default values of the non-parameter locals (zero, or
    /// null for the slots listed in `nullReferenceSlots`) followed by the
    /// constant pool.
    func allocateFrameInit(
        localSlots: Int, nullReferenceSlots: [Int], constants: [UntypedValue]
    ) -> UnsafeBufferPointer<UntypedValue> {
        let buffer = UnsafeMutableBufferPointer<UntypedValue>.allocate(capacity: localSlots + constants.count)
        buffer.initialize(repeating: UntypedValue.default)
        for slot in nullReferenceSlots {
            buffer[slot] = UntypedValue.nullReference
        }
        _ = UnsafeMutableBufferPointer(rebasing: buffer[localSlots...]).initialize(fromContentsOf: constants)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return UnsafeBufferPointer(buffer)
    }

    func allocateInstructions(capacity: Int) -> UnsafeMutableBufferPointer<UInt64> {
        assert(_isPOD(Instruction.self), "Instruction must be POD")
        let buffer = UnsafeMutableBufferPointer<UInt64>.allocate(capacity: capacity)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return buffer
    }

    deinit {
        for buffer in buffers {
            buffer.deallocate()
        }
    }
}

extension InternalInstance {
    func addressType(memoryIndex: MemoryIndex) throws(WasmKitError) -> ValueType {
        return ValueType.addressType(isMemory64: try isMemory64(memoryIndex: memoryIndex))
    }
    func addressType(tableIndex: TableIndex) throws(WasmKitError) -> ValueType {
        return ValueType.addressType(isMemory64: try isMemory64(tableIndex: tableIndex))
    }
    func validateElementSegment(_ index: ElementIndex) throws(WasmKitError) {
        _ = try elementType(index)
    }

    func resolveType(_ index: TypeIndex) throws(WasmKitError) -> FunctionType {
        guard Int(index) < self.types.count else {
            throw WasmKitError(message: .indexOutOfBounds("type", index, max: UInt32(self.types.count)))
        }
        return self.types[Int(index)]
    }
    func resolveBlockType(_ blockType: BlockType) throws(WasmKitError) -> FunctionType {
        if case .type(let valueType) = blockType {
            return FunctionType(parameters: [], results: [try typeCanonicalizer.canonicalize(valueType)])
        }
        return try FunctionType(blockType: blockType, typeSection: self.types)
    }
    func functionType(_ index: FunctionIndex, interner: Interner<FunctionType>) throws(WasmKitError) -> FunctionType {
        return try interner.resolve(self.functions[validating: Int(index)].type)
    }
    func globalType(_ index: GlobalIndex) throws(WasmKitError) -> ValueType {
        let globalTypes = self.globalTypes
        guard Int(index) < globalTypes.count else {
            throw GlobalEntity.createOutOfBoundsError(index: Int(index), count: globalTypes.count)
        }
        return globalTypes[Int(index)].valueType
    }
    func isMemory64(memoryIndex index: MemoryIndex) throws(WasmKitError) -> Bool {
        let memory = try self.memories[validating: Int(index), MemoryEntity.createOutOfBoundsError]
        return memory.withValue { $0.limit.isMemory64 }
    }
    func isMemory64(tableIndex index: TableIndex) throws(WasmKitError) -> Bool {
        return try self.tables[validating: Int(index)].limits.isMemory64
    }
    func tableType(_ index: TableIndex) throws(WasmKitError) -> TableType {
        return try self.tables[validating: Int(index)].tableType
    }
    func elementType(_ index: ElementIndex) throws(WasmKitError) -> ReferenceType {
        try self.elementSegments[validating: Int(index)].type
    }

    func resolveCallee(_ index: FunctionIndex) -> InternalFunction? {
        return self.functions[Int(index)]
    }
    func resolveGlobal(_ index: GlobalIndex) -> InternalGlobal? {
        return self.globals[Int(index)]
    }
    func isSameInstance(_ instance: InternalInstance) -> Bool {
        return instance == self
    }
    func validateFunctionIndex(_ index: FunctionIndex) throws(WasmKitError) {
        let function = try self.functions[validating: Int(index)]
        guard self.functionRefs.contains(function) else {
            throw WasmKitError(message: .functionIndexNotDeclared(index: index))
        }
    }
    var dataCount: UInt32? {
        self.withValue { $0.dataCount }
    }
}

private struct MetaProgramCounter {
    let offsetFromHead: Int
}

/// The layout of the function stack frame.
///
/// A function call frame starts with a "frame header" which contains
/// the function parameters and the result values. The size of the frame
/// header is determined by the maximum number of parameters and results
/// of the function type. While executing the function, the frame header
/// is used as a storage for parameters. On function return, the frame
/// header is used as a storage for the result values.
///
/// On function entry, the stack frame looks like:
///
/// ```
/// | Offset                             | Description          |
/// |------------------------------------|----------------------|
/// | 0                                  | Function parameter 0 |
/// | 1                                  | Function parameter 1 |
/// | ...                                | ...                  |
/// | len(params)-1                      | Function parameter N |
/// ```
///
/// On function return, the stack frame looks like:
/// ```
/// | Offset                             | Description          |
/// |------------------------------------|----------------------|
/// | 0                                  | Function result 0    |
/// | 1                                  | Function result 1    |
/// | ...                                | ...                  |
/// | len(results)-1                     | Function result N    |
/// ```
///
/// The end of the frame header is usually referred to as "stack pointer"
/// (SP). "local" variables and the value stack space are allocated after
/// the frame header. The value stack space is used to store intermediate
/// values usually corresponding to Wasm's value stack. Unlike the Wasm's
/// value stack, a value slot in the value stack space might be absent if
/// the value is backed by a local variable.
/// The slot index is referred to as "register". The register index is
/// relative to the stack pointer, so the register indices for parameters
/// and results are negative.
///
/// ```
/// | Offset                             | Description          |
/// |------------------------------------|----------------------|
/// | SP-(max(params, results)+3)        | Param/result slots   |------+
/// | ...                                | ...                  |      |
/// | SP-3                               | Saved Instance       |  Frame header
/// | SP-2                               | Saved PC             |      |
/// | SP-1                               | Saved SP             |------+
/// | SP+0                               | Local variable 0     |
/// | SP+1                               | Local variable 1     |
/// | ...                                | ...                  |
/// | SP+len(locals)-1                   | Local variable N     |
/// | SP+len(locals)                     | Const 0              |
/// | SP+len(locals)+1                   | Const 1              |
/// | ...                                | ...                  |
/// | SP+len(locals)+C                   | Const C              |
/// | SP+len(locals)+C                   | Value stack 0        |
/// | SP+len(locals)+C+1                 | Value stack 1        |
/// | ...                                | ...                  |
/// | SP+len(locals)+C+heighest(stack)-1 | Value stack N        |
/// ```
/// where `C` is the number of constant slots.
///
/// ## Example
///
/// Consider the following Wasm function:
///
/// ```wat
/// (func (param i32 i32) (result i32)
///   (local i32)
///   (local i64)
///   (local.set 2 (i32.add (local.get 0) (i32.const 42)))
///   (return (local.get 2))
/// )
/// ```
///
/// Then the stack frame layout looks like:
///
/// ```
/// | Offset                             | Description          |
/// |------------------------------------|----------------------|
/// | -5                                 | Param 0 / Result 0   |------+
/// | -4                                 | Param 1              |      |
/// | -3                                 | Saved Instance       |  Frame header
/// | -2                                 | Saved PC             |      |
/// | -1                                 | Saved SP             |------+
/// | 0                                  | Local 0 (i32)        |
/// | 1                                  | Local 1 (i64)        |
/// | 2                                  | Const 0 (i32:42)     |
/// ```

struct FrameHeaderLayout {
    let type: FunctionType
    /// The number of slots the frame header occupies, i.e. the distance from the
    /// start of the header to `sp`.
    let size: Int
    private let paramSlotOffsets: [Int]
    private let resultSlotOffsets: [Int]

    init(type: FunctionType) {
        self.type = type
        self.paramSlotOffsets = Self.slotOffsets(of: type.parameters)
        self.resultSlotOffsets = Self.slotOffsets(of: type.results)
        self.size = Self.size(of: type, paramSlotOffsets: paramSlotOffsets, resultSlotOffsets: resultSlotOffsets)
    }

    func paramReg(_ index: Int) -> VReg {
        VReg(slotIndex: paramSlotOffsets[index] - size)
    }

    func returnReg(_ index: Int) -> VReg {
        VReg(slotIndex: resultSlotOffsets[index] - size)
    }

    internal static func size(of: FunctionType) -> Int {
        let paramSlotOffsets = Self.slotOffsets(of: of.parameters)
        let resultSlotOffsets = Self.slotOffsets(of: of.results)
        return Self.size(of: of, paramSlotOffsets: paramSlotOffsets, resultSlotOffsets: resultSlotOffsets)
    }
    private static func size(
        of type: FunctionType,
        paramSlotOffsets: [Int],
        resultSlotOffsets: [Int]
    ) -> Int {
        let paramSlots = (paramSlotOffsets.last ?? 0) + (type.parameters.last?.stackSlotCount ?? 0)
        let resultSlots = (resultSlotOffsets.last ?? 0) + (type.results.last?.stackSlotCount ?? 0)
        return max(paramSlots, resultSlots) + numberOfSavingSlots
    }

    private static func slotOffsets(of types: [WasmTypes.ValueType]) -> [Int] {
        var offsets: [Int] = []
        offsets.reserveCapacity(types.count)
        var next = 0
        for t in types {
            offsets.append(next)
            next += t.stackSlotCount
        }
        return offsets
    }
    /// The number of slots used to save the current instance, PC, and SP
    internal static var numberOfSavingSlots: Int { 3 }

    /// Rejects a frame header that a ``VReg`` cannot address.
    ///
    /// A Wasm function's whole frame is checked when it is translated
    /// (`InstructionTranslator.checkFrameFitsVRegRange`); this is for the paths
    /// that build a frame header from a ``FunctionType`` without translating
    /// anything, namely host-function calls and the root frame of an invocation.
    internal static func checkFitsVRegRange(_ size: Int) throws {
        guard VReg.canRepresent(slotIndex: -size) else {
            throw Trap(
                .message(
                    .init(
                        "The frame header of this function type is too large for the interpreter: "
                            + "\(size) slots, but only \(-VReg.minSlotIndex) are addressable"
                    )
                )
            )
        }
    }
}

struct StackLayout {
    let frameHeader: FrameHeaderLayout
    let constantSlotSize: Int
    let localTypes: [WasmTypes.ValueType]
    private let nonParameterLocalSlotOffsets: [Int]
    let numberOfNonParameterLocalSlots: Int

    /// The slot index of the first value-stack slot, i.e. right after the
    /// locals and the constant pool.
    var stackRegBaseSlotIndex: Int {
        return numberOfNonParameterLocalSlots + constantSlotSize
    }

    var stackRegBase: VReg {
        return VReg(slotIndex: stackRegBaseSlotIndex)
    }

    init(type: FunctionType, locals: [WasmTypes.ValueType], codeSize: Int) throws(WasmKitError) {
        self.frameHeader = FrameHeaderLayout(type: type)
        self.localTypes = locals
        self.nonParameterLocalSlotOffsets = Self.slotOffsets(of: locals)
        self.numberOfNonParameterLocalSlots =
            (nonParameterLocalSlotOffsets.last ?? 0) + (locals.last?.stackSlotCount ?? 0)
        // The number of constant slots is determined by the code size
        // This is a heuristic value to balance the fast access to constants
        // and the size of stack frame. Cap the slot size to avoid size explosion.
        self.constantSlotSize = min(max(codeSize / 20, 4), 128)
        let (maxSlots, overflow) = self.constantSlotSize.addingReportingOverflow(numberOfNonParameterLocalSlots)
        guard !overflow, VReg.canRepresent(slotIndex: maxSlots) else {
            // The locals and the constant pool alone already reach past what a
            // `VReg` can address. See ``VReg`` for the range and why it is small.
            throw WasmKitError(
                "The frame of this function is too large for the interpreter: its locals and constant pool "
                    + "need \(maxSlots) slots, but only \(VReg.maxSlotIndex) are addressable"
            )
        }
    }

    func localReg(_ index: LocalIndex) -> VReg {
        if isParameter(index) {
            return frameHeader.paramReg(Int(index))
        } else {
            let nonParamIndex = Int(index) - frameHeader.type.parameters.count
            return VReg(slotIndex: nonParameterLocalSlotOffsets[nonParamIndex])
        }
    }

    func isParameter(_ index: LocalIndex) -> Bool {
        index < frameHeader.type.parameters.count
    }

    /// The slot indices of the non-parameter locals holding references, which
    /// start out null rather than zero.
    var nonParameterReferenceLocalSlots: [Int] {
        zip(localTypes, nonParameterLocalSlotOffsets).compactMap { type, offset in
            guard case .ref = type else { return nil }
            return offset
        }
    }

    func constReg(_ index: Int) -> VReg {
        return VReg(slotIndex: numberOfNonParameterLocalSlots + index)
    }

    #if Disassembler
        func dump<Target: TextOutputStream>(to target: inout Target, iseq: InstructionSequence) {
            let frameHeaderSize = FrameHeaderLayout.size(of: frameHeader.type)
            let slotMinIndex = -frameHeaderSize
            let slotMaxIndex = stackRegBaseSlotIndex - 1
            let slotIndexWidth = max(String(slotMinIndex).count, String(slotMaxIndex).count)
            func writeSlot(_ target: inout Target, _ index: Int, _ description: String) {
                var index = String(index)
                index = String(repeating: " ", count: slotIndexWidth - index.count) + index

                target.write(" [\(index)] \(description)\n")
            }
            func hex(_ value: UInt64) -> String {
                let value = String(value, radix: 16)
                return String(repeating: "0", count: 16 - value.count) + value
            }

            let savedItems: [String] = ["Instance", "Pc", "Sp"]
            for i in 0..<frameHeaderSize - savedItems.count {
                var descriptions: [String] = []
                if i < frameHeader.type.parameters.count {
                    descriptions.append("Param \(i)")
                }
                if i < frameHeader.type.results.count {
                    descriptions.append("Result \(i)")
                }
                writeSlot(&target, i - frameHeaderSize, descriptions.joined(separator: ", "))
            }

            for (i, name) in savedItems.enumerated() {
                writeSlot(&target, i - savedItems.count, "Saved \(name)")
            }

            var localSlot = 0
            for (i, t) in localTypes.enumerated() {
                writeSlot(&target, localSlot, "Local \(i) (\(t))")
                localSlot += t.stackSlotCount
            }
            for i in 0..<(iseq.frameInit.count - numberOfNonParameterLocalSlots) {
                let value = iseq.frameInit[numberOfNonParameterLocalSlots + i]
                writeSlot(&target, numberOfNonParameterLocalSlots + i, "Const \(i) = \(value)")
            }
        }
    #endif  // Disassembler

    private static func slotOffsets(of types: [WasmTypes.ValueType]) -> [Int] {
        var offsets: [Int] = []
        offsets.reserveCapacity(types.count)
        var next = 0
        for t in types {
            offsets.append(next)
            next += t.stackSlotCount
        }
        return offsets
    }
}

struct InstructionTranslator: ~Copyable, InstructionVisitor {
    typealias VisitorError = WasmKitError
    typealias Output = Void

    typealias LabelRef = Int
    typealias ValueType = WasmTypes.ValueType

    /// The fuel meter of a region being translated, when the engine meters fuel.
    ///
    /// A "region" is a stretch of code that always runs from its head: a function body, a loop
    /// body, or one arm of an `if`. Each one is charged once, up front, by a `consumeFuel`
    /// instruction at its head whose immediate is the summed cost of the operators inside it.
    /// The cost is only known once the region has been translated, so the instruction is emitted
    /// with a zero immediate and patched at `meter` when the region closes.
    fileprivate struct FuelRegion {
        /// Position of the region's `consumeFuel` instruction.
        let meter: MetaProgramCounter
        /// Summed cost of the operators translated into this region so far.
        var cost: UInt64
    }

    struct ControlStack {
        typealias BlockType = FunctionType

        struct ControlFrame {
            enum Kind {
                case block(root: Bool)
                case loop
                case `if`(elseLabel: LabelRef, endLabel: LabelRef, isElse: Bool)
                case tryTable(catchCount: UInt16)

                static var block: Kind { .block(root: false) }
            }

            let blockType: BlockType
            /// The logical value height of `ValueStack` without including the frame parameters.
            let valueStackHeight: Int
            /// The physical slot height of `ValueStack` without including the frame parameters.
            let slotStackHeight: Int
            let continuation: LabelRef
            var kind: Kind
            var reachable: Bool = true
            /// Set when this frame opened a fuel region: the state to restore when it closes.
            ///
            /// `nil` for frames that share their parent's meter (`block`, `try_table`) and for
            /// every frame when the engine does not meter fuel.
            fileprivate var fuelRegion: FuelRegion? = nil
            /// The enclosing region, saved while this frame's region is the current one.
            fileprivate var enclosingFuelRegion: FuelRegion? = nil

            var copyTypes: [ValueType] {
                switch self.kind {
                case .block, .if, .tryTable:
                    return blockType.results
                case .loop:
                    return blockType.parameters
                }
            }
            var copySlotCount: UInt16 {
                UInt16(copyTypes.reduce(into: 0) { $0 += $1.stackSlotCount })
            }
        }

        private var frames: [ControlFrame] = []

        var numberOfFrames: Int { frames.count }

        mutating func pushFrame(_ frame: ControlFrame) {
            self.frames.append(frame)
        }

        mutating func popFrame() -> ControlFrame? {
            self.frames.popLast()
        }

        mutating func markUnreachable() throws(WasmKitError) {
            try setReachability(false)
        }
        mutating func resetReachability() throws(WasmKitError) {
            try setReachability(true)
        }

        private mutating func setReachability(_ value: Bool) throws(WasmKitError) {
            guard !self.frames.isEmpty else {
                throw WasmKitError(message: .controlStackEmpty)
            }
            self.frames[self.frames.count - 1].reachable = value
        }

        /// Whether the operators being translated right now will ever run.
        ///
        /// Reads the flag in place rather than copying the frame, because fuel metering consults
        /// it once per operator.
        var isCurrentFrameReachable: Bool {
            self.frames.last?.reachable ?? false
        }

        /// Records the fuel region opened by the frame on top of the stack.
        fileprivate mutating func setCurrentFuelRegion(_ region: FuelRegion, enclosing: FuelRegion?) {
            guard !self.frames.isEmpty else { return }
            self.frames[self.frames.count - 1].fuelRegion = region
            self.frames[self.frames.count - 1].enclosingFuelRegion = enclosing
        }

        func currentFrame() throws(WasmKitError) -> ControlFrame {
            guard let frame = self.frames.last else {
                throw WasmKitError(message: .controlStackEmpty)
            }
            return frame
        }

        func branchTarget(relativeDepth: UInt32) throws(WasmKitError) -> ControlFrame {
            let index = frames.count - 1 - Int(relativeDepth)
            guard frames.indices.contains(index) else {
                throw WasmKitError(message: .relativeDepthOutOfRange(relativeDepth: relativeDepth))
            }
            return frames[index]
        }

        /// Count the total number of catch handlers that would be exited when
        /// branching to the given relative depth.
        func catchHandlersToUnwind(relativeDepth: UInt32) -> UInt16 {
            var count: UInt16 = 0
            let targetIndex = frames.count - 1 - Int(relativeDepth)
            for i in (targetIndex..<frames.count).reversed() {
                if case .tryTable(let catchCount) = frames[i].kind {
                    count += catchCount
                }
            }
            return count
        }
    }

    enum MetaValue: Equatable {
        case some(ValueType)
        case unknown
    }

    enum MetaValueOnStack {
        case local(ValueType, LocalIndex)
        case stack(MetaValue)
        /// A constant, which gets a constant-pool slot only when it is read as
        /// a register operand.
        case const(ValueType, UntypedValue)

        var type: MetaValue {
            switch self {
            case .local(let type, _): return .some(type)
            case .stack(let type): return type
            case .const(let type, _): return .some(type)
            }
        }
    }

    enum ValueSource {
        case vreg(VReg)
        case const(UntypedValue, ValueType)
        case local(LocalIndex)

        /// The register when the value is a materialized stack temporary.
        var stackRegister: VReg? {
            guard case .vreg(let register) = self else { return nil }
            return register
        }

        /// The constant's bits when the value is a constant.
        var constant: UInt64? {
            guard case .const(let value, _) = self else { return nil }
            return value.storage
        }
    }

    struct ValueStack {
        private var values: [MetaValueOnStack] = []
        private var startSlotOffsets: [Int] = []
        /// The current physical slot height of the stack (excluding locals/const pool base).
        private(set) var slotHeight: Int = 0
        /// The maximum physical slot height of the stack within the function.
        private(set) var maxSlotHeight: Int = 0
        /// The current logical value height of the stack.
        var valueHeight: Int { values.count }
        let stackRegBase: VReg
        let stackLayout: StackLayout

        init(stackLayout: StackLayout) {
            self.stackRegBase = stackLayout.stackRegBase
            self.stackLayout = stackLayout
        }

        mutating func push(_ value: ValueType) -> VReg {
            push(.some(value))
        }
        mutating func push(_ value: MetaValue) -> VReg {
            // Record the maximum height of the stack we have seen
            let type = value.concreteType
            let width = type?.stackSlotCount ?? 1
            maxSlotHeight = max(maxSlotHeight, slotHeight + width)
            let usedSlotOffset = slotHeight
            self.values.append(.stack(value))
            self.startSlotOffsets.append(usedSlotOffset)
            self.slotHeight += width
            assert(valueHeight < UInt16.max)
            return stackRegBase + VReg(slotIndex: usedSlotOffset)
        }
        mutating func pushLocal(_ localIndex: LocalIndex, locals: inout Locals) throws(WasmKitError) {
            let type = try locals.type(of: localIndex)
            self.values.append(.local(type, localIndex))
            self.startSlotOffsets.append(slotHeight)
            self.slotHeight += type.stackSlotCount
            maxSlotHeight = max(maxSlotHeight, slotHeight)
        }
        mutating func pushConst(_ value: UntypedValue, type: ValueType) {
            self.values.append(.const(type, value))
            self.startSlotOffsets.append(slotHeight)
            self.slotHeight += type.stackSlotCount
            maxSlotHeight = max(maxSlotHeight, slotHeight)
        }
        mutating func preserveLocalsOnStack(_ localIndex: LocalIndex) -> [(to: VReg, type: ValueType)] {
            var copyTo: [(to: VReg, type: ValueType)] = []
            for i in 0..<values.count {
                guard case .local(let type, localIndex) = self.values[i] else { continue }
                self.values[i] = .stack(.some(type))
                copyTo.append((to: stackRegBase + VReg(slotIndex: startSlotOffsets[i]), type: type))
            }
            return copyTo
        }

        mutating func preserveLocalsOnStack(depth: Int) -> [(source: LocalIndex, to: VReg, type: ValueType)] {
            var copies: [(source: LocalIndex, to: VReg, type: ValueType)] = []
            for offset in 0..<min(depth, self.valueHeight) {
                let valueIndex = self.values.count - 1 - offset
                let value = self.values[valueIndex]
                guard case .local(let type, let localIndex) = value else { continue }
                self.values[valueIndex] = .stack(.some(type))
                copies.append((localIndex, self.stackRegBase + VReg(slotIndex: startSlotOffsets[valueIndex]), type))
            }
            return copies
        }

        mutating func preserveConstsOnStack(depth: Int) -> [(value: UntypedValue, to: VReg, type: ValueType)] {
            var copies: [(value: UntypedValue, to: VReg, type: ValueType)] = []
            for offset in 0..<min(depth, self.valueHeight) {
                let valueIndex = self.values.count - 1 - offset
                let value = self.values[valueIndex]
                guard case .const(let type, let constant) = value else { continue }
                self.values[valueIndex] = .stack(.some(type))
                copies.append((constant, self.stackRegBase + VReg(slotIndex: startSlotOffsets[valueIndex]), type))
            }
            return copies
        }

        /// Whether the value at `index` already lives in its physical slot,
        /// rather than being a reference to a local or a constant slot.
        func isMaterialized(at index: Int) -> Bool {
            guard case .stack = values[index] else { return false }
            return true
        }

        func peek(depth: Int) -> ValueSource {
            return makeValueSource(valueIndexFromTop: depth)
        }

        func peekType(depth: Int) -> MetaValue {
            return self.values[valueHeight - 1 - depth].type
        }

        private func makeValueSource(valueIndexFromTop depth: Int) -> ValueSource {
            let valueIndex = valueHeight - 1 - depth
            let value = values[valueIndex]
            let source: ValueSource
            switch value {
            case .local(_, let localIndex):
                source = .local(localIndex)
            case .stack:
                source = .vreg(stackRegBase + VReg(slotIndex: startSlotOffsets[valueIndex]))
            case .const(let type, let constant):
                source = .const(constant, type)
            }
            return source
        }

        mutating func pop() throws(WasmKitError) -> (MetaValue, ValueSource) {
            guard let value = self.values.popLast() else {
                throw WasmKitError("Expected a value on stack but it's empty")
            }
            guard let startSlotOffset = self.startSlotOffsets.popLast() else {
                throw WasmKitError("Internal consistency error: missing slot offset")
            }
            let width = value.type.concreteType?.stackSlotCount ?? 1
            self.slotHeight -= width
            let source: ValueSource
            switch value {
            case .local(_, let localIndex):
                source = .local(localIndex)
            case .stack:
                source = .vreg(stackRegBase + VReg(slotIndex: startSlotOffset))
            case .const(let type, let constant):
                source = .const(constant, type)
            }
            return (value.type, source)
        }
        mutating func pop(_ expected: ValueType) throws(WasmKitError) -> ValueSource {
            let (value, register) = try pop()
            switch value {
            case .some(let actual):
                guard actual == expected else {
                    throw WasmKitError("Expected \(expected) on the stack top but got \(actual)")
                }
            case .unknown: break  // OK
            }
            return register
        }
        mutating func popRef() throws(WasmKitError) -> ValueSource {
            let (value, register) = try pop()
            switch value {
            case .some(let actual):
                guard case .ref = actual else {
                    throw WasmKitError("Expected reference value on the stack top but got \(actual)")
                }
            case .unknown: break  // OK
            }
            return register
        }
        mutating func truncate(height: Int) throws(WasmKitError) {
            guard height <= self.valueHeight else {
                throw WasmKitError("Truncating to \(height) but the stack height is \(self.valueHeight)")
            }
            while height != self.valueHeight {
                _ = try pop()
            }
        }
    }

    /// An integer comparison that the ISA has a fused compare+branch form for.
    ///
    /// The complement of an integer comparison is another integer comparison,
    /// so `br_if_not` can be fused by flipping the operator. Float comparisons
    /// have no complement (NaN makes both a comparison and its "opposite"
    /// false) and use ``FusedFCmpKind`` instead.
    fileprivate enum FusedCmpKind {
        case i32Eq, i32Ne, i32LtS, i32LtU, i32GtS, i32GtU, i32LeS, i32LeU, i32GeS, i32GeU
        case i64Eq, i64Ne, i64LtS, i64LtU, i64GtS, i64GtU, i64LeS, i64LeU, i64GeS, i64GeU

        /// The comparison that holds exactly when this one does not.
        var complement: FusedCmpKind {
            switch self {
            case .i32Eq: return .i32Ne
            case .i32Ne: return .i32Eq
            case .i32LtS: return .i32GeS
            case .i32LtU: return .i32GeU
            case .i32GtS: return .i32LeS
            case .i32GtU: return .i32LeU
            case .i32LeS: return .i32GtS
            case .i32LeU: return .i32GtU
            case .i32GeS: return .i32LtS
            case .i32GeU: return .i32LtU
            case .i64Eq: return .i64Ne
            case .i64Ne: return .i64Eq
            case .i64LtS: return .i64GeS
            case .i64LtU: return .i64GeU
            case .i64GtS: return .i64LeS
            case .i64GtU: return .i64LeU
            case .i64LeS: return .i64GtS
            case .i64LeU: return .i64GtU
            case .i64GeS: return .i64LtS
            case .i64GeU: return .i64LtU
            }
        }

        /// The comparison that holds exactly when this one does with its
        /// operands exchanged (`a < b` is `b > a`).
        var swapped: FusedCmpKind {
            switch self {
            case .i32Eq: return .i32Eq
            case .i32Ne: return .i32Ne
            case .i32LtS: return .i32GtS
            case .i32LtU: return .i32GtU
            case .i32GtS: return .i32LtS
            case .i32GtU: return .i32LtU
            case .i32LeS: return .i32GeS
            case .i32LeU: return .i32GeU
            case .i32GeS: return .i32LeS
            case .i32GeU: return .i32LeU
            case .i64Eq: return .i64Eq
            case .i64Ne: return .i64Ne
            case .i64LtS: return .i64GtS
            case .i64LtU: return .i64GtU
            case .i64GtS: return .i64LtS
            case .i64GtU: return .i64LtU
            case .i64LeS: return .i64GeS
            case .i64LeU: return .i64GeU
            case .i64GeS: return .i64LeS
            case .i64GeU: return .i64LeU
            }
        }

        var operandType: ValueType {
            switch self {
            case .i32Eq, .i32Ne, .i32LtS, .i32LtU, .i32GtS, .i32GtU, .i32LeS, .i32LeU, .i32GeS, .i32GeU:
                return .i32
            case .i64Eq, .i64Ne, .i64LtS, .i64LtU, .i64GtS, .i64GtU, .i64LeS, .i64LeU, .i64GeS, .i64GeU:
                return .i64
            }
        }

        /// The fused `select` on this comparison of two slots. Predicates
        /// without an opcode exchange the candidates or the operands.
        func makeSelect(lhs: VReg, rhs: VReg, onTrue: VReg, onFalse: VReg) -> (VReg) -> Instruction {
            switch self {
            case .i32Eq: return { .selectI32Eq(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i32LtS: return { .selectI32LtS(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i32LtU: return { .selectI32LtU(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i64Eq: return { .selectI64Eq(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i64LtS: return { .selectI64LtS(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i64LtU: return { .selectI64LtU(.init(result: $0, lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)) }
            case .i32GtS, .i32GtU, .i64GtS, .i64GtU:
                return swapped.makeSelect(lhs: rhs, rhs: lhs, onTrue: onTrue, onFalse: onFalse)
            case .i32Ne, .i32GeS, .i32GeU, .i32LeS, .i32LeU, .i64Ne, .i64GeS, .i64GeU, .i64LeS, .i64LeU:
                return complement.makeSelect(lhs: lhs, rhs: rhs, onTrue: onFalse, onFalse: onTrue)
            }
        }

        /// The fused `select` on this comparison against a constant.
        /// Predicates without an opcode exchange the candidates.
        func makeSelectImm(lhs: VReg, imm: Int32, onTrue: VReg, onFalse: VReg) -> (VReg) -> Instruction {
            switch self {
            case .i32Eq: return { .selectI32EqImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i32LtS: return { .selectI32LtSImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i32LtU: return { .selectI32LtUImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i32GtS: return { .selectI32GtSImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i32GtU: return { .selectI32GtUImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i64Eq: return { .selectI64EqImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i64LtS: return { .selectI64LtSImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i64LtU: return { .selectI64LtUImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i64GtS: return { .selectI64GtSImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i64GtU: return { .selectI64GtUImm(.init(result: $0, lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)) }
            case .i32Ne, .i32GeS, .i32GeU, .i32LeS, .i32LeU, .i64Ne, .i64GeS, .i64GeU, .i64LeS, .i64LeU:
                return complement.makeSelectImm(lhs: lhs, imm: imm, onTrue: onFalse, onFalse: onTrue)
            }
        }

        /// The comparison against a constant.
        var makeCmpImm: (Instruction.BinaryImmOperand) -> Instruction {
            switch self {
            case .i32Eq: return Instruction.i32EqImm
            case .i32Ne: return Instruction.i32NeImm
            case .i32LtS: return Instruction.i32LtSImm
            case .i32LtU: return Instruction.i32LtUImm
            case .i32GtS: return Instruction.i32GtSImm
            case .i32GtU: return Instruction.i32GtUImm
            case .i32LeS: return Instruction.i32LeSImm
            case .i32LeU: return Instruction.i32LeUImm
            case .i32GeS: return Instruction.i32GeSImm
            case .i32GeU: return Instruction.i32GeUImm
            case .i64Eq: return Instruction.i64EqImm
            case .i64Ne: return Instruction.i64NeImm
            case .i64LtS: return Instruction.i64LtSImm
            case .i64LtU: return Instruction.i64LtUImm
            case .i64GtS: return Instruction.i64GtSImm
            case .i64GtU: return Instruction.i64GtUImm
            case .i64LeS: return Instruction.i64LeSImm
            case .i64LeU: return Instruction.i64LeUImm
            case .i64GeS: return Instruction.i64GeSImm
            case .i64GeU: return Instruction.i64GeUImm
            }
        }

        /// The fused comparison against a constant and branch.
        var makeBrIfImm: (Instruction.BrIfCmpImmOperand) -> Instruction {
            switch self {
            case .i32Eq: return Instruction.brIfI32EqImm
            case .i32Ne: return Instruction.brIfI32NeImm
            case .i32LtS: return Instruction.brIfI32LtSImm
            case .i32LtU: return Instruction.brIfI32LtUImm
            case .i32GtS: return Instruction.brIfI32GtSImm
            case .i32GtU: return Instruction.brIfI32GtUImm
            case .i32LeS: return Instruction.brIfI32LeSImm
            case .i32LeU: return Instruction.brIfI32LeUImm
            case .i32GeS: return Instruction.brIfI32GeSImm
            case .i32GeU: return Instruction.brIfI32GeUImm
            case .i64Eq: return Instruction.brIfI64EqImm
            case .i64Ne: return Instruction.brIfI64NeImm
            case .i64LtS: return Instruction.brIfI64LtSImm
            case .i64LtU: return Instruction.brIfI64LtUImm
            case .i64GtS: return Instruction.brIfI64GtSImm
            case .i64GtU: return Instruction.brIfI64GtUImm
            case .i64LeS: return Instruction.brIfI64LeSImm
            case .i64LeU: return Instruction.brIfI64LeUImm
            case .i64GeS: return Instruction.brIfI64GeSImm
            case .i64GeU: return Instruction.brIfI64GeUImm
            }
        }

        /// The fused branch whose left operand is the accumulator.
        var makeBrIfAcc: (Instruction.BrIfAccCmpOperand) -> Instruction {
            switch self {
            case .i32Eq: return Instruction.brIfI32EqAcc
            case .i32Ne: return Instruction.brIfI32NeAcc
            case .i32LtS: return Instruction.brIfI32LtSAcc
            case .i32LtU: return Instruction.brIfI32LtUAcc
            case .i32GtS: return Instruction.brIfI32GtSAcc
            case .i32GtU: return Instruction.brIfI32GtUAcc
            case .i32LeS: return Instruction.brIfI32LeSAcc
            case .i32LeU: return Instruction.brIfI32LeUAcc
            case .i32GeS: return Instruction.brIfI32GeSAcc
            case .i32GeU: return Instruction.brIfI32GeUAcc
            case .i64Eq: return Instruction.brIfI64EqAcc
            case .i64Ne: return Instruction.brIfI64NeAcc
            case .i64LtS: return Instruction.brIfI64LtSAcc
            case .i64LtU: return Instruction.brIfI64LtUAcc
            case .i64GtS: return Instruction.brIfI64GtSAcc
            case .i64GtU: return Instruction.brIfI64GtUAcc
            case .i64LeS: return Instruction.brIfI64LeSAcc
            case .i64LeU: return Instruction.brIfI64LeUAcc
            case .i64GeS: return Instruction.brIfI64GeSAcc
            case .i64GeU: return Instruction.brIfI64GeUAcc
            }
        }

        /// The fused `brIf*` instruction taking `BrIfCmpOperand`.
        var makeBrIf: (Instruction.BrIfCmpOperand) -> Instruction {
            switch self {
            case .i32Eq: return Instruction.brIfI32Eq
            case .i32Ne: return Instruction.brIfI32Ne
            case .i32LtS: return Instruction.brIfI32LtS
            case .i32LtU: return Instruction.brIfI32LtU
            case .i32GtS: return Instruction.brIfI32GtS
            case .i32GtU: return Instruction.brIfI32GtU
            case .i32LeS: return Instruction.brIfI32LeS
            case .i32LeU: return Instruction.brIfI32LeU
            case .i32GeS: return Instruction.brIfI32GeS
            case .i32GeU: return Instruction.brIfI32GeU
            case .i64Eq: return Instruction.brIfI64Eq
            case .i64Ne: return Instruction.brIfI64Ne
            case .i64LtS: return Instruction.brIfI64LtS
            case .i64LtU: return Instruction.brIfI64LtU
            case .i64GtS: return Instruction.brIfI64GtS
            case .i64GtU: return Instruction.brIfI64GtU
            case .i64LeS: return Instruction.brIfI64LeS
            case .i64LeU: return Instruction.brIfI64LeU
            case .i64GeS: return Instruction.brIfI64GeS
            case .i64GeU: return Instruction.brIfI64GeU
            }
        }
    }

    /// A float comparison that the ISA has fused compare+branch forms for.
    ///
    /// Unlike ``FusedCmpKind`` there is no `complement`: NaN makes both `a < b`
    /// and `a >= b` false, so the `br_if_not` form of a float comparison is not
    /// another float comparison. The branch polarity is instead part of the
    /// opcode, and ``makeBrIf(polarity:lhs:rhs:offset:)`` picks it.
    fileprivate enum FusedFCmpKind {
        case f32Eq, f32Ne, f32Lt, f32Gt, f32Le, f32Ge
        case f64Eq, f64Ne, f64Lt, f64Gt, f64Le, f64Ge

        /// The comparison that holds exactly when this one does with its
        /// operands exchanged (`a < b` is `b > a`), which is exact under NaN.
        var swapped: FusedFCmpKind {
            switch self {
            case .f32Eq: return .f32Eq
            case .f32Ne: return .f32Ne
            case .f32Lt: return .f32Gt
            case .f32Gt: return .f32Lt
            case .f32Le: return .f32Ge
            case .f32Ge: return .f32Le
            case .f64Eq: return .f64Eq
            case .f64Ne: return .f64Ne
            case .f64Lt: return .f64Gt
            case .f64Gt: return .f64Lt
            case .f64Le: return .f64Ge
            case .f64Ge: return .f64Le
            }
        }

        var operandType: ValueType {
            switch self {
            case .f32Eq, .f32Ne, .f32Lt, .f32Gt, .f32Le, .f32Ge: return .f32
            case .f64Eq, .f64Ne, .f64Lt, .f64Gt, .f64Le, .f64Ge: return .f64
            }
        }

        /// The fused branch whose left operand is the float accumulator, or
        /// `nil` for `f32`.
        func makeBrIfAcc(polarity: FusedBranchPolarity) -> ((Instruction.BrIfAccCmpOperand) -> Instruction)? {
            switch (self, polarity) {
            case (.f64Eq, .ifTrue), (.f64Ne, .ifFalse): return Instruction.brIfF64EqAcc
            case (.f64Eq, .ifFalse), (.f64Ne, .ifTrue): return Instruction.brIfF64NeAcc
            case (.f64Lt, .ifTrue): return Instruction.brIfF64LtAcc
            case (.f64Lt, .ifFalse): return Instruction.brIfNotF64LtAcc
            case (.f64Le, .ifTrue): return Instruction.brIfF64LeAcc
            case (.f64Le, .ifFalse): return Instruction.brIfNotF64LeAcc
            case (.f64Gt, .ifTrue): return Instruction.brIfF64GtAcc
            case (.f64Gt, .ifFalse): return Instruction.brIfNotF64GtAcc
            case (.f64Ge, .ifTrue): return Instruction.brIfF64GeAcc
            case (.f64Ge, .ifFalse): return Instruction.brIfNotF64GeAcc
            case (.f32Eq, _), (.f32Ne, _), (.f32Lt, _), (.f32Gt, _), (.f32Le, _), (.f32Ge, _): return nil
            }
        }

        /// The fused branch for this comparison at the given branch polarity.
        ///
        /// Three rewrites happen here, all of them exact under NaN:
        /// - `ne` is the exact complement of `eq` (`f64.ne` *is* `!(a == b)`),
        ///   so the two swap places between the polarities;
        /// - `a > b` is `b < a` and `a >= b` is `b <= a`, so `gt`/`ge` are
        ///   `lt`/`le` with the operands swapped;
        /// - `lt`/`le` at `ifFalse` use the dedicated `brIfNot*` opcodes rather
        ///   than being flipped to `ge`/`gt`, which would differ on NaN.
        func makeBrIf(
            polarity: FusedBranchPolarity, lhs: VReg, rhs: VReg, offset: Int32
        ) -> Instruction {
            /// `(instruction, swapOperands)` for this (comparison, polarity).
            let make: (Instruction.BrIfCmpOperand) -> Instruction
            let swapped: Bool
            switch (self, polarity) {
            case (.f32Eq, .ifTrue), (.f32Ne, .ifFalse): (make, swapped) = (Instruction.brIfF32Eq, false)
            case (.f32Eq, .ifFalse), (.f32Ne, .ifTrue): (make, swapped) = (Instruction.brIfF32Ne, false)
            case (.f32Lt, .ifTrue): (make, swapped) = (Instruction.brIfF32Lt, false)
            case (.f32Lt, .ifFalse): (make, swapped) = (Instruction.brIfNotF32Lt, false)
            case (.f32Gt, .ifTrue): (make, swapped) = (Instruction.brIfF32Lt, true)
            case (.f32Gt, .ifFalse): (make, swapped) = (Instruction.brIfNotF32Lt, true)
            case (.f32Le, .ifTrue): (make, swapped) = (Instruction.brIfF32Le, false)
            case (.f32Le, .ifFalse): (make, swapped) = (Instruction.brIfNotF32Le, false)
            case (.f32Ge, .ifTrue): (make, swapped) = (Instruction.brIfF32Le, true)
            case (.f32Ge, .ifFalse): (make, swapped) = (Instruction.brIfNotF32Le, true)
            case (.f64Eq, .ifTrue), (.f64Ne, .ifFalse): (make, swapped) = (Instruction.brIfF64Eq, false)
            case (.f64Eq, .ifFalse), (.f64Ne, .ifTrue): (make, swapped) = (Instruction.brIfF64Ne, false)
            case (.f64Lt, .ifTrue): (make, swapped) = (Instruction.brIfF64Lt, false)
            case (.f64Lt, .ifFalse): (make, swapped) = (Instruction.brIfNotF64Lt, false)
            case (.f64Gt, .ifTrue): (make, swapped) = (Instruction.brIfF64Lt, true)
            case (.f64Gt, .ifFalse): (make, swapped) = (Instruction.brIfNotF64Lt, true)
            case (.f64Le, .ifTrue): (make, swapped) = (Instruction.brIfF64Le, false)
            case (.f64Le, .ifFalse): (make, swapped) = (Instruction.brIfNotF64Le, false)
            case (.f64Ge, .ifTrue): (make, swapped) = (Instruction.brIfF64Le, true)
            case (.f64Ge, .ifFalse): (make, swapped) = (Instruction.brIfNotF64Le, true)
            }
            return make(
                Instruction.BrIfCmpOperand(
                    lhs: swapped ? rhs : lhs, rhs: swapped ? lhs : rhs, offset: offset
                )
            )
        }
    }

    /// The operand width of a fused `and`+branch (`brIf{Not}{I32,I64}And`).
    fileprivate enum FusedAndWidth {
        case i32, i64

        /// The width of the bit test `op` offers a following branch, or `nil`
        /// when `op` is not a bit test.
        init?(type: ValueType, op: BinBinOp) {
            guard case .and = op else { return nil }
            switch type {
            case .i32: self = .i32
            case .i64: self = .i64
            default: return nil
            }
        }

        /// The fused bit test against a constant mask.
        func makeBrIfImm(polarity: FusedBranchPolarity, lhs: VReg, imm: Int32, offset: Int32) -> Instruction {
            let operand = Instruction.BrIfCmpImmOperand(lhs: lhs, imm: imm, offset: offset)
            switch (self, polarity) {
            case (.i32, .ifTrue): return Instruction.brIfI32AndImm(operand)
            case (.i32, .ifFalse): return Instruction.brIfNotI32AndImm(operand)
            case (.i64, .ifTrue): return Instruction.brIfI64AndImm(operand)
            case (.i64, .ifFalse): return Instruction.brIfNotI64AndImm(operand)
            }
        }

        /// The fused branch for this width at the given branch polarity.
        func makeBrIf(
            polarity: FusedBranchPolarity, lhs: VReg, rhs: VReg, offset: Int32
        ) -> Instruction {
            let operand = Instruction.BrIfCmpOperand(lhs: lhs, rhs: rhs, offset: offset)
            switch (self, polarity) {
            case (.i32, .ifTrue): return Instruction.brIfI32And(operand)
            case (.i32, .ifFalse): return Instruction.brIfNotI32And(operand)
            case (.i64, .ifTrue): return Instruction.brIfI64And(operand)
            case (.i64, .ifFalse): return Instruction.brIfNotI64And(operand)
            }
        }
    }

    /// A binary operation that takes part in the two-operation
    /// superinstructions (`f64MulAdd`, `i32ShlAdd` and friends).
    fileprivate enum BinBinOp {
        case add, sub, mul
        /// Float division, which pairs with no superinstruction.
        case div
        case and, or, xor, shl, shrS, shrU, rotl, rotr

        /// Whether `a op b` and `b op a` are the same operation.
        ///
        /// Used when the intermediate is the *right* operand of the consumer:
        /// `z op2 (x op1 y)` can reuse the `(x op1 y) op2 z` opcode exactly
        /// when `op2` commutes. IEEE-754 addition and multiplication commute
        /// (a NaN result is nondeterministic in Wasm, so the payload is free
        /// either way), and so do the integer `add`/`mul`/`and`/`or`/`xor`.
        var isCommutative: Bool {
            switch self {
            case .add, .mul, .and, .or, .xor: return true
            case .sub, .div, .shl, .shrS, .shrU, .rotl, .rotr: return false
            }
        }
    }

    /// The plain opcode computing `result = lhs <op> rhs` for `type`.
    ///
    /// A table rather than a closure parameter of `visitFusableBinary`, which
    /// would otherwise be specialized once per call site.
    fileprivate static func plainBinaryInstruction(
        _ type: ValueType, _ op: BinBinOp
    ) -> (Instruction.BinaryOperand) -> Instruction {
        switch (type, op) {
        case (.f32, .add): return Instruction.f32Add
        case (.f32, .sub): return Instruction.f32Sub
        case (.f32, .mul): return Instruction.f32Mul
        case (.f32, .div): return Instruction.f32Div
        case (.f64, .add): return Instruction.f64Add
        case (.f64, .sub): return Instruction.f64Sub
        case (.f64, .mul): return Instruction.f64Mul
        case (.f64, .div): return Instruction.f64Div
        case (.i32, .add): return Instruction.i32Add
        case (.i32, .sub): return Instruction.i32Sub
        case (.i32, .mul): return Instruction.i32Mul
        case (.i32, .and): return Instruction.i32And
        case (.i32, .or): return Instruction.i32Or
        case (.i32, .xor): return Instruction.i32Xor
        case (.i32, .shl): return Instruction.i32Shl
        case (.i32, .shrS): return Instruction.i32ShrS
        case (.i32, .shrU): return Instruction.i32ShrU
        case (.i32, .rotl): return Instruction.i32Rotl
        case (.i32, .rotr): return Instruction.i32Rotr
        case (.i64, .add): return Instruction.i64Add
        case (.i64, .sub): return Instruction.i64Sub
        case (.i64, .mul): return Instruction.i64Mul
        case (.i64, .and): return Instruction.i64And
        case (.i64, .or): return Instruction.i64Or
        case (.i64, .xor): return Instruction.i64Xor
        case (.i64, .shl): return Instruction.i64Shl
        case (.i64, .shrS): return Instruction.i64ShrS
        case (.i64, .shrU): return Instruction.i64ShrU
        case (.i64, .rotl): return Instruction.i64Rotl
        case (.i64, .rotr): return Instruction.i64Rotr
        default:
            preconditionFailure("Internal consistency error: no binary opcode for \(type) \(op)")
        }
    }

    /// The superinstruction computing `result = (x op1 y) op2 z` for `type`,
    /// or `result = z op2 (x op1 y)` when `reversed` is set. `nil` when there
    /// is no opcode for the pair.
    fileprivate static func binBinInstruction(
        _ type: ValueType, _ op1: BinBinOp, _ op2: BinBinOp, reversed: Bool
    ) -> ((Instruction.BinBinOperand) -> Instruction)? {
        switch (type, op1, op2, reversed) {
        case (.f32, .add, .add, false): return Instruction.f32AddAdd
        case (.f32, .add, .sub, false): return Instruction.f32AddSub
        case (.f32, .add, .mul, false): return Instruction.f32AddMul
        case (.f32, .sub, .add, false): return Instruction.f32SubAdd
        case (.f32, .sub, .sub, false): return Instruction.f32SubSub
        case (.f32, .sub, .mul, false): return Instruction.f32SubMul
        case (.f32, .mul, .add, false): return Instruction.f32MulAdd
        case (.f32, .mul, .sub, false): return Instruction.f32MulSub
        case (.f32, .mul, .mul, false): return Instruction.f32MulMul
        case (.f64, .add, .add, false): return Instruction.f64AddAdd
        case (.f64, .add, .sub, false): return Instruction.f64AddSub
        case (.f64, .add, .mul, false): return Instruction.f64AddMul
        case (.f64, .sub, .add, false): return Instruction.f64SubAdd
        case (.f64, .sub, .sub, false): return Instruction.f64SubSub
        case (.f64, .sub, .mul, false): return Instruction.f64SubMul
        case (.f64, .mul, .add, false): return Instruction.f64MulAdd
        case (.f64, .mul, .sub, false): return Instruction.f64MulSub
        case (.f64, .mul, .mul, false): return Instruction.f64MulMul
        case (.i32, .shl, .add, false): return Instruction.i32ShlAdd
        case (.i32, .mul, .add, false): return Instruction.i32MulAdd
        case (.i32, .add, .add, false): return Instruction.i32AddAdd
        case (.i32, .and, .add, false): return Instruction.i32AndAdd
        case (.i32, .shrU, .and, false): return Instruction.i32ShrUAnd
        case (.i32, .or, .and, false): return Instruction.i32OrAnd
        case (.i32, .shrU, .add, false): return Instruction.i32ShrUAdd
        case (.i32, .sub, .and, false): return Instruction.i32SubAnd
        case (.i32, .shl, .or, false): return Instruction.i32ShlOr
        case (.i32, .add, .and, false): return Instruction.i32AddAnd
        case (.i32, .shrU, .or, false): return Instruction.i32ShrUOr
        case (.i32, .xor, .shrU, false): return Instruction.i32XorShrU
        case (.i32, .add, .sub, false): return Instruction.i32AddSub
        case (.i32, .xor, .shl, false): return Instruction.i32XorShl
        case (.i32, .sub, .add, false): return Instruction.i32SubAdd
        case (.i32, .and, .shl, false): return Instruction.i32AndShl
        case (.i32, .mul, .sub, true): return Instruction.i32MulSubRev
        case (.i64, .xor, .rotl, false): return Instruction.i64XorRotl
        case (.i64, .mul, .add, false): return Instruction.i64MulAdd
        case (.i64, .shl, .and, false): return Instruction.i64ShlAnd
        case (.i64, .and, .mul, false): return Instruction.i64AndMul
        case (.i64, .shl, .or, false): return Instruction.i64ShlOr
        case (.i64, .xor, .and, false): return Instruction.i64XorAnd
        case (.i64, .mul, .xor, false): return Instruction.i64MulXor
        case (.i64, .and, .xor, false): return Instruction.i64AndXor
        case (.i64, .rotl, .xor, false): return Instruction.i64RotlXor
        case (.i64, .sub, .and, false): return Instruction.i64SubAnd
        case (.i64, .xor, .xor, false): return Instruction.i64XorXor
        case (.i64, .or, .or, false): return Instruction.i64OrOr
        case (.i64, .shrU, .and, false): return Instruction.i64ShrUAnd
        case (.i64, .and, .and, false): return Instruction.i64AndAnd
        case (.i64, .xor, .mul, false): return Instruction.i64XorMul
        case (.i64, .xor, .shrU, false): return Instruction.i64XorShrU
        default: return nil
        }
    }

    /// The accumulator forms of an integer binary operation.
    fileprivate struct AccBinaryForms {
        /// `ireg = sp[lhs] <op> sp[rhs]`
        let toAcc: (Instruction.AccBinaryOperand) -> Instruction
        /// `sp[result] = ireg <op> sp[operand]`
        let fromAcc: (Instruction.AccUnaryOperand) -> Instruction
        /// `ireg = ireg <op> sp[operand]`
        let inAcc: (Instruction.AccOperand) -> Instruction
    }

    /// `sp[result] = ireg = sp[lhs] <op> sp[rhs]`
    fileprivate static func accAndSlotBinaryInstruction(_ type: ValueType, _ op: BinBinOp) -> ((Instruction.BinaryOperand) -> Instruction)? {
        switch (type, op) {
        case (.i32, .add): return Instruction.i32AddToAccAndSlot
        case (.i32, .sub): return Instruction.i32SubToAccAndSlot
        case (.i32, .mul): return Instruction.i32MulToAccAndSlot
        case (.i32, .and): return Instruction.i32AndToAccAndSlot
        case (.i32, .or): return Instruction.i32OrToAccAndSlot
        case (.i32, .xor): return Instruction.i32XorToAccAndSlot
        case (.i32, .shl): return Instruction.i32ShlToAccAndSlot
        case (.i32, .shrS): return Instruction.i32ShrSToAccAndSlot
        case (.i32, .shrU): return Instruction.i32ShrUToAccAndSlot
        case (.i32, .rotl): return Instruction.i32RotlToAccAndSlot
        case (.i32, .rotr): return Instruction.i32RotrToAccAndSlot
        case (.i64, .add): return Instruction.i64AddToAccAndSlot
        case (.i64, .sub): return Instruction.i64SubToAccAndSlot
        case (.i64, .mul): return Instruction.i64MulToAccAndSlot
        case (.i64, .and): return Instruction.i64AndToAccAndSlot
        case (.i64, .or): return Instruction.i64OrToAccAndSlot
        case (.i64, .xor): return Instruction.i64XorToAccAndSlot
        case (.i64, .shl): return Instruction.i64ShlToAccAndSlot
        case (.i64, .shrS): return Instruction.i64ShrSToAccAndSlot
        case (.i64, .shrU): return Instruction.i64ShrUToAccAndSlot
        case (.i64, .rotl): return Instruction.i64RotlToAccAndSlot
        case (.i64, .rotr): return Instruction.i64RotrToAccAndSlot
        default: return nil
        }
    }

    /// `sp[result] = ireg = sp[lhs] <op> imm`
    fileprivate static func accAndSlotImmInstruction(_ type: ValueType, _ op: BinBinOp) -> ((Instruction.BinaryImmOperand) -> Instruction)? {
        switch (type, op) {
        case (.i32, .add): return Instruction.i32AddImmToAccAndSlot
        case (.i32, .mul): return Instruction.i32MulImmToAccAndSlot
        case (.i32, .and): return Instruction.i32AndImmToAccAndSlot
        case (.i32, .or): return Instruction.i32OrImmToAccAndSlot
        case (.i32, .xor): return Instruction.i32XorImmToAccAndSlot
        case (.i32, .shl): return Instruction.i32ShlImmToAccAndSlot
        case (.i32, .shrS): return Instruction.i32ShrSImmToAccAndSlot
        case (.i32, .shrU): return Instruction.i32ShrUImmToAccAndSlot
        case (.i32, .rotl): return Instruction.i32RotlImmToAccAndSlot
        case (.i32, .rotr): return Instruction.i32RotrImmToAccAndSlot
        case (.i64, .add): return Instruction.i64AddImmToAccAndSlot
        case (.i64, .mul): return Instruction.i64MulImmToAccAndSlot
        case (.i64, .and): return Instruction.i64AndImmToAccAndSlot
        case (.i64, .or): return Instruction.i64OrImmToAccAndSlot
        case (.i64, .xor): return Instruction.i64XorImmToAccAndSlot
        case (.i64, .shl): return Instruction.i64ShlImmToAccAndSlot
        case (.i64, .shrS): return Instruction.i64ShrSImmToAccAndSlot
        case (.i64, .shrU): return Instruction.i64ShrUImmToAccAndSlot
        case (.i64, .rotl): return Instruction.i64RotlImmToAccAndSlot
        case (.i64, .rotr): return Instruction.i64RotrImmToAccAndSlot
        default: return nil
        }
    }

    /// `sp[result] = ireg = load(sp[pointer] + offset)`
    fileprivate static func accAndSlotLoadInstruction(_ load: WasmParser.Instruction.Load) -> ((Instruction.AccMemoryPointerResultOperand) -> Instruction)? {
        switch load {
        case .i32Load: return Instruction.i32LoadToAccAndSlot
        case .i64Load: return Instruction.i64LoadToAccAndSlot
        case .f32Load: return Instruction.f32LoadToAccAndSlot
        case .f64Load: return Instruction.f64LoadToAccAndSlot
        case .i32Load8S: return Instruction.i32Load8SToAccAndSlot
        case .i32Load8U: return Instruction.i32Load8UToAccAndSlot
        case .i32Load16S: return Instruction.i32Load16SToAccAndSlot
        case .i32Load16U: return Instruction.i32Load16UToAccAndSlot
        case .i64Load8S: return Instruction.i64Load8SToAccAndSlot
        case .i64Load8U: return Instruction.i64Load8UToAccAndSlot
        case .i64Load16S: return Instruction.i64Load16SToAccAndSlot
        case .i64Load16U: return Instruction.i64Load16UToAccAndSlot
        case .i64Load32S: return Instruction.i64Load32SToAccAndSlot
        case .i64Load32U: return Instruction.i64Load32UToAccAndSlot
        default: return nil
        }
    }

    /// `sp[copyDest] = sp[pointer]`, then `sp[result] = load(sp[pointer] + offset)`
    fileprivate static func loadWithCopyInstruction(_ load: WasmParser.Instruction.Load) -> ((Instruction.LoadWithCopyOperand) -> Instruction)? {
        switch load {
        case .i32Load: return Instruction.i32LoadWithCopy
        case .i64Load: return Instruction.i64LoadWithCopy
        case .f32Load: return Instruction.f32LoadWithCopy
        case .f64Load: return Instruction.f64LoadWithCopy
        case .i32Load8S: return Instruction.i32Load8SWithCopy
        case .i32Load8U: return Instruction.i32Load8UWithCopy
        case .i32Load16S: return Instruction.i32Load16SWithCopy
        case .i32Load16U: return Instruction.i32Load16UWithCopy
        case .i64Load8S: return Instruction.i64Load8SWithCopy
        case .i64Load8U: return Instruction.i64Load8UWithCopy
        case .i64Load16S: return Instruction.i64Load16SWithCopy
        case .i64Load16U: return Instruction.i64Load16UWithCopy
        case .i64Load32S: return Instruction.i64Load32SWithCopy
        case .i64Load32U: return Instruction.i64Load32UWithCopy
        default: return nil
        }
    }

    fileprivate static func accBinaryForms(_ type: ValueType, _ op: BinBinOp) -> AccBinaryForms? {
        switch (type, op) {
        case (.i32, .add):
            return AccBinaryForms(
                toAcc: Instruction.i32AddToAcc, fromAcc: Instruction.i32AddFromAcc, inAcc: Instruction.i32AddInAcc)
        case (.i32, .sub):
            return AccBinaryForms(
                toAcc: Instruction.i32SubToAcc, fromAcc: Instruction.i32SubFromAcc, inAcc: Instruction.i32SubInAcc)
        case (.i32, .mul):
            return AccBinaryForms(
                toAcc: Instruction.i32MulToAcc, fromAcc: Instruction.i32MulFromAcc, inAcc: Instruction.i32MulInAcc)
        case (.i32, .and):
            return AccBinaryForms(
                toAcc: Instruction.i32AndToAcc, fromAcc: Instruction.i32AndFromAcc, inAcc: Instruction.i32AndInAcc)
        case (.i32, .or):
            return AccBinaryForms(
                toAcc: Instruction.i32OrToAcc, fromAcc: Instruction.i32OrFromAcc, inAcc: Instruction.i32OrInAcc)
        case (.i32, .xor):
            return AccBinaryForms(
                toAcc: Instruction.i32XorToAcc, fromAcc: Instruction.i32XorFromAcc, inAcc: Instruction.i32XorInAcc)
        case (.i32, .shl):
            return AccBinaryForms(
                toAcc: Instruction.i32ShlToAcc, fromAcc: Instruction.i32ShlFromAcc, inAcc: Instruction.i32ShlInAcc)
        case (.i32, .shrS):
            return AccBinaryForms(
                toAcc: Instruction.i32ShrSToAcc, fromAcc: Instruction.i32ShrSFromAcc, inAcc: Instruction.i32ShrSInAcc)
        case (.i32, .shrU):
            return AccBinaryForms(
                toAcc: Instruction.i32ShrUToAcc, fromAcc: Instruction.i32ShrUFromAcc, inAcc: Instruction.i32ShrUInAcc)
        case (.i32, .rotl):
            return AccBinaryForms(
                toAcc: Instruction.i32RotlToAcc, fromAcc: Instruction.i32RotlFromAcc, inAcc: Instruction.i32RotlInAcc)
        case (.i32, .rotr):
            return AccBinaryForms(
                toAcc: Instruction.i32RotrToAcc, fromAcc: Instruction.i32RotrFromAcc, inAcc: Instruction.i32RotrInAcc)
        case (.i64, .add):
            return AccBinaryForms(
                toAcc: Instruction.i64AddToAcc, fromAcc: Instruction.i64AddFromAcc, inAcc: Instruction.i64AddInAcc)
        case (.i64, .sub):
            return AccBinaryForms(
                toAcc: Instruction.i64SubToAcc, fromAcc: Instruction.i64SubFromAcc, inAcc: Instruction.i64SubInAcc)
        case (.i64, .mul):
            return AccBinaryForms(
                toAcc: Instruction.i64MulToAcc, fromAcc: Instruction.i64MulFromAcc, inAcc: Instruction.i64MulInAcc)
        case (.i64, .and):
            return AccBinaryForms(
                toAcc: Instruction.i64AndToAcc, fromAcc: Instruction.i64AndFromAcc, inAcc: Instruction.i64AndInAcc)
        case (.i64, .or):
            return AccBinaryForms(
                toAcc: Instruction.i64OrToAcc, fromAcc: Instruction.i64OrFromAcc, inAcc: Instruction.i64OrInAcc)
        case (.i64, .xor):
            return AccBinaryForms(
                toAcc: Instruction.i64XorToAcc, fromAcc: Instruction.i64XorFromAcc, inAcc: Instruction.i64XorInAcc)
        case (.i64, .shl):
            return AccBinaryForms(
                toAcc: Instruction.i64ShlToAcc, fromAcc: Instruction.i64ShlFromAcc, inAcc: Instruction.i64ShlInAcc)
        case (.i64, .shrS):
            return AccBinaryForms(
                toAcc: Instruction.i64ShrSToAcc, fromAcc: Instruction.i64ShrSFromAcc, inAcc: Instruction.i64ShrSInAcc)
        case (.i64, .shrU):
            return AccBinaryForms(
                toAcc: Instruction.i64ShrUToAcc, fromAcc: Instruction.i64ShrUFromAcc, inAcc: Instruction.i64ShrUInAcc)
        case (.i64, .rotl):
            return AccBinaryForms(
                toAcc: Instruction.i64RotlToAcc, fromAcc: Instruction.i64RotlFromAcc, inAcc: Instruction.i64RotlInAcc)
        case (.i64, .rotr):
            return AccBinaryForms(
                toAcc: Instruction.i64RotrToAcc, fromAcc: Instruction.i64RotrFromAcc, inAcc: Instruction.i64RotrInAcc)
        default: return nil
        }
    }

    /// The float accumulator forms of an `f64` binary operation. The reversed
    /// forms, where the accumulated value is the right operand, exist only for
    /// the non-commutative `sub` and `div`.
    fileprivate struct FloatAccBinaryForms {
        let toAcc: (Instruction.AccBinaryOperand) -> Instruction
        let fromAcc: (Instruction.AccUnaryOperand) -> Instruction
        let inAcc: (Instruction.AccOperand) -> Instruction
        let fromAccRev: ((Instruction.AccUnaryOperand) -> Instruction)?
        let inAccRev: ((Instruction.AccOperand) -> Instruction)?
    }

    fileprivate static func floatAccBinaryForms(_ type: ValueType, _ op: BinBinOp) -> FloatAccBinaryForms? {
        switch (type, op) {
        case (.f64, .add):
            return FloatAccBinaryForms(
                toAcc: Instruction.f64AddToAcc, fromAcc: Instruction.f64AddFromAcc, inAcc: Instruction.f64AddInAcc,
                fromAccRev: nil, inAccRev: nil)
        case (.f64, .mul):
            return FloatAccBinaryForms(
                toAcc: Instruction.f64MulToAcc, fromAcc: Instruction.f64MulFromAcc, inAcc: Instruction.f64MulInAcc,
                fromAccRev: nil, inAccRev: nil)
        case (.f64, .sub):
            return FloatAccBinaryForms(
                toAcc: Instruction.f64SubToAcc, fromAcc: Instruction.f64SubFromAcc, inAcc: Instruction.f64SubInAcc,
                fromAccRev: Instruction.f64SubFromAccRev, inAccRev: Instruction.f64SubInAccRev)
        case (.f64, .div):
            return FloatAccBinaryForms(
                toAcc: Instruction.f64DivToAcc, fromAcc: Instruction.f64DivFromAcc, inAcc: Instruction.f64DivInAcc,
                fromAccRev: Instruction.f64DivFromAccRev, inAccRev: Instruction.f64DivInAccRev)
        default: return nil
        }
    }

    /// The `f64` two-operation superinstruction producing into the float
    /// accumulator.
    fileprivate static func floatBinBinAccInstruction(
        _ type: ValueType, _ op1: BinBinOp, _ op2: BinBinOp
    ) -> ((Instruction.AccBinBinOperand) -> Instruction)? {
        switch (type, op1, op2) {
        case (.f64, .add, .add): return Instruction.f64AddAddToAcc
        case (.f64, .add, .sub): return Instruction.f64AddSubToAcc
        case (.f64, .add, .mul): return Instruction.f64AddMulToAcc
        case (.f64, .sub, .add): return Instruction.f64SubAddToAcc
        case (.f64, .sub, .sub): return Instruction.f64SubSubToAcc
        case (.f64, .sub, .mul): return Instruction.f64SubMulToAcc
        case (.f64, .mul, .add): return Instruction.f64MulAddToAcc
        case (.f64, .mul, .sub): return Instruction.f64MulSubToAcc
        case (.f64, .mul, .mul): return Instruction.f64MulMulToAcc
        default: return nil
        }
    }

    /// A load and its accumulator forms, on a 32-bit memory.
    fileprivate struct AccLoadForms {
        let plain: (Instruction.LoadOperand) -> Instruction
        /// `ireg = load(sp[pointer] + offset)`
        let toAcc: (Instruction.AccMemoryPointerOperand) -> Instruction
        /// `sp[result] = load(ireg + offset)`
        let fromAcc: (Instruction.AccMemoryResultOperand) -> Instruction
        /// `ireg = load(ireg + offset)`
        let inAcc: (Instruction.AccMemoryOffsetOperand) -> Instruction
    }

    /// `nil` for the SIMD and atomic loads, which have no accumulator forms.
    fileprivate static func accLoadForms(_ load: WasmParser.Instruction.Load) -> AccLoadForms? {
        switch load {
        case .i32Load:
            return AccLoadForms(
                plain: Instruction.i32Load, toAcc: Instruction.i32LoadToAcc, fromAcc: Instruction.i32LoadFromAcc,
                inAcc: Instruction.i32LoadInAcc)
        case .i64Load:
            return AccLoadForms(
                plain: Instruction.i64Load, toAcc: Instruction.i64LoadToAcc, fromAcc: Instruction.i64LoadFromAcc,
                inAcc: Instruction.i64LoadInAcc)
        case .f32Load:
            return AccLoadForms(
                plain: Instruction.f32Load, toAcc: Instruction.f32LoadToAcc, fromAcc: Instruction.f32LoadFromAcc,
                inAcc: Instruction.f32LoadInAcc)
        case .f64Load:
            return AccLoadForms(
                plain: Instruction.f64Load, toAcc: Instruction.f64LoadToAcc, fromAcc: Instruction.f64LoadFromAcc,
                inAcc: Instruction.f64LoadInAcc)
        case .i32Load8S:
            return AccLoadForms(
                plain: Instruction.i32Load8S, toAcc: Instruction.i32Load8SToAcc, fromAcc: Instruction.i32Load8SFromAcc,
                inAcc: Instruction.i32Load8SInAcc)
        case .i32Load8U:
            return AccLoadForms(
                plain: Instruction.i32Load8U, toAcc: Instruction.i32Load8UToAcc, fromAcc: Instruction.i32Load8UFromAcc,
                inAcc: Instruction.i32Load8UInAcc)
        case .i32Load16S:
            return AccLoadForms(
                plain: Instruction.i32Load16S, toAcc: Instruction.i32Load16SToAcc, fromAcc: Instruction.i32Load16SFromAcc,
                inAcc: Instruction.i32Load16SInAcc)
        case .i32Load16U:
            return AccLoadForms(
                plain: Instruction.i32Load16U, toAcc: Instruction.i32Load16UToAcc, fromAcc: Instruction.i32Load16UFromAcc,
                inAcc: Instruction.i32Load16UInAcc)
        case .i64Load8S:
            return AccLoadForms(
                plain: Instruction.i64Load8S, toAcc: Instruction.i64Load8SToAcc, fromAcc: Instruction.i64Load8SFromAcc,
                inAcc: Instruction.i64Load8SInAcc)
        case .i64Load8U:
            return AccLoadForms(
                plain: Instruction.i64Load8U, toAcc: Instruction.i64Load8UToAcc, fromAcc: Instruction.i64Load8UFromAcc,
                inAcc: Instruction.i64Load8UInAcc)
        case .i64Load16S:
            return AccLoadForms(
                plain: Instruction.i64Load16S, toAcc: Instruction.i64Load16SToAcc, fromAcc: Instruction.i64Load16SFromAcc,
                inAcc: Instruction.i64Load16SInAcc)
        case .i64Load16U:
            return AccLoadForms(
                plain: Instruction.i64Load16U, toAcc: Instruction.i64Load16UToAcc, fromAcc: Instruction.i64Load16UFromAcc,
                inAcc: Instruction.i64Load16UInAcc)
        case .i64Load32S:
            return AccLoadForms(
                plain: Instruction.i64Load32S, toAcc: Instruction.i64Load32SToAcc, fromAcc: Instruction.i64Load32SFromAcc,
                inAcc: Instruction.i64Load32SInAcc)
        case .i64Load32U:
            return AccLoadForms(
                plain: Instruction.i64Load32U, toAcc: Instruction.i64Load32UToAcc, fromAcc: Instruction.i64Load32UFromAcc,
                inAcc: Instruction.i64Load32UInAcc)
        default: return nil
        }
    }

    /// The accumulator forms of a store, on a 32-bit memory.
    fileprivate struct AccStoreForms {
        let plain: (Instruction.StoreOperand) -> Instruction
        /// `store(sp[pointer] + offset) = ireg`
        let fromAcc: (Instruction.AccMemoryPointerOperand) -> Instruction
        /// `store(ireg + offset) = sp[value]`
        let addrFromAcc: (Instruction.AccMemoryValueOperand) -> Instruction
    }

    /// `nil` for the SIMD and atomic stores, which have no accumulator forms.
    fileprivate static func accStoreForms(_ store: WasmParser.Instruction.Store) -> AccStoreForms? {
        switch store {
        case .i32Store: return AccStoreForms(plain: Instruction.i32Store, fromAcc: Instruction.i32StoreFromAcc, addrFromAcc: Instruction.i32StoreAddrFromAcc)
        case .i64Store: return AccStoreForms(plain: Instruction.i64Store, fromAcc: Instruction.i64StoreFromAcc, addrFromAcc: Instruction.i64StoreAddrFromAcc)
        case .f32Store: return AccStoreForms(plain: Instruction.f32Store, fromAcc: Instruction.f32StoreFromAcc, addrFromAcc: Instruction.f32StoreAddrFromAcc)
        case .f64Store: return AccStoreForms(plain: Instruction.f64Store, fromAcc: Instruction.f64StoreFromAcc, addrFromAcc: Instruction.f64StoreAddrFromAcc)
        case .i32Store8: return AccStoreForms(plain: Instruction.i32Store8, fromAcc: Instruction.i32Store8FromAcc, addrFromAcc: Instruction.i32Store8AddrFromAcc)
        case .i32Store16: return AccStoreForms(plain: Instruction.i32Store16, fromAcc: Instruction.i32Store16FromAcc, addrFromAcc: Instruction.i32Store16AddrFromAcc)
        case .i64Store8: return AccStoreForms(plain: Instruction.i64Store8, fromAcc: Instruction.i64Store8FromAcc, addrFromAcc: Instruction.i64Store8AddrFromAcc)
        case .i64Store16: return AccStoreForms(plain: Instruction.i64Store16, fromAcc: Instruction.i64Store16FromAcc, addrFromAcc: Instruction.i64Store16AddrFromAcc)
        case .i64Store32: return AccStoreForms(plain: Instruction.i64Store32, fromAcc: Instruction.i64Store32FromAcc, addrFromAcc: Instruction.i64Store32AddrFromAcc)
        default: return nil
        }
    }

    /// A binary operation as recorded on its emission, for folding into the
    /// operation that consumes its result.
    fileprivate struct BinaryOperation {
        let type: ValueType
        let op: BinBinOp
        let lhs: VReg
        let rhs: VReg
        let result: VReg
        /// Set when the right operand is a constant carried in the instruction
        /// rather than `rhs`. A superinstruction reads it from the constant pool.
        var rhsConstant: UntypedValue? = nil
    }

    /// The immediate-operand forms of an integer binary operation.
    fileprivate struct ImmBinaryForms {
        let plain: (Instruction.BinaryImmOperand) -> Instruction
        /// `ireg = lhs <op> imm`
        let toAcc: (Instruction.AccBinaryImmOperand) -> Instruction
    }

    fileprivate static func immBinaryForms(_ type: ValueType, _ op: BinBinOp) -> ImmBinaryForms? {
        switch (type, op) {
        case (.i32, .add): return ImmBinaryForms(plain: Instruction.i32AddImm, toAcc: Instruction.i32AddImmToAcc)
        case (.i32, .mul): return ImmBinaryForms(plain: Instruction.i32MulImm, toAcc: Instruction.i32MulImmToAcc)
        case (.i32, .and): return ImmBinaryForms(plain: Instruction.i32AndImm, toAcc: Instruction.i32AndImmToAcc)
        case (.i32, .or): return ImmBinaryForms(plain: Instruction.i32OrImm, toAcc: Instruction.i32OrImmToAcc)
        case (.i32, .xor): return ImmBinaryForms(plain: Instruction.i32XorImm, toAcc: Instruction.i32XorImmToAcc)
        case (.i32, .shl): return ImmBinaryForms(plain: Instruction.i32ShlImm, toAcc: Instruction.i32ShlImmToAcc)
        case (.i32, .shrS): return ImmBinaryForms(plain: Instruction.i32ShrSImm, toAcc: Instruction.i32ShrSImmToAcc)
        case (.i32, .shrU): return ImmBinaryForms(plain: Instruction.i32ShrUImm, toAcc: Instruction.i32ShrUImmToAcc)
        case (.i32, .rotl): return ImmBinaryForms(plain: Instruction.i32RotlImm, toAcc: Instruction.i32RotlImmToAcc)
        case (.i32, .rotr): return ImmBinaryForms(plain: Instruction.i32RotrImm, toAcc: Instruction.i32RotrImmToAcc)
        case (.i64, .add): return ImmBinaryForms(plain: Instruction.i64AddImm, toAcc: Instruction.i64AddImmToAcc)
        case (.i64, .mul): return ImmBinaryForms(plain: Instruction.i64MulImm, toAcc: Instruction.i64MulImmToAcc)
        case (.i64, .and): return ImmBinaryForms(plain: Instruction.i64AndImm, toAcc: Instruction.i64AndImmToAcc)
        case (.i64, .or): return ImmBinaryForms(plain: Instruction.i64OrImm, toAcc: Instruction.i64OrImmToAcc)
        case (.i64, .xor): return ImmBinaryForms(plain: Instruction.i64XorImm, toAcc: Instruction.i64XorImmToAcc)
        case (.i64, .shl): return ImmBinaryForms(plain: Instruction.i64ShlImm, toAcc: Instruction.i64ShlImmToAcc)
        case (.i64, .shrS): return ImmBinaryForms(plain: Instruction.i64ShrSImm, toAcc: Instruction.i64ShrSImmToAcc)
        case (.i64, .shrU): return ImmBinaryForms(plain: Instruction.i64ShrUImm, toAcc: Instruction.i64ShrUImmToAcc)
        case (.i64, .rotl): return ImmBinaryForms(plain: Instruction.i64RotlImm, toAcc: Instruction.i64RotlImmToAcc)
        case (.i64, .rotr): return ImmBinaryForms(plain: Instruction.i64RotrImm, toAcc: Instruction.i64RotrImmToAcc)
        default: return nil
        }
    }

    /// The two accumulator registers.
    fileprivate enum AccRegister {
        /// `ireg`, which holds an integer or a raw 64-bit slot value.
        case integer
        /// `freg`, which holds an `f64`.
        case float
    }

    /// An instruction whose single result can be produced into an accumulator
    /// instead of a frame slot.
    ///
    /// Recorded as operands rather than as `Instruction` values, which would
    /// make the `~Copyable` builder's layout expensive to analyze.
    fileprivate enum AccProducerForm {
        /// `result = lhs <op> rhs`
        case binary(type: ValueType, op: BinBinOp, lhs: VReg, rhs: VReg, result: VReg)
        /// `result = lhs <op> imm`
        case binaryImm(type: ValueType, op: BinBinOp, lhs: VReg, imm: Int32, result: VReg)
        /// `result = ireg <op> operand`
        case fromAcc(type: ValueType, op: BinBinOp, operand: VReg, result: VReg)
        /// `result = freg <op> operand`, or `operand <op> freg` when reversed
        case fromFloatAcc(op: BinBinOp, operand: VReg, reversed: Bool, result: VReg)
        /// `result = (x <op1> y) <op2> z` on `f64`
        case floatBinBin(op1: BinBinOp, op2: BinBinOp, x: VReg, y: VReg, z: VReg, result: VReg)
        /// `result = sqrt(operand)` on `f64`
        case sqrt(operand: VReg, result: VReg)
        /// `result = <global>`
        case globalGet(type: ValueType, global: InternalGlobal, result: VReg)
        /// `result = load(pointer + offset)`
        case load(WasmParser.Instruction.Load, pointer: VReg, offset: UInt32, result: VReg)
        /// `result = load(ireg + offset)`
        case loadFromAcc(WasmParser.Instruction.Load, offset: UInt32, result: VReg)

        var type: ValueType {
            switch self {
            case .binary(let type, _, _, _, _), .binaryImm(let type, _, _, _, _), .fromAcc(let type, _, _, _), .globalGet(let type, _, _): return type
            case .fromFloatAcc, .floatBinBin, .sqrt: return .f64
            case .load(let load, _, _, _), .loadFromAcc(let load, _, _): return load.type
            }
        }

        var result: VReg {
            switch self {
            case .binary(_, _, _, _, let result), .binaryImm(_, _, _, _, let result), .fromAcc(_, _, _, let result), .globalGet(_, _, let result): return result
            case .fromFloatAcc(_, _, _, let result), .floatBinBin(_, _, _, _, _, let result), .sqrt(_, let result): return result
            case .load(_, _, _, let result), .loadFromAcc(_, _, let result): return result
            }
        }

        /// The same operation producing into `register`, or `nil` when it has
        /// no such form.
        func producing(into register: AccRegister) -> Instruction? {
            switch (self, register) {
            case (.binary(let type, let op, let lhs, let rhs, _), .integer):
                return accBinaryForms(type, op)?.toAcc(Instruction.AccBinaryOperand(lhs: lhs, rhs: rhs))
            case (.binary(let type, let op, let lhs, let rhs, _), .float):
                return floatAccBinaryForms(type, op)?.toAcc(Instruction.AccBinaryOperand(lhs: lhs, rhs: rhs))
            case (.binaryImm(let type, let op, let lhs, let imm, _), .integer):
                return immBinaryForms(type, op)!.toAcc(Instruction.AccBinaryImmOperand(lhs: lhs, imm: imm))
            case (.fromAcc(let type, let op, let operand, _), .integer):
                return accBinaryForms(type, op)?.inAcc(Instruction.AccOperand(operand: operand))
            case (.fromFloatAcc(let op, let operand, let reversed, _), .float):
                let forms = floatAccBinaryForms(.f64, op)!
                return (reversed ? forms.inAccRev! : forms.inAcc)(Instruction.AccOperand(operand: operand))
            case (.floatBinBin(let op1, let op2, let x, let y, let z, _), .float):
                return floatBinBinAccInstruction(.f64, op1, op2)?(Instruction.AccBinBinOperand(x: x, y: y, z: z))
            case (.sqrt(let operand, _), .float):
                return .f64SqrtToAcc(Instruction.AccOperand(operand: operand))
            case (.globalGet(_, let global, _), .integer):
                return .globalGetToAcc(Instruction.GlobalOperand(global: global))
            case (.load(let load, let pointer, let offset, _), .integer):
                return accLoadForms(load)!.toAcc(Instruction.AccMemoryPointerOperand(pointer: pointer, offset: offset))
            case (.load(.f64Load, let pointer, let offset, _), .float):
                return .f64LoadToFAcc(Instruction.AccMemoryPointerOperand(pointer: pointer, offset: offset))
            case (.loadFromAcc(let load, let offset, _), .integer):
                return accLoadForms(load)!.inAcc(Instruction.AccMemoryOffsetOperand(offset: offset))
            case (.loadFromAcc(.f64Load, let offset, _), .float):
                return .f64LoadFromAccToFAcc(Instruction.AccMemoryOffsetOperand(offset: offset))
            default:
                return nil
            }
        }

        /// The same operation writing its result to its frame slot and leaving
        /// it in `ireg` too, or `nil` when it has no such form.
        var producingIntoAccAndSlot: Instruction? {
            switch self {
            case .binary(let type, let op, let lhs, let rhs, let result):
                return accAndSlotBinaryInstruction(type, op)?(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result)))
            case .binaryImm(let type, let op, let lhs, let imm, let result):
                return accAndSlotImmInstruction(type, op)?(Instruction.BinaryImmOperand(result: result, lhs: lhs, imm: imm))
            case .load(let load, let pointer, let offset, let result):
                return accAndSlotLoadInstruction(load)?(Instruction.AccMemoryPointerResultOperand(pointer: pointer, result: result, offset: offset))
            default:
                return nil
            }
        }

        /// Whether ``producingIntoAccAndSlot`` has a form.
        var hasAccAndSlotForm: Bool {
            switch self {
            case .binary(let type, let op, _, _, _): return (type == .i32 || type == .i64) && op != .div
            case .binaryImm: return true
            case .load: return true
            default: return false
            }
        }

        /// The same operation writing `result` instead.
        func relinked(to result: VReg) -> AccProducerForm {
            switch self {
            case .binary(let type, let op, let lhs, let rhs, _): return .binary(type: type, op: op, lhs: lhs, rhs: rhs, result: result)
            case .binaryImm(let type, let op, let lhs, let imm, _): return .binaryImm(type: type, op: op, lhs: lhs, imm: imm, result: result)
            case .fromAcc(let type, let op, let operand, _): return .fromAcc(type: type, op: op, operand: operand, result: result)
            case .fromFloatAcc(let op, let operand, let reversed, _): return .fromFloatAcc(op: op, operand: operand, reversed: reversed, result: result)
            case .floatBinBin(let op1, let op2, let x, let y, let z, _): return .floatBinBin(op1: op1, op2: op2, x: x, y: y, z: z, result: result)
            case .sqrt(let operand, _): return .sqrt(operand: operand, result: result)
            case .globalGet(let type, let global, _): return .globalGet(type: type, global: global, result: result)
            case .load(let load, let pointer, let offset, _): return .load(load, pointer: pointer, offset: offset, result: result)
            case .loadFromAcc(let load, let offset, _): return .loadFromAcc(load, offset: offset, result: result)
            }
        }

        /// The operation writing its result to its frame slot.
        var plain: Instruction {
            switch self {
            case .binary(let type, let op, let lhs, let rhs, let result):
                return plainBinaryInstruction(type, op)(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result)))
            case .binaryImm(let type, let op, let lhs, let imm, let result):
                return immBinaryForms(type, op)!.plain(Instruction.BinaryImmOperand(result: result, lhs: lhs, imm: imm))
            case .fromAcc(let type, let op, let operand, let result):
                return accBinaryForms(type, op)!.fromAcc(Instruction.AccUnaryOperand(operand: operand, result: LVReg(result)))
            case .fromFloatAcc(let op, let operand, let reversed, let result):
                let forms = floatAccBinaryForms(.f64, op)!
                return (reversed ? forms.fromAccRev! : forms.fromAcc)(Instruction.AccUnaryOperand(operand: operand, result: LVReg(result)))
            case .floatBinBin(let op1, let op2, let x, let y, let z, let result):
                return binBinInstruction(.f64, op1, op2, reversed: false)!(Instruction.BinBinOperand(result: result, x: x, y: y, z: z))
            case .sqrt(let operand, let result):
                return .f64Sqrt(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(operand)))
            case .globalGet(_, let global, let result):
                return .globalGet(Instruction.GlobalAndVRegOperand(reg: LLVReg(result), global: global))
            case .load(let load, let pointer, let offset, let result):
                return accLoadForms(load)!.plain(Instruction.LoadOperand(offset: UInt64(offset), pointer: pointer, result: result))
            case .loadFromAcc(let load, let offset, let result):
                return accLoadForms(load)!.fromAcc(Instruction.AccMemoryResultOperand(result: result, offset: offset))
            }
        }
    }

    /// A just-emitted instruction whose single integer result could be
    /// produced into the accumulator instead of a frame slot.
    fileprivate struct AccProducer {
        let position: MetaProgramCounter
        let end: MetaProgramCounter
        let form: AccProducerForm
        /// The result is a local that is read again later, so the producer
        /// keeps writing its slot and also leaves the value in `ireg`.
        var keepsSlot = false

        /// The form handing the result to the next instruction in `register`,
        /// or `nil` when there is none.
        func producing(into register: AccRegister) -> Instruction? {
            guard keepsSlot else { return form.producing(into: register) }
            return register == .integer ? form.producingIntoAccAndSlot : nil
        }
    }

    /// A comparison one of whose operands is the result of the instruction
    /// right before it, so that a branch fusing the comparison can take that
    /// operand from the accumulator.
    fileprivate struct AccCompare {
        enum Kind {
            case integer(FusedCmpKind)
            case float(FusedFCmpKind)
        }
        /// The predicate with the accumulator as its left operand.
        let kind: Kind
        /// The operand that stays in a slot.
        let rhs: VReg
        /// Set when an `eqz` negates the comparison.
        var negated = false
        let producerPosition: MetaProgramCounter
        let producer: AccProducer

        var register: AccRegister {
            switch kind {
            case .integer: return .integer
            case .float: return .float
            }
        }

        func makeBranch(polarity: FusedBranchPolarity, offset: Int32) -> Instruction {
            let polarity = negated ? polarity.flipped : polarity
            let operand = Instruction.BrIfAccCmpOperand(rhs: rhs, offset: offset)
            switch kind {
            case .integer(let kind):
                return (polarity == .ifTrue ? kind : kind.complement).makeBrIfAcc(operand)
            case .float(let kind):
                return kind.makeBrIfAcc(polarity: polarity)!(operand)
            }
        }
    }

    /// A just-emitted binary operation whose result can be kept in a register
    /// by folding it into the operation that consumes it.
    fileprivate struct BinaryEmission {
        let position: MetaProgramCounter
        let end: MetaProgramCounter
        let operation: BinaryOperation
        /// See ``AccRecords/prefix``.
        let prefix: AccProducerForm?
    }

    /// What the last emission offers to the accumulator hand-off. Kept apart
    /// from the builder's other records of the last emission so that emitting
    /// an instruction stays cheap.
    fileprivate struct AccRecords {
        /// The emission can produce its result into the accumulator.
        var producer: AccProducerForm?
        /// The emission is a comparison that can take an operand from the
        /// accumulator.
        var compare: AccCompare?
        /// The emission reads its left operand from the accumulator. A fold
        /// that replaces it rewinds to the producer's position and re-emits the
        /// producer in its slot-writing form first.
        var prefix: (position: MetaProgramCounter, producer: AccProducerForm)?
    }

    /// A just-emitted instruction whose result feeds a following conditional
    /// branch directly, and which can therefore be replaced by a fused
    /// compare+branch instruction.
    fileprivate enum FusableCondition {
        /// `result = lhs <kind> rhs`
        case compare(kind: FusedCmpKind, lhs: VReg, rhs: VReg)
        /// `result = lhs <kind> imm`
        case compareImm(kind: FusedCmpKind, lhs: VReg, imm: Int32)
        /// `result = lhs <kind> rhs` for a float comparison
        case floatCompare(kind: FusedFCmpKind, lhs: VReg, rhs: VReg)
        /// `result = lhs & rhs`, tested against zero by the branch that pops it
        case and(width: FusedAndWidth, lhs: VReg, rhs: VReg)
        /// `result = lhs & imm`, tested against zero
        case andImm(width: FusedAndWidth, lhs: VReg, imm: Int32)
        /// `result = (input == 0)` for a 32-bit `input`
        case i32Eqz(input: VReg)
        /// `result = (inner == 0)`, i.e. an `i32.eqz` applied to another
        /// fusable condition.
        ///
        /// LLVM routinely emits `<cmp>; i32.eqz; if` for a `while` whose exit
        /// test is the comparison. Recorded with the *comparison's* start
        /// position so that a following branch rewinds both instructions away
        /// and emits one fused branch of the opposite polarity.
        indirect case negated(FusableCondition)
    }

    /// The last emission, positioned, when it is a fusion candidate.
    fileprivate struct FusableEmission {
        /// The offset of the candidate's opcode slot.
        let position: MetaProgramCounter
        /// The insertion point right after the candidate's last slot.
        let end: MetaProgramCounter
        /// The register the candidate writes its `i32` result to.
        let result: VReg
        let condition: FusableCondition
        let accCompare: AccCompare?
        /// See ``AccRecords/prefix``.
        let prefix: AccProducerForm?
    }

    fileprivate struct ISeqBuilder: ~Copyable {
        typealias InstructionFactoryWithLabel = (
            borrowing ISeqBuilder,
            // The position of the next slot of the creating instruction
            _ source: MetaProgramCounter,
            // The position of the resolved label
            _ target: MetaProgramCounter
        ) -> (WasmKit.Instruction)
        typealias BrTableEntryFactory = (borrowing ISeqBuilder, MetaProgramCounter) -> Instruction.BrTableOperand.Entry
        typealias BuildingBrTable = UnsafeMutableBufferPointer<Instruction.BrTableOperand.Entry>
        typealias BuildingCatchTable = UnsafeMutableBufferPointer<CatchTableEntry>

        enum OnPinAction {
            case emitInstruction(
                insertAt: MetaProgramCounter,
                source: MetaProgramCounter,
                InstructionFactoryWithLabel
            )
            case fillBrTableEntry(
                buildingTable: BuildingBrTable,
                index: Int, make: BrTableEntryFactory
            )
            case fillCatchTableEntry(
                buildingTable: BuildingCatchTable,
                index: Int,
                /// The position of the `catchHandlers` instruction (used to compute relative offset)
                catchHandlersPC: MetaProgramCounter
            )
        }
        struct LabelUser: CustomStringConvertible {
            let action: OnPinAction
            let sourceLine: UInt

            var description: String {
                "LabelUser:\(sourceLine)"
            }
        }
        enum LabelEntry {
            case unpinned(users: [LabelUser])
            case pinned(MetaProgramCounter)
        }

        typealias ResultRelink = (_ result: VReg) -> Instruction
        fileprivate struct LastEmission {
            let position: MetaProgramCounter
            /// The insertion point right after the emitted instruction.
            let end: MetaProgramCounter
            let resultRelink: ResultRelink?
            /// Set when the emission can be folded into a following conditional
            /// branch. See ``FusableCondition``.
            ///
            /// `start` is where the buffer must be rewound to when the fusion
            /// happens. It is normally this emission's own `position`, but is
            /// earlier when the emission extends a condition another
            /// instruction already computed (`<cmp>` + `i32.eqz`), in which
            /// case both instructions are replaced by the fused branch.
            let fusable: (condition: FusableCondition, result: VReg, start: MetaProgramCounter)?
            /// Set when the emission is a binary operation whose result can be
            /// folded into the operation that consumes it. See
            /// ``BinaryEmission``.
            let binary: BinaryOperation?
        }

        private var labels: [LabelEntry] = []
        private var unpinnedLabels: Set<LabelRef> = []
        private var instructions: [UInt64] = []
        private var lastEmission: LastEmission?
        /// Kept apart from a presence flag, so that forgetting the records on
        /// every operand pop is a single store.
        private var lastAccRecords = AccRecords()
        private var hasLastAcc = false
        private var lastAcc: AccRecords? { hasLastAcc ? lastAccRecords : nil }
        /// The last emission's accumulator producer after its result was
        /// relinked into a local. Unlike ``lastAcc`` it survives operand pops:
        /// the slot stays written, so it only has to be the last thing in the
        /// buffer, which ``accProducer`` checks.
        private var lastAccAndSlot: AccProducer?
        /// Off for a debuggable module: an accumulator is live only between one
        /// instruction and the next, and a resume re-enters the dispatch loop
        /// with a fresh one, so a stop anywhere in a hand-off loses the value.
        /// A relinked producer also reads as a separate guest instruction from
        /// the consumer.
        var tracksAcc = true
        /// A copy emitted right after an accumulator producer, which hands
        /// the accumulator on untouched once fused with a following write of
        /// the producer's result.
        private var copyAfterAcc: (producer: AccProducer, source: VReg, dest: VReg, end: MetaProgramCounter)?
        /// The last emitted single copy, for pairing it with the next one.
        private var lastCopy: (source: VReg, dest: VReg, position: MetaProgramCounter, end: MetaProgramCounter)?
        /// The highest offset any label has been pinned at.
        ///
        /// Rewinding the instruction buffer past a pinned label would silently
        /// retarget or dangle it, so ``canRewind(to:)`` refuses to do so.
        private var highestPinnedLabelOffset: Int = 0
        fileprivate var insertingPC: MetaProgramCounter {
            MetaProgramCounter(offsetFromHead: instructions.count)
        }
        let engineConfiguration: EngineConfiguration

        init(engineConfiguration: EngineConfiguration) {
            self.engineConfiguration = engineConfiguration
        }

        func assertDanglingLabels() throws(WasmKitError) {
            for ref in unpinnedLabels {
                let label = labels[ref]
                switch label {
                case .unpinned(let users):
                    guard !users.isEmpty else { continue }
                    throw WasmKitError("Internal consistency error: Label (#\(ref)) is used but not pinned at finalization-time: \(users)")
                case .pinned: break  // unreachable in theory
                }
            }
        }

        func trace(_ message: @autoclosure () -> String) {
            #if WASMKIT_TRANSLATOR_TRACE
                print(message())
            #endif
        }

        private mutating func assign(at index: Int, _ instruction: Instruction) {
            trace("assign: \(instruction)")
            let headSlot = instruction.headSlot(threadingModel: engineConfiguration.threadingModel)
            trace("        [\(index)] = 0x\(String(headSlot, radix: 16))")
            self.instructions[index] = headSlot
            var slots: [CodeSlot] = []
            instruction.emitImmediate(to: { slots.append($0) })
            for (i, slot) in slots.enumerated() {
                let slotIndex = index + 1 + i
                trace("        [\(slotIndex)] = 0x\(String(slot, radix: 16))")
                self.instructions[slotIndex] = slot
            }
        }

        /// Overwrites the instruction previously emitted at `position`.
        ///
        /// The replacement must occupy the same number of code slots as the instruction it
        /// replaces, which holds for a fuel meter: it is always a `consumeFuel` with a
        /// fixed-width immediate, emitted with a zero cost and patched with the real one.
        mutating func patch(at position: MetaProgramCounter, _ instruction: Instruction) {
            assign(at: position.offsetFromHead, instruction)
        }

        mutating func resetLastEmission() {
            lastEmission = nil
            hasLastAcc = false
        }

        /// Records what the instruction just emitted offers to the accumulator
        /// hand-off.
        mutating func recordAcc(_ records: AccRecords) {
            guard tracksAcc else { return }
            lastAccRecords = records
            hasLastAcc = true
        }

        /// Forgets how to relink the last emission's result, but keeps what it
        /// offers to a fusion.
        ///
        /// Used when a value that emits nothing (a local or a constant slot) is
        /// pushed above the emission's result: a following `local.set` pops that
        /// value, so it must not relink the emission. The compare+branch fusion
        /// and the float superinstructions check that they consume the
        /// emission's own result, so their records stay valid.
        mutating func dropResultRelink() {
            guard let emission = lastEmission else { return }
            lastEmission = LastEmission(
                position: emission.position, end: emission.end, resultRelink: nil,
                fusable: emission.fusable, binary: emission.binary
            )
        }

        /// The last emitted instruction if it can be fused with a conditional
        /// branch emitted right after it.
        fileprivate var fusableEmission: FusableEmission? {
            guard let lastEmission, let fusable = lastEmission.fusable else { return nil }
            return FusableEmission(
                position: fusable.start,
                end: lastEmission.end,
                result: fusable.result,
                condition: fusable.condition,
                accCompare: lastAcc?.compare,
                prefix: lastAcc?.prefix?.producer
            )
        }

        /// The last emitted instruction when it is a binary operation whose
        /// result a following operation can consume from a register.
        fileprivate var binaryEmission: BinaryEmission? {
            guard let lastEmission, let binary = lastEmission.binary else { return nil }
            return BinaryEmission(
                position: lastAcc?.prefix?.position ?? lastEmission.position,
                end: lastEmission.end, operation: binary, prefix: lastAcc?.prefix?.producer
            )
        }

        /// The last emitted instruction when it can produce its result into the
        /// accumulator instead.
        ///
        /// Direct threading only: the token-threaded dispatcher has no
        /// accumulator.
        fileprivate var accProducer: AccProducer? {
            guard engineConfiguration.threadingModel == .direct else { return nil }
            if let lastEmission, let acc = lastAcc?.producer {
                return AccProducer(position: lastEmission.position, end: lastEmission.end, form: acc)
            }
            guard let lastAccAndSlot, lastAccAndSlot.end.offsetFromHead == insertingPC.offsetFromHead else { return nil }
            return lastAccAndSlot
        }

        /// Whether `producer` is still the last thing in the buffer.
        fileprivate func canRewind(to producer: AccProducer) -> Bool {
            guard producer.end.offsetFromHead == insertingPC.offsetFromHead else { return false }
            return canRewind(to: producer.position)
        }

        /// Whether `emission` is still the last thing in the buffer and can be
        /// replaced by a two-operation superinstruction.
        fileprivate func canRewind(to emission: BinaryEmission) -> Bool {
            guard emission.end.offsetFromHead == insertingPC.offsetFromHead else { return false }
            return canRewind(to: emission.position)
        }

        /// Whether `emission` is still the last thing in the buffer and can be
        /// replaced by a fused compare+branch.
        fileprivate func canRewind(to emission: FusableEmission) -> Bool {
            // Anything emitted after the candidate (e.g. `preserveOnStack`
            // copies) makes the fusion unsound.
            guard emission.end.offsetFromHead == insertingPC.offsetFromHead else { return false }
            return canRewind(to: emission.position)
        }

        /// Whether the buffer can be rewound to `position` without moving or
        /// dangling a label that has already been pinned.
        fileprivate func canRewind(to position: MetaProgramCounter) -> Bool {
            guard position.offsetFromHead <= instructions.count else { return false }
            // A label pinned strictly after `position` would be retargeted at
            // whatever is emitted in place of the removed instructions. A label
            // pinned exactly at `position` is fine: it keeps pointing at the
            // start of the replacement.
            return highestPinnedLabelOffset <= position.offsetFromHead
        }

        /// Drops every pending user of an unpinned label so the instructions
        /// referring to it can be rewound away.
        ///
        /// The label must not have been pinned yet, and is never pinned
        /// afterwards -- it simply disappears together with its only user.
        fileprivate mutating func discardUnpinnedLabel(_ ref: LabelRef) {
            guard case .unpinned = self.labels[ref] else {
                preconditionFailure("Internal consistency error: Label (#\(ref)) is already pinned and cannot be discarded")
            }
            self.labels[ref] = .unpinned(users: [])
            self.unpinnedLabels.remove(ref)
        }

        /// Drops every slot from `position` to the end of the buffer.
        ///
        /// Only valid when ``canRewind(to:)`` returned true for the emission
        /// starting at `position`.
        fileprivate mutating func rewind(to position: MetaProgramCounter) {
            assert(position.offsetFromHead <= instructions.count)
            assert(highestPinnedLabelOffset <= position.offsetFromHead)
            #if DEBUG
                for ref in unpinnedLabels {
                    guard case .unpinned(let users) = labels[ref] else { continue }
                    for user in users {
                        guard case .emitInstruction(let insertAt, _, _) = user.action else { continue }
                        assert(
                            insertAt.offsetFromHead < position.offsetFromHead,
                            "rewinding over a pending label user (\(user))"
                        )
                    }
                }
            #endif
            trace("rewind: \(instructions.count) -> \(position.offsetFromHead)")
            instructions.removeLast(instructions.count - position.offsetFromHead)
            resetLastEmission()
            lastAccAndSlot = nil
            copyAfterAcc = nil
            lastCopy = nil
        }

        /// Records a single copy just emitted at `position`.
        mutating func recordCopy(source: VReg, dest: VReg, position: MetaProgramCounter) {
            lastCopy = (source, dest, position, insertingPC)
        }

        /// The copy right before the insertion point, when a copy reading
        /// `source` can run together with it: nothing was emitted since, no
        /// label lands between the two, and it does not write `source`.
        fileprivate func pairableCopy(reading source: VReg) -> (source: VReg, dest: VReg, position: MetaProgramCounter)? {
            guard let copy = lastCopy, copy.end.offsetFromHead == insertingPC.offsetFromHead,
                copy.dest != source, canRewind(to: copy.position)
            else { return nil }
            return (copy.source, copy.dest, copy.position)
        }

        /// The copy right before the insertion point when it writes `dest`
        /// and no label lands after it.
        fileprivate func copy(into dest: VReg) -> (source: VReg, position: MetaProgramCounter)? {
            guard let copy = lastCopy, copy.end.offsetFromHead == insertingPC.offsetFromHead,
                copy.dest == dest, canRewind(to: copy.position)
            else { return nil }
            return (copy.source, copy.position)
        }

        /// Records that `source` was just copied to `dest` right after
        /// `producer`.
        mutating func recordCopy(after producer: AccProducer, source: VReg, dest: VReg) {
            guard tracksAcc else { return }
            copyAfterAcc = (producer, source, dest, insertingPC)
        }

        /// The producer of `value` and the copy between it and the insertion
        /// point, when the copy neither reads nor writes `value`.
        fileprivate func accProducerAcrossCopy(of value: VReg) -> (producer: AccProducer, source: VReg, dest: VReg)? {
            guard let copy = copyAfterAcc, copy.end.offsetFromHead == insertingPC.offsetFromHead,
                copy.producer.form.result == value, copy.source != value, copy.dest != value,
                canRewind(to: copy.producer.position)
            else { return nil }
            return (copy.producer, copy.source, copy.dest)
        }

        mutating func relinkLastInstructionResult(_ newResult: VReg) -> Bool {
            guard let lastEmission = self.lastEmission,
                let resultRelink = lastEmission.resultRelink
            else { return false }
            let newInstruction = resultRelink(newResult)
            assign(at: lastEmission.position.offsetFromHead, newInstruction)
            if tracksAcc, let form = lastAcc?.producer, form.hasAccAndSlotForm {
                lastAccAndSlot = AccProducer(
                    position: lastEmission.position, end: lastEmission.end, form: form.relinked(to: newResult), keepsSlot: true)
            }
            resetLastEmission()
            return true
        }

        private mutating func emitSlot(_ codeSlot: CodeSlot) {
            trace("emitSlot[\(instructions.count)]: 0x\(String(codeSlot, radix: 16))")
            self.instructions.append(codeSlot)
        }

        func dump() {
            for instruction in instructions {
                print(instruction)
            }
        }

        consuming func finalize() -> [UInt64] {
            return instructions
        }

        /// - Parameter fusable: the condition this emission makes available to
        ///   a following conditional branch, and the position a fusion has to
        ///   rewind to (`nil` start = this instruction's own position).
        mutating func emit(
            _ instruction: Instruction,
            resultRelink: ResultRelink? = nil,
            fusable: (condition: FusableCondition, result: VReg, start: MetaProgramCounter?)? = nil,
            binary: BinaryOperation? = nil
        ) {
            let position = insertingPC
            trace("emitInstruction: \(instruction)")
            emitSlot(instruction.headSlot(threadingModel: engineConfiguration.threadingModel))
            var slots: [CodeSlot] = []
            instruction.emitImmediate(to: { slots.append($0) })
            for slot in slots { emitSlot(slot) }
            self.lastEmission = LastEmission(
                position: position, end: insertingPC,
                resultRelink: resultRelink,
                fusable: fusable.map { ($0.condition, $0.result, $0.start ?? position) },
                binary: binary
            )
            hasLastAcc = false
        }

        mutating func putLabel() -> LabelRef {
            let ref = labels.count
            self.labels.append(.pinned(insertingPC))
            self.highestPinnedLabelOffset = max(self.highestPinnedLabelOffset, insertingPC.offsetFromHead)
            return ref
        }

        mutating func allocLabel() -> LabelRef {
            let ref = labels.count
            self.labels.append(.unpinned(users: []))
            self.unpinnedLabels.insert(ref)
            return ref
        }

        fileprivate func resolveLabel(_ ref: LabelRef) -> MetaProgramCounter? {
            let entry = self.labels[ref]
            switch entry {
            case .pinned(let pc): return pc
            case .unpinned: return nil
            }
        }

        fileprivate mutating func pinLabel(_ ref: LabelRef, pc: MetaProgramCounter) throws(WasmKitError) {
            switch self.labels[ref] {
            case .pinned(let oldPC):
                throw WasmKitError("Internal consistency error: Label \(ref) is already pinned at \(oldPC), but tried to pin at \(pc) again")
            case .unpinned(let users):
                self.labels[ref] = .pinned(pc)
                self.unpinnedLabels.remove(ref)
                self.highestPinnedLabelOffset = max(self.highestPinnedLabelOffset, pc.offsetFromHead)
                for user in users {
                    switch user.action {
                    case .emitInstruction(let insertAt, let source, let make):
                        assign(at: insertAt.offsetFromHead, make(self, source, pc))
                    case .fillBrTableEntry(let brTable, let index, let make):
                        brTable[index] = make(self, pc)
                    case .fillCatchTableEntry(let catchTable, let index, let catchHandlersPC):
                        // pcOffset is relative to the PC position after the catchHandlers instruction
                        catchTable[index].pcOffset = Int32(pc.offsetFromHead - catchHandlersPC.offsetFromHead)
                    }
                }
            }
        }

        mutating func pinLabelHere(_ ref: LabelRef) throws(WasmKitError) {
            try pinLabel(ref, pc: insertingPC)
        }

        /// Emit an instruction at the current insertion point with resolved label position
        /// - Parameters:
        ///   - ref: Label reference to be resolved
        ///   - make: Factory closure to make an inserting instruction
        mutating func emitWithLabel<Immediate: InstructionImmediate>(
            _ makeInstruction: @escaping (Immediate) -> Instruction,
            _ ref: LabelRef,
            line: UInt = #line,
            make:
                @escaping (
                    borrowing ISeqBuilder,
                    // The position of the next slot of the creating instruction
                    _ source: MetaProgramCounter,
                    // The position of the resolved label
                    _ target: MetaProgramCounter
                ) -> (Immediate)
        ) {
            let insertAt = insertingPC

            // Emit dummy instruction to be replaced later
            emitSlot(0)  // dummy opcode
            var immediateSlots = 0
            Immediate.emit(to: { _ in immediateSlots += 1 })
            for _ in 0..<immediateSlots { emitSlot(0) }

            // Schedule actual emission
            emitWithLabel(
                ref, insertAt: insertAt, line: line,
                make: {
                    makeInstruction(make($0, $1, $2))
                })
        }

        /// Emit a branch instruction with a single immediate slot at the current
        /// insertion point with a resolved label position.
        ///
        /// Unlike ``emitWithLabel(_:_:line:make:)`` the immediate type is not
        /// statically known here, which is what lets the compare+branch fusion
        /// pick between `BrIfCmpOperand` and `BrIfOperand` at runtime. Every
        /// branch immediate occupies exactly one code slot.
        mutating func emitBranchWithLabel(
            _ ref: LabelRef,
            immediateSlots: Int = 1,
            line: UInt = #line,
            make: @escaping InstructionFactoryWithLabel
        ) {
            let insertAt = insertingPC
            emitSlot(0)  // dummy opcode
            for _ in 0..<immediateSlots { emitSlot(0) }  // dummy immediate
            emitWithLabel(
                ref, insertAt: insertAt, line: line,
                make: { builder, source, target in
                    let instruction = make(builder, source, target)
                    #if DEBUG
                        var slotCount = 0
                        instruction.emitImmediate(to: { _ in slotCount += 1 })
                        assert(slotCount == immediateSlots, "emitBranchWithLabel reserved \(immediateSlots) immediate slots but the instruction has \(slotCount)")
                    #endif
                    return instruction
                })
        }

        /// Emit an instruction at the specified position with resolved label position
        /// - Parameters:
        ///   - ref: Label reference to be resolved
        ///   - insertAt: Instruction sequence offset to insert at
        ///   - make: Factory closure to make an inserting instruction
        private mutating func emitWithLabel(
            _ ref: LabelRef, insertAt: MetaProgramCounter,
            line: UInt = #line, make: @escaping InstructionFactoryWithLabel
        ) {
            switch self.labels[ref] {
            case .pinned(let pc):
                assign(at: insertAt.offsetFromHead, make(self, insertingPC, pc))
            case .unpinned(var users):
                users.append(LabelUser(action: .emitInstruction(insertAt: insertAt, source: insertingPC, make), sourceLine: line))
                self.labels[ref] = .unpinned(users: users)
            }
        }

        /// Schedule to fill a br_table entry with the resolved label position
        /// - Parameters:
        ///   - ref: Label reference to be resolved
        ///   - table: Building br_table buffer
        ///   - index: Index of the entry to fill
        ///   - make: Factory closure to make an br_table entry
        mutating func fillBrTableEntry(
            _ ref: LabelRef,
            table: BuildingBrTable,
            index: Int, line: UInt = #line,
            make: @escaping BrTableEntryFactory
        ) {
            switch self.labels[ref] {
            case .pinned(let pc):
                table[index] = make(self, pc)
            case .unpinned(var users):
                users.append(LabelUser(action: .fillBrTableEntry(buildingTable: table, index: index, make: make), sourceLine: line))
                self.labels[ref] = .unpinned(users: users)
            }
        }

        /// Schedule to fill a catch table entry with the resolved label position.
        mutating func fillCatchTableEntry(
            _ ref: LabelRef,
            table: BuildingCatchTable,
            index: Int,
            catchHandlersPC: MetaProgramCounter,
            line: UInt = #line
        ) {
            switch self.labels[ref] {
            case .pinned(let pc):
                table[index].pcOffset = Int32(pc.offsetFromHead - catchHandlersPC.offsetFromHead)
            case .unpinned(var users):
                users.append(
                    LabelUser(
                        action: .fillCatchTableEntry(buildingTable: table, index: index, catchHandlersPC: catchHandlersPC),
                        sourceLine: line
                    ))
                self.labels[ref] = .unpinned(users: users)
            }
        }
    }

    struct Locals {
        let types: [ValueType]

        var count: Int { types.count }

        func type(of localIndex: UInt32) throws(WasmKitError) -> ValueType {
            guard Int(localIndex) < types.count else {
                throw WasmKitError("Local index \(localIndex) is out of range")
            }
            return self.types[Int(localIndex)]
        }
    }

    struct ConstSlots {
        private(set) var values: [UntypedValue]
        private var indexByValue: [UntypedValue: Int]
        let stackLayout: StackLayout

        init(stackLayout: StackLayout) {
            self.values = []
            self.indexByValue = [:]
            self.stackLayout = stackLayout
        }

        /// Constants that may still be given a slot. Capped at the pool size, so
        /// ``allocate(_:)`` cannot run out.
        private var reserved: Set<UntypedValue> = []

        /// Reserves pool space for `value`; `false` when the pool is full.
        mutating func reserve(_ value: UntypedValue) -> Bool {
            // NOTE: Share the same const slot for exactly the same bit pattern
            // values even having different types
            if reserved.contains(value) { return true }
            guard reserved.count < stackLayout.constantSlotSize else { return false }
            reserved.insert(value)
            return true
        }

        /// The slot of a reserved constant, assigned on first use.
        mutating func allocate(_ value: UntypedValue) -> Int {
            if let allocated = indexByValue[value] { return allocated }
            assert(reserved.contains(value), "allocating a constant that was never reserved")
            let constSlotIndex = values.count
            values.append(value)
            indexByValue[value] = constSlotIndex
            return constSlotIndex
        }
    }

    let allocator: ISeqAllocator
    let funcTypeInterner: Interner<FunctionType>
    let engineConfiguration: EngineConfiguration
    var module: InternalInstance
    /// The fuel region being translated, when the engine meters fuel; `nil` otherwise.
    private var fuelRegion: FuelRegion?
    private var iseqBuilder: ISeqBuilder
    var controlStack: ControlStack
    var valueStack: ValueStack
    var locals: Locals
    let type: FunctionType
    let stackLayout: StackLayout
    /// The index of the function in the module
    let functionIndex: FunctionIndex
    /// Whether a call to this function should be intercepted
    let isIntercepting: Bool
    var constantSlots: ConstSlots

    /// The highest slot index this function addresses, tracked for the frame-range
    /// check in ``finalize()``.
    ///
    /// ``ValueStack/maxSlotHeight`` covers the value stack itself; this covers the
    /// places that reach past it, namely a call's `spAddend` (which adds the
    /// callee's frame header) and a `return_call`'s frame-header resize.
    var maxFrameSlotIndex: Int = 0

    /// Whether the `end` that closes the function body has been visited.
    ///
    /// The root control frame stays on the control stack after that `end`, so a
    /// trailing instruction would be translated against a frame that is already
    /// finished. ``translate(code:)`` rejects anything that follows instead.
    var reachedFunctionEnd: Bool = false

    let validator: InstructionValidator

    // Wasm debugging support.

    /// Current Wasm offset, updated for every instruction including non-emitting ones.
    var binaryOffset: Int = 0 {
        didSet {
            #if WasmDebuggingSupport
                guard self.module.isDebuggable else { return }

                if self.hasEmittedSinceLastInstruction {
                    self.currentRunStartWasm = self.binaryOffset
                    self.hasEmittedSinceLastInstruction = false
                } else if self.currentRunStartWasm == nil {
                    self.currentRunStartWasm = self.binaryOffset
                }
            #endif
        }
    }

    #if WasmDebuggingSupport
        /// Start of the Wasm instruction run sharing the current bytecode slot.
        var currentRunStartWasm: Int?

        /// True if bytecode was emitted since the last instruction.
        var hasEmittedSinceLastInstruction: Bool = false

        /// Pending mappings from iseq bytecode offsets to their canonical and emitting Wasm addresses.
        var iseqToWasmMapping = [(iseq: Int, canonical: Int, emitting: Int)]()
    #endif

    init(
        allocator: ISeqAllocator,
        engineConfiguration: EngineConfiguration,
        funcTypeInterner: Interner<FunctionType>,
        module: InternalInstance,
        type: FunctionType,
        locals: [WasmTypes.ValueType],
        functionIndex: FunctionIndex,
        codeSize: Int,
        isIntercepting: Bool
    ) throws(WasmKitError) {
        self.allocator = allocator
        self.funcTypeInterner = funcTypeInterner
        self.engineConfiguration = engineConfiguration
        self.type = type
        self.module = module
        self.iseqBuilder = ISeqBuilder(engineConfiguration: engineConfiguration)
        self.iseqBuilder.tracksAcc = !module.isDebuggable
        self.controlStack = ControlStack()
        let locals = try module.typeCanonicalizer.canonicalize(locals)
        self.stackLayout = try StackLayout(
            type: type,
            locals: locals,
            codeSize: codeSize
        )
        self.valueStack = ValueStack(stackLayout: stackLayout)
        self.locals = Locals(types: type.parameters + locals)
        self.functionIndex = functionIndex
        self.isIntercepting = isIntercepting
        self.constantSlots = ConstSlots(stackLayout: stackLayout)
        self.validator = InstructionValidator(context: module)
        self.maxFrameSlotIndex = stackLayout.stackRegBaseSlotIndex

        do {
            let endLabel = self.iseqBuilder.allocLabel()
            let rootFrame = ControlStack.ControlFrame(
                blockType: type,
                valueStackHeight: 0,
                slotStackHeight: 0,
                continuation: endLabel,
                kind: .block(root: true)
            )
            self.controlStack.pushFrame(rootFrame)
        }
    }

    private func returnReg(_ index: Int) -> VReg {
        return stackLayout.frameHeader.returnReg(index)
    }
    private func localReg(_ index: LocalIndex) -> VReg {
        return stackLayout.localReg(index)
    }

    private mutating func emit(
        _ instruction: Instruction,
        resultRelink: ISeqBuilder.ResultRelink? = nil,
        fusable: (condition: FusableCondition, result: VReg, start: MetaProgramCounter?)? = nil,
        binary: BinaryOperation? = nil
    ) {
        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emit(instruction, resultRelink: resultRelink, fusable: fusable, binary: binary)
        self.updateInstructionMapping(from: oldPC)
    }

    // MARK: - Fuel metering

    /// Emits the meter for a region starting here and makes it the region being charged.
    ///
    /// Does nothing when the engine does not meter fuel. The meter is attached to the control
    /// frame on top of the stack, which must be the frame that owns the region, so that
    /// ``closeFuelRegion(of:)`` can give it its final cost when that frame ends.
    private mutating func openFuelRegion() {
        guard engineConfiguration.fuelMetering else { return }
        let meter = iseqBuilder.insertingPC
        emit(.consumeFuel(Instruction.ConsumeFuelOperand(raw: 0)))
        // A peephole fusion that rewound past the meter would drop the charge and leave the
        // patch position pointing at unrelated code, so put it out of the rewinder's reach.
        iseqBuilder.resetLastEmission()
        let enclosing = fuelRegion
        let region = FuelRegion(meter: meter, cost: 0)
        fuelRegion = region
        controlStack.setCurrentFuelRegion(region, enclosing: enclosing)
    }

    /// Writes the accumulated cost into the meter `frame` opened, and makes the enclosing region
    /// current again. Does nothing for a frame that shares its parent's meter.
    private mutating func closeFuelRegion(of frame: ControlStack.ControlFrame) {
        guard frame.fuelRegion != nil, let region = fuelRegion else { return }
        iseqBuilder.patch(at: region.meter, .consumeFuel(Instruction.ConsumeFuelOperand(raw: region.cost)))
        fuelRegion = frame.enclosingFuelRegion
    }

    /// Prices the operator about to be translated at one unit, in the region being translated.
    ///
    /// Charged before the operator is visited, so that it lands in the region that is current at
    /// that moment rather than in one the operator itself opens: an `if` belongs to the region
    /// that evaluates its condition, not to the arm it guards.
    ///
    /// The operators that generate no code give the unit back in ``refundFuelForFreeOperator()``.
    /// Pricing this way, rather than by asking what the operator is, keeps the translator from
    /// switching over every operator kind on a path the visitor is already dispatching on.
    ///
    /// Operators in unreachable code are not charged: the translator emits nothing for them, so
    /// charging would bill a guest for work it cannot do.
    private mutating func chargeFuelForOperator() {
        guard fuelRegion != nil, controlStack.isCurrentFrameReachable else { return }
        fuelRegion?.cost += 1
    }

    /// Gives back the unit charged by ``chargeFuelForOperator()`` for an operator that generates
    /// no code: `nop`, `drop`, `block`, `loop`, `unreachable`, `return`, `else` and `end`.
    ///
    /// Call it as the first act of the visit method, before anything that opens or closes a region
    /// or changes reachability, so that the refund lands where the charge did.
    private mutating func refundFuelForFreeOperator() {
        guard fuelRegion != nil, controlStack.isCurrentFrameReachable else { return }
        fuelRegion?.cost -= 1
    }

    @discardableResult
    private mutating func emitCopyStack(from source: VReg, to dest: VReg) -> Bool {
        guard source != dest else { return false }
        if engineConfiguration.threadingModel == .direct, !module.isDebuggable,
            let previous = iseqBuilder.pairableCopy(reading: source)
        {
            iseqBuilder.rewind(to: previous.position)
            self.rewindInstructionMapping(to: previous.position)
            emit(.copyStack2(Instruction.CopyStack2Operand(source0: previous.source, dest0: previous.dest, source1: source, dest1: dest)))
            return true
        }
        let producer = iseqBuilder.accProducer
        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emit(.copyStack(Instruction.CopyStackOperand(source: LVReg(source), dest: LVReg(dest))))
        self.updateInstructionMapping(from: oldPC)
        iseqBuilder.recordCopy(source: source, dest: dest, position: oldPC)
        if let producer, !producer.keepsSlot, producer.end.offsetFromHead == oldPC.offsetFromHead,
            producer.form.producing(into: .integer) != nil
        {
            iseqBuilder.recordCopy(after: producer, source: source, dest: dest)
        }
        return true
    }

    @discardableResult
    private mutating func emitCopyValueSlots(_ type: ValueType, from source: VReg, to dest: VReg) -> Bool {
        var copied = false
        for offset in 0..<type.stackSlotCount {
            copied = emitCopyStack(from: source + VReg(slotIndex: offset), to: dest + VReg(slotIndex: offset)) || copied
        }
        return copied
    }

    /// Check that materializing the top `depth` values does not reach into an
    /// enclosing control frame.
    ///
    /// Materialization rewrites the value-stack entry to
    /// ``MetaValueOnStack/stack(_:)`` for the rest of translation, but emits its
    /// copy at the current position. That is only sound when the copy dominates
    /// every later read, which holds within the innermost frame -- straight-line
    /// code since the frame was entered -- but not for values belonging to an
    /// enclosing frame: a path that skips this point would leave the slot
    /// undefined while translation assumes it holds the value. Block-like
    /// constructs therefore materialize their whole stack on entry, and this
    /// check catches any site that reintroduces the hazard.
    private func assertPreservationStaysInCurrentFrame(depth: Int, caller: StaticString = #function) {
        #if DEBUG
            guard let frame = try? controlStack.currentFrame() else { return }
            for offset in 0..<Swift.min(depth, valueStack.valueHeight) {
                let index = valueStack.valueHeight - 1 - offset
                guard index < frame.valueStackHeight else { continue }
                assert(
                    valueStack.isMaterialized(at: index),
                    "[\(caller)] value at stack index \(index) belongs to an enclosing"
                        + " control frame (which starts at \(frame.valueStackHeight)); its"
                        + " copy would not dominate all later reads of the slot"
                )
            }
        #endif
    }

    /// Emit copy instructions to ensure local and constant values on the logical
    /// stack are on the physical stack.
    ///
    /// > Important: This permanently rewrites the affected value-stack entries to
    /// > ``MetaValueOnStack/stack(_:)``, so every later reference to them reads the
    /// > physical slot. The copies emitted here must therefore dominate the rest of
    /// > the block, which is why block-like constructs preserve the *whole* stack on
    /// > entry rather than just their parameters: a branch nested inside the block
    /// > would otherwise materialize an enclosing frame's value on its own path only,
    /// > leaving the slot undefined on the paths that skip it.
    private mutating func preserveOnStack(depth: Int, site: StaticString = #function) {
        assertPreservationStaysInCurrentFrame(depth: depth, caller: site)
        preserveLocalsOnStack(depth: depth)
        for (value, dest, type) in valueStack.preserveConstsOnStack(depth: depth) {
            emitCopyValueSlots(type, from: stackLayout.constReg(constantSlots.allocate(value)), to: dest)
        }
    }

    private mutating func preserveLocalsOnStack(_ localIndex: LocalIndex) {
        assertPreservationStaysInCurrentFrame(depth: valueStack.valueHeight)
        for (copyTo, type) in valueStack.preserveLocalsOnStack(localIndex) {
            emitCopyValueSlots(type, from: localReg(localIndex), to: copyTo)
        }
    }

    /// Emit copy instructions to ensure local variable values on the logical
    /// stack are on the physical stack.
    ///
    /// - Parameter depth: The depth of the logical stack to ensure the values
    ///   are on the physical stack.
    private mutating func preserveLocalsOnStack(depth: Int) {
        for (sourceLocal, destReg, type) in valueStack.preserveLocalsOnStack(depth: depth) {
            emitCopyValueSlots(type, from: localReg(sourceLocal), to: destReg)
        }
    }

    /// Perform a precondition check for pop operation on value stack.
    ///
    /// - Parameter typeHint: A type expected to be popped. Only used for diagnostic purpose.
    /// - Returns: `true` if check succeed. `false` if the pop operation is going to be performed in unreachable code path.
    private func checkBeforePop(typeHint: ValueType?, depth: Int = 0, controlFrame: ControlStack.ControlFrame) throws(WasmKitError) -> Bool {
        if _slowPath(valueStack.valueHeight - depth <= controlFrame.valueStackHeight) {
            if controlFrame.reachable {
                throw WasmKitError(message: .expectedTypeOnStackButEmpty(expected: typeHint))
            }
            // Too many pop on unreachable path is ignored
            return false
        }
        return true
    }
    private func checkBeforePop(typeHint: ValueType?, depth: Int = 0) throws(WasmKitError) -> Bool {
        let controlFrame = try controlStack.currentFrame()
        return try self.checkBeforePop(typeHint: typeHint, depth: depth, controlFrame: controlFrame)
    }
    /// The slot `source` occupies without materializing it: `nil` for a
    /// constant.
    private func existingSlot(of source: ValueSource) -> VReg? {
        switch source {
        case .vreg(let register): return register
        case .local(let index): return stackLayout.localReg(index)
        case .const: return nil
        }
    }

    private mutating func ensureOnVReg(_ source: ValueSource) -> VReg {
        // TODO: Copy to stack if source is on preg
        // let copyTo = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
        switch source {
        case .vreg(let register):
            return register
        case .local(let index):
            return stackLayout.localReg(index)
        case .const(let value, _):
            return stackLayout.constReg(constantSlots.allocate(value))
        }
    }
    private mutating func ensureOnStack(_ source: ValueSource, type: ValueType) -> VReg {
        let copyTo = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
        switch source {
        case .vreg(let vReg):
            return vReg
        case .local(let localIndex):
            emitCopyValueSlots(type, from: localReg(localIndex), to: copyTo)
            return copyTo
        case .const(let value, _):
            emitCopyValueSlots(type, from: stackLayout.constReg(constantSlots.allocate(value)), to: copyTo)
            return copyTo
        }
    }
    private mutating func popOperand(_ type: ValueType) throws(WasmKitError) -> ValueSource? {
        guard try checkBeforePop(typeHint: type) else {
            return nil
        }
        iseqBuilder.resetLastEmission()
        return try valueStack.pop(type)
    }

    private mutating func popOnStackOperand(_ type: ValueType) throws(WasmKitError) -> VReg? {
        guard let op = try popOperand(type) else { return nil }
        return ensureOnStack(op, type: type)
    }

    private mutating func popVRegOperand(_ type: ValueType) throws(WasmKitError) -> VReg? {
        guard let op = try popOperand(type) else { return nil }
        return ensureOnVReg(op)
    }

    /// Pops an operand of any reference type, or returns nil for a missing
    /// operand of an unreachable, polymorphic stack.
    private mutating func popRefOperand() throws(WasmKitError) -> ValueSource? {
        guard try checkBeforePop(typeHint: nil) else {
            return nil
        }
        iseqBuilder.resetLastEmission()
        return try valueStack.popRef()
    }

    private mutating func popAnyOperand() throws(WasmKitError) -> (MetaValue, ValueSource?) {
        guard try checkBeforePop(typeHint: nil) else {
            return (.unknown, nil)
        }
        iseqBuilder.resetLastEmission()
        return try valueStack.pop()
    }

    @discardableResult
    private mutating func popPushValues(_ valueTypes: [ValueType]) throws(WasmKitError) -> (valueHeight: Int, slotHeight: Int) {
        var values: [ValueSource?] = []
        for type in valueTypes.reversed() {
            values.append(try popOperand(type))
        }
        let stackHeight = (valueHeight: self.valueStack.valueHeight, slotHeight: self.valueStack.slotHeight)
        for (type, value) in zip(valueTypes, values.reversed()) {
            switch value {
            case .local(let localIndex):
                // Re-push local variables to the stack
                _ = try valueStack.pushLocal(localIndex, locals: &locals)
            case .vreg, nil:
                _ = valueStack.push(type)
            case .const(let value, let type):
                valueStack.pushConst(value, type: type)
            }
        }
        return stackHeight
    }

    private func checkStackTop(_ valueTypes: [ValueType]) throws(WasmKitError) {
        for (stackDepth, type) in valueTypes.reversed().enumerated() {
            guard try checkBeforePop(typeHint: type, depth: stackDepth) else { return }
            let actual = valueStack.peekType(depth: stackDepth)
            switch actual {
            case .some(let actualType):
                guard actualType == type else {
                    throw WasmKitError(message: .expectedTypeOnStack(expected: type, actual: actualType))
                }
            case .unknown: break
            }
        }
    }

    private mutating func visitReturnLike() throws(WasmKitError) {
        try copyValuesIntoResultSlots(self.type.results, frameHeader: stackLayout.frameHeader)
    }

    /// Pop values from the stack and copy them to the return slots.
    ///
    /// - Parameter valueTypes: The types of the values to copy.
    private mutating func copyValuesIntoResultSlots(_ valueTypes: [ValueType], frameHeader: FrameHeaderLayout) throws(WasmKitError) {
        var copies: [(source: VReg, dest: VReg, type: ValueType)] = []
        for (index, resultType) in valueTypes.enumerated().reversed() {
            guard let operand = try popOperand(resultType) else { continue }
            var source = ensureOnVReg(operand)
            if case .local(let localIndex) = operand, stackLayout.isParameter(localIndex) {
                // Parameter space is shared with return values, so we need to copy it to the stack
                // before copying to the return slot to avoid overwriting the parameter value.
                let copyTo = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
                emitCopyValueSlots(resultType, from: localReg(localIndex), to: copyTo)
                source = copyTo
            }
            let dest = frameHeader.returnReg(index)
            copies.append((source, dest, resultType))
        }
        for (source, dest, type) in copies {
            emitCopyValueSlots(type, from: source, to: dest)
        }
    }

    /// Pop values from the stack and copy them to the parameter slots.
    ///
    /// This is used by `return_call`-like instructions which rewrite the current frame header
    /// to the callee's frame header layout.
    private mutating func copyValuesIntoParamSlots(_ valueTypes: [ValueType], frameHeader: FrameHeaderLayout) throws(WasmKitError) {
        var copies: [(source: VReg, dest: VReg, type: ValueType)] = []
        for (index, paramType) in valueTypes.enumerated().reversed() {
            guard let operand = try popOperand(paramType) else { continue }
            var source = ensureOnVReg(operand)
            if case .local(let localIndex) = operand, stackLayout.isParameter(localIndex) {
                // Parameter space is shared with frame header slots, so copy to stack first
                // to avoid overwriting when the destination is also in the frame header.
                let copyTo = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
                emitCopyValueSlots(paramType, from: localReg(localIndex), to: copyTo)
                source = copyTo
            }
            let dest = frameHeader.paramReg(index)
            copies.append((source, dest, paramType))
        }
        for (source, dest, type) in copies {
            emitCopyValueSlots(type, from: source, to: dest)
        }
    }

    @discardableResult
    private mutating func copyOnBranch(targetFrame frame: ControlStack.ControlFrame) throws(WasmKitError) -> Bool {
        let depthValues = min(frame.copyTypes.count, valueStack.valueHeight - frame.valueStackHeight)
        preserveOnStack(depth: depthValues)
        let copyCount = Int(frame.copySlotCount)
        let sourceBase = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
        let destBase = valueStack.stackRegBase + VReg(slotIndex: frame.slotStackHeight)
        var emittedCopy = false
        for i in (0..<copyCount).reversed() {
            let source = sourceBase + VReg(slotIndex: -1 - i)
            let dest: VReg
            if case .block(root: true) = frame.kind {
                guard frame.copySlotCount > 0 else { continue }
                dest = returnReg(0) + VReg(slotIndex: copyCount - 1 - i)
            } else {
                dest = destBase + VReg(slotIndex: copyCount - 1 - i)
            }
            let copied = emitCopyStack(from: source, to: dest)
            emittedCopy = emittedCopy || copied
        }
        return emittedCopy
    }
    private mutating func translateReturn() throws(WasmKitError) {
        if isIntercepting {
            // Emit `onExit` instruction before every `return` instruction
            emit(.onExit(functionIndex))
        }
        // Clean up all exception handlers before returning from the function
        let handlersToUnwind = controlStack.catchHandlersToUnwind(
            relativeDepth: UInt32(controlStack.numberOfFrames - 1)
        )
        if handlersToUnwind > 0 {
            emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: handlersToUnwind)))
        }
        try visitReturnLike()
        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emit(._return(.init()))
        self.updateInstructionMapping(from: oldPC)
    }
    private mutating func markUnreachable() throws(WasmKitError) {
        try controlStack.markUnreachable()
        let currentFrame = try controlStack.currentFrame()
        try valueStack.truncate(height: currentFrame.valueStackHeight)
    }

    /// The extent of the frame this function addresses, as the closed range
    /// `[lowest, highest]` of slot indices relative to `sp`.
    ///
    /// The lowest is the start of the frame header (parameters and results live
    /// below `sp`); the highest is the top of the value stack, or the `spAddend`
    /// of the widest call, whichever reaches further.
    private var frameSlotIndexExtent: (lowest: Int, highest: Int) {
        (
            lowest: -stackLayout.frameHeader.size,
            highest: max(maxFrameSlotIndex, stackLayout.stackRegBaseSlotIndex + valueStack.maxSlotHeight)
        )
    }

    /// Rejects a function whose frame does not fit the pre-shifted ``VReg``
    /// encoding.
    ///
    /// ``VReg`` stores a slot's byte offset rather than its index, which saves a
    /// shift per 32-bit operand access on arm64 at the cost of three bits of
    /// range: only slots `VReg.minSlotIndex...VReg.maxSlotIndex` are addressable.
    /// Out-of-range indices wrap silently while a function is being translated,
    /// so this check runs before the instruction sequence built from them is
    /// handed out.
    private func checkFrameFitsVRegRange() throws(WasmKitError) {
        let extent = frameSlotIndexExtent
        guard VReg.canRepresent(slotIndex: extent.lowest), VReg.canRepresent(slotIndex: extent.highest) else {
            throw WasmKitError(
                "The frame of this function is too large for the interpreter: it needs slots "
                    + "\(extent.lowest)...\(extent.highest), but only "
                    + "\(VReg.minSlotIndex)...\(VReg.maxSlotIndex) are addressable"
            )
        }
    }

    private consuming func finalize() throws(WasmKitError) -> InstructionSequence {
        if controlStack.numberOfFrames > 1 {
            throw WasmKitError(message: .expectedMoreEndInstructions(count: controlStack.numberOfFrames - 1))
        }
        try checkFrameFitsVRegRange()
        // Check dangling labels
        try iseqBuilder.assertDanglingLabels()

        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emit(._return(.init()))
        self.updateInstructionMapping(from: oldPC)
        // The function body's region closes here rather than in `visitEnd`, which returns for the
        // root frame without popping it.
        if let region = fuelRegion {
            iseqBuilder.patch(at: region.meter, .consumeFuel(Instruction.ConsumeFuelOperand(raw: region.cost)))
            fuelRegion = nil
        }
        let instructions = iseqBuilder.finalize()
        // TODO: Figure out a way to avoid the copy here while keeping the execution performance.
        let buffer = allocator.allocateInstructions(capacity: instructions.count)
        let initializedElementsIndex = buffer.initialize(fromContentsOf: instructions)
        assert(initializedElementsIndex == instructions.endIndex)

        #if WasmDebuggingSupport
            for (iseq, canonical, emitting) in self.iseqToWasmMapping {
                self.module.withValue {
                    let absoluteIseq = iseq + buffer.baseAddress.unsafelyUnwrapped
                    $0.instructionMapping.add(canonical: canonical, emitting: emitting, iseq: absoluteIseq)
                }
            }
        #endif

        let frameInit = allocator.allocateFrameInit(
            localSlots: stackLayout.numberOfNonParameterLocalSlots,
            nullReferenceSlots: stackLayout.nonParameterReferenceLocalSlots,
            constants: self.constantSlots.values
        )
        return InstructionSequence(
            instructions: buffer,
            maxStackHeight: stackLayout.stackRegBaseSlotIndex + valueStack.maxSlotHeight,
            frameInit: frameInit
        )
    }

    /// Drops the debug mapping entries of instructions removed by a rewind.
    ///
    /// Without this the mapping would keep pointing a Wasm offset at bytecode
    /// that no longer exists (or, worse, at whatever gets emitted in its place).
    private mutating func rewindInstructionMapping(to position: MetaProgramCounter) {
        #if WasmDebuggingSupport
            while let last = self.iseqToWasmMapping.last, last.iseq >= position.offsetFromHead {
                self.iseqToWasmMapping.removeLast()
            }
        #endif
    }

    /// Maps the instruction head emitted at `oldPC`. Operand slots are omitted.
    private mutating func updateInstructionMapping(from oldPC: MetaProgramCounter) {
        #if WasmDebuggingSupport
            guard self.module.isDebuggable, let canonical = self.currentRunStartWasm,
                oldPC.offsetFromHead < self.iseqBuilder.insertingPC.offsetFromHead
            else { return }

            self.iseqToWasmMapping.append((oldPC.offsetFromHead, canonical, self.binaryOffset))
            self.hasEmittedSinceLastInstruction = true
        #endif
    }

    // MARK: Main entry point

    /// Translate a Wasm expression into a sequence of instructions.
    consuming func translate(code: Code) throws(WasmKitError) -> InstructionSequence {
        if isIntercepting {
            // Emit `onEnter` instruction at the beginning of the function
            emit(.onEnter(functionIndex))
        }
        // The function body is a region: everything reachable without taking a back-edge or
        // entering an `if` arm is charged once, here, before any of it runs.
        openFuelRegion()
        var parser = ExpressionParser(code: code)
        while let visit = try WasmKitError.wrap({ () throws(WasmParserError) in try parser.parse() }) {
            chargeFuelForOperator()
            guard !reachedFunctionEnd else {
                // The expression parser only stops at an `end` that exhausts the
                // code entry, so a body with trailing operators keeps decoding.
                var error = WasmKitError(message: .controlStackEmpty)
                error.location = parser.offset
                throw error
            }
            do throws(WasmKitError) {
                try visit(visitor: &self)
            } catch {
                var errorWithOffset = error
                if errorWithOffset.location == nil {
                    errorWithOffset.location = self.binaryOffset
                }
                throw errorWithOffset
            }
        }
        return try finalize()
    }

    // MARK: - Visitor

    mutating func visitUnreachable() throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        emit(.unreachable(.init()))
        try markUnreachable()
    }
    mutating func visitNop() -> Output {
        refundFuelForFreeOperator()
        emit(.nop(.init()))
    }

    mutating func visitBlock(blockType: WasmParser.BlockType) throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        let blockType = try module.resolveBlockType(blockType)
        let endLabel = iseqBuilder.allocLabel()
        self.preserveOnStack(depth: self.valueStack.valueHeight)
        let stackHeight = try popPushValues(blockType.parameters)
        controlStack.pushFrame(
            ControlStack.ControlFrame(
                blockType: blockType,
                valueStackHeight: stackHeight.valueHeight,
                slotStackHeight: stackHeight.slotHeight,
                continuation: endLabel,
                kind: .block
            )
        )
    }

    mutating func visitLoop(blockType: WasmParser.BlockType) throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        let blockType = try module.resolveBlockType(blockType)
        preserveOnStack(depth: self.valueStack.valueHeight)
        iseqBuilder.resetLastEmission()
        for param in blockType.parameters.reversed() {
            _ = try popOperand(param)
        }
        let headLabel = iseqBuilder.putLabel()
        let stackHeight = (valueHeight: self.valueStack.valueHeight, slotHeight: self.valueStack.slotHeight)
        for param in blockType.parameters {
            _ = valueStack.push(param)
        }
        controlStack.pushFrame(
            ControlStack.ControlFrame(
                blockType: blockType,
                valueStackHeight: stackHeight.valueHeight,
                slotStackHeight: stackHeight.slotHeight,
                continuation: headLabel,
                kind: .loop
            )
        )
        // After the label, so that the back-edge lands on the meter and every iteration is
        // charged. This is what bounds a guest that loops without ever calling out.
        openFuelRegion()
    }

    mutating func visitIf(blockType: WasmParser.BlockType) throws(WasmKitError) -> Output {
        // Captured before `popVRegOperand`, which resets the last emission.
        let fusable = iseqBuilder.fusableEmission
        let accCandidate = iseqBuilder.accProducer
        // Pop condition value
        let condition = try popVRegOperand(.i32)
        let blockType = try module.resolveBlockType(blockType)
        self.preserveOnStack(depth: self.valueStack.valueHeight)
        let endLabel = iseqBuilder.allocLabel()
        let elseLabel = iseqBuilder.allocLabel()
        for param in blockType.parameters.reversed() {
            _ = try popOperand(param)
        }
        let stackHeight = (valueHeight: self.valueStack.valueHeight, slotHeight: self.valueStack.slotHeight)
        for param in blockType.parameters {
            _ = valueStack.push(param)
        }
        controlStack.pushFrame(
            ControlStack.ControlFrame(
                blockType: blockType,
                valueStackHeight: stackHeight.valueHeight,
                slotStackHeight: stackHeight.slotHeight,
                continuation: endLabel,
                kind: .if(elseLabel: elseLabel, endLabel: endLabel, isElse: false)
            )
        )
        // The `then` arm is its own region, and it must be metered after the conditional branch
        // that guards it, whichever of the branch forms below gets emitted.
        defer { openFuelRegion() }
        guard let condition = condition else { return }
        // NOTE: `preserveOnStack` above may have emitted copies; when it did,
        // `canRewind` refuses and we fall back to the unfused form.
        if let makeFused = fuseCompareIntoBranch(fusable, condition: condition) {
            let oldPC = iseqBuilder.insertingPC
            iseqBuilder.emitBranchWithLabel(endLabel, immediateSlots: makeFused.immediateSlots) { iseqBuilder, selfPC, endPC in
                let targetPC = iseqBuilder.resolveLabel(elseLabel) ?? endPC
                return makeFused.make(.ifFalse, Int32(targetPC.offsetFromHead - selfPC.offsetFromHead))
            }
            self.updateInstructionMapping(from: oldPC)
            return
        }
        if let producer = accConditionProducer(accCandidate, condition: condition) {
            rewindProducerIntoAccumulator(producer)
            let oldPC = iseqBuilder.insertingPC
            iseqBuilder.emitWithLabel(Instruction.brIfNotAcc, endLabel) { iseqBuilder, selfPC, endPC in
                let targetPC = iseqBuilder.resolveLabel(elseLabel) ?? endPC
                return Instruction.BrIfAccOperand(offset: Int32(targetPC.offsetFromHead - selfPC.offsetFromHead))
            }
            self.updateInstructionMapping(from: oldPC)
            return
        }
        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emitWithLabel(Instruction.brIfNot, endLabel) { iseqBuilder, selfPC, endPC in
            let targetPC: MetaProgramCounter
            if let elsePC = iseqBuilder.resolveLabel(elseLabel) {
                targetPC = elsePC
            } else {
                targetPC = endPC
            }
            let elseOrEnd = UInt32(targetPC.offsetFromHead - selfPC.offsetFromHead)
            return Instruction.BrIfOperand(condition: LVReg(condition), offset: Int32(elseOrEnd))
        }
        self.updateInstructionMapping(from: oldPC)
    }

    mutating func visitElse() throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        var frame = try controlStack.currentFrame()
        // `isElse: true` means this `if` already has an `else`, so a second one
        // would pin `elseLabel` twice.
        guard case .if(let elseLabel, let endLabel, isElse: false) = frame.kind else {
            throw WasmKitError(message: .expectedIfControlFrame)
        }
        preserveOnStack(depth: valueStack.valueHeight - frame.valueStackHeight)
        try controlStack.resetReachability()
        iseqBuilder.resetLastEmission()

        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emitWithLabel(Instruction.br, endLabel) { _, selfPC, endPC in
            let offset = endPC.offsetFromHead - selfPC.offsetFromHead
            return Int32(offset)
        }
        self.updateInstructionMapping(from: oldPC)
        for result in frame.blockType.results.reversed() {
            guard try checkBeforePop(typeHint: result, controlFrame: frame) else { continue }
            _ = try valueStack.pop(result)
        }
        guard valueStack.valueHeight == frame.valueStackHeight else {
            throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
        }
        guard valueStack.slotHeight == frame.slotStackHeight else {
            throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
        }
        _ = controlStack.popFrame()
        // The `then` arm ends here, so its meter can be given its final cost.
        closeFuelRegion(of: frame)
        frame.kind = .if(elseLabel: elseLabel, endLabel: endLabel, isElse: true)
        frame.reachable = true
        frame.fuelRegion = nil
        frame.enclosingFuelRegion = nil
        controlStack.pushFrame(frame)

        // Re-push parameters
        for parameter in frame.blockType.parameters {
            _ = valueStack.push(parameter)
        }
        try iseqBuilder.pinLabelHere(elseLabel)
        // The `else` arm is a region of its own, entered only when the condition was false.
        openFuelRegion()
    }

    mutating func visitEnd() throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        let toBePopped = try controlStack.currentFrame()
        iseqBuilder.resetLastEmission()
        if case .block(root: true) = toBePopped.kind {
            try translateReturn()
            guard valueStack.valueHeight == toBePopped.valueStackHeight else {
                throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
            }
            guard valueStack.slotHeight == toBePopped.slotStackHeight else {
                throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
            }
            try iseqBuilder.pinLabelHere(toBePopped.continuation)
            reachedFunctionEnd = true
            return
        }

        if case .if(_, _, isElse: false) = toBePopped.kind {
            let blockType = toBePopped.blockType
            guard blockType.parameters == blockType.results else {
                throw WasmKitError(message: .parameterResultTypeMismatch(blockType: blockType))
            }
        }

        preserveOnStack(depth: Int(valueStack.valueHeight - toBePopped.valueStackHeight))
        switch toBePopped.kind {
        case .block:
            try iseqBuilder.pinLabelHere(toBePopped.continuation)
        case .loop: break
        case .if:
            try iseqBuilder.pinLabelHere(toBePopped.continuation)
        case .tryTable(let catchCount):
            emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: catchCount)))
            try iseqBuilder.pinLabelHere(toBePopped.continuation)
        }
        for result in toBePopped.blockType.results.reversed() {
            guard try checkBeforePop(typeHint: result, controlFrame: toBePopped) else { continue }
            _ = try valueStack.pop(result)
        }
        guard valueStack.valueHeight == toBePopped.valueStackHeight else {
            throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
        }
        guard valueStack.slotHeight == toBePopped.slotStackHeight else {
            throw WasmKitError(message: .valuesRemainingAtEndOfBlock)
        }
        for result in toBePopped.blockType.results {
            _ = valueStack.push(result)
        }
        _ = controlStack.popFrame()
        // A loop body, a `then` without an `else`, or an `else`: whichever region this frame
        // opened is complete, so its meter gets the cost accumulated for it.
        closeFuelRegion(of: toBePopped)
    }

    private static func computePopCount(
        destination: ControlStack.ControlFrame,
        currentFrame: ControlStack.ControlFrame,
        currentHeight: Int
    ) throws(WasmKitError) -> UInt32 {
        let popCount: UInt32
        if _fastPath(currentFrame.reachable) {
            let count = currentHeight - Int(destination.copySlotCount) - destination.slotStackHeight
            guard count >= 0 else {
                throw WasmKitError(message: .stackHeightUnderflow(available: currentHeight, required: destination.slotStackHeight + Int(destination.copySlotCount)))
            }
            popCount = UInt32(count)
        } else {
            // Slow path: This path is taken when "br" is placed after "unreachable"
            // It's ok to put the fake popCount because it will not be executed at runtime.
            popCount = 0
        }
        return popCount
    }

    /// Which way a conditional branch tests the popped `i32` condition.
    fileprivate enum FusedBranchPolarity {
        /// Branch when the condition is non-zero (`brIf`).
        case ifTrue
        /// Branch when the condition is zero (`brIfNot`).
        case ifFalse

        var flipped: FusedBranchPolarity { self == .ifTrue ? .ifFalse : .ifTrue }
    }

    /// Builds a fused compare+branch for a given polarity and pc-relative offset.
    ///
    /// The polarity is supplied at emission time so that a branch already
    /// emitted as `ifFalse` can be re-emitted as `ifTrue` if the landing pad it
    /// skipped over turns out to be empty (see ``visitBrIf(relativeDepth:)``).
    ///
    /// The number of immediate slots is fixed before the offset is known, since
    /// the slots are reserved when the branch is emitted.
    private struct FusedBranchFactory {
        var immediateSlots = 1
        let make: (_ polarity: FusedBranchPolarity, _ offset: Int32) -> Instruction
    }

    /// Folds a just-emitted comparison into the conditional branch about to be
    /// emitted.
    ///
    /// When `candidate` computes exactly the branch's `condition` register and
    /// is still the last thing in the instruction buffer, the comparison is
    /// removed from the buffer and a factory for the fused branch is returned.
    /// The caller must then emit that instruction at the current (rewound)
    /// insertion point; the offset it is given follows the same pc-relative
    /// convention as `brIf`.
    ///
    /// The comparison result is a temporary pushed by the comparison and popped
    /// by the branch, so dropping the write is safe: `local.set`/`local.tee`
    /// and anything else that could keep the slot alive either relinks or
    /// resets the last emission, or emits its own instruction (which makes
    /// ``ISeqBuilder/canRewind(to:)`` refuse).
    private mutating func fuseCompareIntoBranch(
        _ candidate: FusableEmission?,
        condition: VReg
    ) -> FusedBranchFactory? {
        guard let candidate, candidate.result == condition else { return nil }
        guard iseqBuilder.canRewind(to: candidate) else { return nil }

        // When the comparison's operand was produced right before it, rewind
        // both and take that operand from the accumulator.
        if let acc = candidate.accCompare, iseqBuilder.canRewind(to: acc.producerPosition),
            let producer = acc.producer.producing(into: acc.register)
        {
            iseqBuilder.rewind(to: acc.producerPosition)
            self.rewindInstructionMapping(to: acc.producerPosition)
            emit(producer)
            return FusedBranchFactory { polarity, offset in acc.makeBranch(polarity: polarity, offset: offset) }
        }

        let factory = Self.fusedBranchFactory(for: candidate.condition)
        iseqBuilder.rewind(to: candidate.position)
        self.rewindInstructionMapping(to: candidate.position)
        if let prefix = candidate.prefix {
            emit(prefix.plain)
        }
        return factory
    }

    /// The fused branch that tests `condition`, as a function of the branch
    /// polarity and the pc-relative offset.
    private static func fusedBranchFactory(for condition: FusableCondition) -> FusedBranchFactory {
        switch condition {
        case .compare(let kind, let lhs, let rhs):
            return FusedBranchFactory { polarity, offset in
                let fused = polarity == .ifTrue ? kind : kind.complement
                return fused.makeBrIf(Instruction.BrIfCmpOperand(lhs: lhs, rhs: rhs, offset: offset))
            }
        case .compareImm(let kind, let lhs, let imm):
            return FusedBranchFactory(immediateSlots: 2) { polarity, offset in
                let fused = polarity == .ifTrue ? kind : kind.complement
                return fused.makeBrIfImm(Instruction.BrIfCmpImmOperand(lhs: lhs, imm: imm, offset: offset))
            }
        case .floatCompare(let kind, let lhs, let rhs):
            // The polarity is part of the opcode here; see `FusedFCmpKind`.
            return FusedBranchFactory { polarity, offset in
                kind.makeBrIf(polarity: polarity, lhs: lhs, rhs: rhs, offset: offset)
            }
        case .and(let width, let lhs, let rhs):
            // The polarity is part of the opcode here; see `FusedAndWidth`.
            return FusedBranchFactory { polarity, offset in
                width.makeBrIf(polarity: polarity, lhs: lhs, rhs: rhs, offset: offset)
            }
        case .andImm(let width, let lhs, let imm):
            return FusedBranchFactory(immediateSlots: 2) { polarity, offset in
                width.makeBrIfImm(polarity: polarity, lhs: lhs, imm: imm, offset: offset)
            }
        case .i32Eqz(let input):
            // `eqz(x)` is non-zero exactly when `x` is zero, so the fused form
            // is just the plain branch with the opposite polarity on `x`.
            return FusedBranchFactory { polarity, offset in
                let operand = Instruction.BrIfOperand(condition: LVReg(input), offset: offset)
                switch polarity {
                case .ifTrue: return Instruction.brIfNot(operand)
                case .ifFalse: return Instruction.brIf(operand)
                }
            }
        case .negated(let inner):
            // `i32.eqz` of a condition: the same branch with the polarity
            // flipped. This is not a predicate complement (which would be wrong
            // for floats under NaN): the comparison produced 0 or 1, and `eqz`
            // inverts that exactly.
            let innerFactory = fusedBranchFactory(for: inner)
            return FusedBranchFactory(immediateSlots: innerFactory.immediateSlots) { polarity, offset in
                innerFactory.make(polarity.flipped, offset)
            }
        }
    }

    private mutating func emitBranch<Immediate: InstructionImmediate>(
        _ makeInstruction: @escaping (Immediate) -> Instruction,
        relativeDepth: UInt32,
        make: @escaping (_ offset: Int32, _ copyCount: UInt32, _ popCount: UInt32) -> Immediate
    ) throws(WasmKitError) {
        let frame = try controlStack.branchTarget(relativeDepth: relativeDepth)
        let copyCount = frame.copySlotCount
        let popCount = try Self.computePopCount(
            destination: frame,
            currentFrame: try controlStack.currentFrame(),
            currentHeight: valueStack.slotHeight
        )

        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emitWithLabel(makeInstruction, frame.continuation) { _, selfPC, continuation in
            let relativeOffset = continuation.offsetFromHead - selfPC.offsetFromHead
            return make(Int32(relativeOffset), UInt32(copyCount), popCount)
        }
        self.updateInstructionMapping(from: oldPC)
    }
    /// Emit `catchHandlersEnd` instructions for any `try_table` blocks that
    /// would be exited by branching to the given relative depth.
    private mutating func emitCatchHandlersUnwind(relativeDepth: UInt32) {
        let count = controlStack.catchHandlersToUnwind(relativeDepth: relativeDepth)
        if count > 0 {
            emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: count)))
        }
    }

    mutating func visitBr(relativeDepth: UInt32) throws(WasmKitError) -> Output {
        let frame = try controlStack.branchTarget(relativeDepth: relativeDepth)

        // Copy from the stack top to the bottom to avoid overwrites
        //              [BLOCK1]
        //              [      ]
        //              [      ]
        //              [BLOCK2] () -> (i32, i64)
        // copy [1] +-->[  i32 ]
        //          +---[  i32 ]<--+ copy [2]
        //              [  i64 ]---+
        try copyOnBranch(targetFrame: frame)
        emitCatchHandlersUnwind(relativeDepth: relativeDepth)
        try emitBranch(Instruction.br, relativeDepth: relativeDepth) { offset, copyCount, popCount in
            return offset
        }
        for type in frame.copyTypes.reversed() {
            _ = try popOperand(type)
        }
        try markUnreachable()
    }

    /// The last emission when a conditional branch emitted here can read its
    /// `i32` condition from the accumulator.
    private func accConditionProducer(_ candidate: AccProducer?, condition: VReg) -> AccProducer? {
        guard let candidate, candidate.form.type == .i32, candidate.form.result == condition,
            candidate.producing(into: .integer) != nil, iseqBuilder.canRewind(to: candidate)
        else { return nil }
        return candidate
    }

    /// Removes the integer comparison computing `condition` when it is still
    /// the last instruction, returning the fused `select` to emit in its place.
    private mutating func fuseCompareIntoSelect(
        _ candidate: FusableEmission?, condition: VReg, onTrue: VReg, onFalse: VReg
    ) -> ((VReg) -> Instruction)? {
        guard engineConfiguration.threadingModel == .direct,
            let candidate, candidate.result == condition, candidate.prefix == nil, iseqBuilder.canRewind(to: candidate),
            let factory = Self.selectCmpFactory(for: candidate.condition, onTrue: onTrue, onFalse: onFalse)
        else { return nil }
        iseqBuilder.rewind(to: candidate.position)
        self.rewindInstructionMapping(to: candidate.position)
        return factory
    }

    /// The fused `select` testing `condition`, or `nil` when it is not an
    /// integer comparison. Bit tests reach `selectAcc` instead.
    private static func selectCmpFactory(
        for condition: FusableCondition, onTrue: VReg, onFalse: VReg
    ) -> ((VReg) -> Instruction)? {
        switch condition {
        case .compare(let kind, let lhs, let rhs):
            return kind.makeSelect(lhs: lhs, rhs: rhs, onTrue: onTrue, onFalse: onFalse)
        case .compareImm(let kind, let lhs, let imm):
            return kind.makeSelectImm(lhs: lhs, imm: imm, onTrue: onTrue, onFalse: onFalse)
        case .i32Eqz(let input):
            return FusedCmpKind.i32Eq.makeSelectImm(lhs: input, imm: 0, onTrue: onTrue, onFalse: onFalse)
        case .negated(let inner):
            return selectCmpFactory(for: inner, onTrue: onFalse, onFalse: onTrue)
        case .floatCompare, .and, .andImm:
            return nil
        }
    }

    /// Replaces `producer` with its form producing into `register`, which it
    /// must have. The caller must emit the instruction that reads the
    /// accumulator right after.
    private mutating func rewindProducerIntoAccumulator(_ producer: AccProducer, _ register: AccRegister = .integer) {
        iseqBuilder.rewind(to: producer.position)
        self.rewindInstructionMapping(to: producer.position)
        emit(producer.producing(into: register)!)
    }

    mutating func visitBrIf(relativeDepth: UInt32) throws(WasmKitError) -> Output {
        // Captured before `popVRegOperand`, which resets the last emission.
        let fusable = iseqBuilder.fusableEmission
        let accCandidate = iseqBuilder.accProducer
        let frame = try controlStack.branchTarget(relativeDepth: relativeDepth)
        let condition = try popVRegOperand(.i32)
        let handlersToUnwind = controlStack.catchHandlersToUnwind(relativeDepth: relativeDepth)

        if frame.copySlotCount == 0 && handlersToUnwind == 0 {
            guard let condition else { return }
            // Optimization where we don't need copying values when the branch taken
            // and no exception handlers need unwinding.
            if let makeFused = fuseCompareIntoBranch(fusable, condition: condition) {
                let oldPC = iseqBuilder.insertingPC
                iseqBuilder.emitBranchWithLabel(frame.continuation, immediateSlots: makeFused.immediateSlots) { _, selfPC, continuation in
                    makeFused.make(.ifTrue, Int32(continuation.offsetFromHead - selfPC.offsetFromHead))
                }
                self.updateInstructionMapping(from: oldPC)
                return
            }
            if let producer = accConditionProducer(accCandidate, condition: condition) {
                rewindProducerIntoAccumulator(producer)
                let oldPC = iseqBuilder.insertingPC
                iseqBuilder.emitWithLabel(Instruction.brIfAcc, frame.continuation) { _, selfPC, continuation in
                    Instruction.BrIfAccOperand(offset: Int32(continuation.offsetFromHead - selfPC.offsetFromHead))
                }
                self.updateInstructionMapping(from: oldPC)
                return
            }
            let oldPC = iseqBuilder.insertingPC
            iseqBuilder.emitWithLabel(Instruction.brIf, frame.continuation) { _, selfPC, continuation in
                let relativeOffset = continuation.offsetFromHead - selfPC.offsetFromHead
                return Instruction.BrIfOperand(
                    condition: LVReg(condition), offset: Int32(relativeOffset)
                )
            }
            self.updateInstructionMapping(from: oldPC)
            return
        }
        preserveOnStack(depth: valueStack.valueHeight - frame.valueStackHeight)

        if let condition {
            // If branch taken, fallthrough to landing pad, copy stack values,
            // clean up exception handlers (if any), then branch to the actual place.
            // If branch not taken, branch to the next of the landing pad.
            //
            // (block (result i32)
            //   (i32.const 42)
            //   (i32.const 24)
            //   (local.get 0)
            //   (br_if 0) ------+
            //   (local.get 1)   |
            // )         <-------+
            //
            // [0x00] (i32.const 42 reg:0)
            // [0x01] (i32.const 24 reg:1)
            // [0x02] (local.get 0 result=reg:2)
            // [0x03] (br_if_z offset=+0x3 cond=reg:2) --+
            // [0x04] (stack.copy reg:1 -> reg:0)        |
            //        (catchHandlersEnd count=N)?        |  // only if handlersToUnwind > 0
            // [0x05] (br offset=+0x2) --------+         |
            // [0x06] (local.get 1 reg:2) <----|---------+
            // [0x07] ...              <-------+
            let onBranchNotTaken = iseqBuilder.allocLabel()
            // NOTE: `preserveOnStack` above may have emitted copies; when it did,
            // `canRewind` refuses and we fall back to the unfused form.
            let makeFused = fuseCompareIntoBranch(fusable, condition: condition)
            let accProducer = makeFused == nil ? accConditionProducer(accCandidate, condition: condition) : nil
            if let accProducer {
                rewindProducerIntoAccumulator(accProducer)
            }
            let conditionCheckPC = iseqBuilder.insertingPC
            if let makeFused {
                iseqBuilder.emitBranchWithLabel(onBranchNotTaken, immediateSlots: makeFused.immediateSlots) { _, conditionCheckAt, continuation in
                    makeFused.make(.ifFalse, Int32(continuation.offsetFromHead - conditionCheckAt.offsetFromHead))
                }
            } else if accProducer != nil {
                iseqBuilder.emitWithLabel(Instruction.brIfNotAcc, onBranchNotTaken) { _, conditionCheckAt, continuation in
                    Instruction.BrIfAccOperand(offset: Int32(continuation.offsetFromHead - conditionCheckAt.offsetFromHead))
                }
            } else {
                iseqBuilder.emitWithLabel(Instruction.brIfNot, onBranchNotTaken) { _, conditionCheckAt, continuation in
                    let relativeOffset = continuation.offsetFromHead - conditionCheckAt.offsetFromHead
                    return Instruction.BrIfOperand(condition: LVReg(condition), offset: Int32(relativeOffset))
                }
            }
            self.updateInstructionMapping(from: conditionCheckPC)
            let landingPadPC = iseqBuilder.insertingPC
            try copyOnBranch(targetFrame: frame)

            // The landing pad only exists to run the copies (and the handler
            // unwind) on the taken path. `frame.copySlotCount != 0` does *not*
            // imply that any copy is emitted: for a `loop (param ...)`
            // back-edge the operand usually already sits in the destination
            // slot, so `copyOnBranch` emits nothing and the pad degenerates
            // into two dispatches for one guest branch.
            //
            // (loop $continue (param i32) (result i32)
            //   (i32.const 1)
            //   (i32.sub)
            //   (local.tee $n)
            //   (local.get $n)
            //   (br_if $continue) ---> back to the loop head
            // )
            //
            // [0x02] (i32.sub reg:4, reg:0 -> local $n)    <-----------+
            // [0x04] (copy local $n -> reg:4)                          |
            // [0x06] (br_if_not cond=local $n, offset=+2) --+          |
            // [0x08] (br offset=-8) ------------------------|----------+
            // [0x0a] ...                        <-----------+
            //
            // Collapse that into a single conditional branch (fused, when
            // the condition came from a comparison) straight to the real
            // destination:
            //
            // [0x02] (i32.sub reg:4, reg:0 -> local $n)    <-----------+
            // [0x04] (copy local $n -> reg:4)                          |
            // [0x06] (br_if cond=local $n, offset=-6) ------------------+
            // [0x08] ...
            //
            // Only the "no copy was emitted" case is collapsed. When copies
            // *were* emitted they cannot be hoisted above the branch: they
            // write the branch target's slots, which are below the current
            // stack top and generally still live on the fall-through path (in
            // the example above reg:0 must keep holding 42 when the branch is
            // not taken). Proving those slots dead needs liveness information
            // this single-pass translator does not have, so the copying case
            // keeps the landing pad.
            let collapseLandingPad =
                handlersToUnwind == 0
                && iseqBuilder.insertingPC.offsetFromHead == landingPadPC.offsetFromHead
                && iseqBuilder.canRewind(to: conditionCheckPC)
            if collapseLandingPad {
                // The conditional branch just emitted is the only user of the
                // landing pad's label, and it is about to be removed.
                iseqBuilder.discardUnpinnedLabel(onBranchNotTaken)
                iseqBuilder.rewind(to: conditionCheckPC)
                self.rewindInstructionMapping(to: conditionCheckPC)
                if let makeFused {
                    iseqBuilder.emitBranchWithLabel(frame.continuation, immediateSlots: makeFused.immediateSlots) { _, selfPC, continuation in
                        makeFused.make(.ifTrue, Int32(continuation.offsetFromHead - selfPC.offsetFromHead))
                    }
                } else if accProducer != nil {
                    iseqBuilder.emitWithLabel(Instruction.brIfAcc, frame.continuation) { _, selfPC, continuation in
                        Instruction.BrIfAccOperand(offset: Int32(continuation.offsetFromHead - selfPC.offsetFromHead))
                    }
                } else {
                    iseqBuilder.emitWithLabel(Instruction.brIf, frame.continuation) { _, selfPC, continuation in
                        let relativeOffset = continuation.offsetFromHead - selfPC.offsetFromHead
                        return Instruction.BrIfOperand(
                            condition: LVReg(condition), offset: Int32(relativeOffset)
                        )
                    }
                }
                self.updateInstructionMapping(from: conditionCheckPC)
            } else {
                if handlersToUnwind > 0 {
                    emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: handlersToUnwind)))
                }
                try emitBranch(Instruction.br, relativeDepth: relativeDepth) { offset, copyCount, popCount in
                    return offset
                }
                try iseqBuilder.pinLabelHere(onBranchNotTaken)
            }
        }
        try popPushValues(frame.copyTypes)
    }

    mutating func visitBrTable(targets: WasmParser.BrTable) throws(WasmKitError) -> Output {
        guard let index = try popVRegOperand(.i32) else { return }

        let defaultFrame = try controlStack.branchTarget(relativeDepth: targets.defaultIndex)

        // If this instruction is unreachable, copyCount might be greater than the actual stack height
        try preserveOnStack(
            depth: min(
                defaultFrame.copyTypes.count,
                valueStack.valueHeight - controlStack.currentFrame().valueStackHeight
            )
        )
        let allLabelIndices = targets.labelIndices + [targets.defaultIndex]
        let tableBuffer = allocator.allocateBrTable(capacity: allLabelIndices.count)
        guard let targetCount = UInt16(exactly: tableBuffer.count) else {
            throw WasmKitError(message: .vectorTooLargeForInterpreter("this `br_table`", count: tableBuffer.count))
        }
        let operand = Instruction.BrTableOperand(
            baseAddress: tableBuffer.baseAddress!,
            count: targetCount, index: index
        )
        let oldPC = iseqBuilder.insertingPC
        iseqBuilder.emit(.brTable(operand))
        self.updateInstructionMapping(from: oldPC)
        let brTableAt = iseqBuilder.insertingPC

        //
        // (block $l1 (result i32)
        //   (i32.const 63)
        //   (block $l2 (result i32)
        //     (i32.const 42)
        //     (i32.const 24)
        //     (local.get 0)
        //     (br_table $l1 $l2) ---+
        //                           |
        //   )               <-------+
        //   (i32.const 36)          |
        // )              <----------+
        //
        //
        //           [0x00] (i32.const 63 reg:0)
        //           [0x01] (i32.const 42 reg:1)
        //           [0x02] (i32.const 24 reg:2)
        //           [0x03] (local.get 0 result=reg:3)
        //           [0x04] (br_table index=reg:3 offsets=[
        //                    +0x01       -----------------+
        //                    +0x03       -----------------|----+
        //                  ])                             |    |
        //           [0x05] (stack.copy reg:2 -> reg:0) <--+    |
        //  +------- [0x06] (br offset=+0x03)                   |
        //  |        [0x07] (stack.copy reg:2 -> reg:1)  <------+
        //  |  +---- [0x08] (br offset=+0x03)
        //  +--|---> [0x09] (i32.const 36 reg:2)
        //     |     [0x0a] (stack.copy reg:2 -> reg:0)
        //     +---> [0x0b] ...
        for (entryIndex, labelIndex) in allLabelIndices.enumerated() {
            let frame = try controlStack.branchTarget(relativeDepth: labelIndex)

            // Check copyTypes consistency
            guard frame.copyTypes.count == defaultFrame.copyTypes.count else {
                throw WasmKitError(
                    message:
                        .expectedSameCopyTypes(
                            frameCopyTypes: frame.copyTypes,
                            defaultFrameCopyTypes: defaultFrame.copyTypes
                        )
                )
            }
            try checkStackTop(frame.copyTypes)

            let handlersToUnwind = controlStack.catchHandlersToUnwind(relativeDepth: labelIndex)

            do {
                let relativeOffset = iseqBuilder.insertingPC.offsetFromHead - brTableAt.offsetFromHead
                tableBuffer[entryIndex] = Instruction.BrTableOperand.Entry(
                    offset: Int32(relativeOffset)
                )
            }
            let emittedCopy = try copyOnBranch(targetFrame: frame)
            if emittedCopy || handlersToUnwind > 0 {
                if handlersToUnwind > 0 {
                    emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: handlersToUnwind)))
                }
                let oldPC = iseqBuilder.insertingPC
                iseqBuilder.emitWithLabel(Instruction.br, frame.continuation) { _, brAt, continuation in
                    let relativeOffset = continuation.offsetFromHead - brAt.offsetFromHead
                    return Int32(relativeOffset)
                }
                self.updateInstructionMapping(from: oldPC)
            } else {
                // Optimization: If no value is copied and no handlers to unwind,
                // we can directly jump to the target
                iseqBuilder.fillBrTableEntry(frame.continuation, table: tableBuffer, index: entryIndex) { _, continuation in
                    return Instruction.BrTableOperand.Entry(offset: Int32(continuation.offsetFromHead - brTableAt.offsetFromHead))
                }
            }
        }
        // Pop branch copy values for type checking
        for type in defaultFrame.copyTypes.reversed() {
            _ = try popOperand(type)
        }
        try markUnreachable()
    }

    mutating func visitReturn() throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        try translateReturn()
        try markUnreachable()
    }

    private mutating func visitCallLike(calleeType: FunctionType) throws(WasmKitError) -> VReg? {
        var hasAllParameters = true
        for parameter in calleeType.parameters.reversed() {
            if try popOnStackOperand(parameter) == nil {
                hasAllParameters = false
            }
        }
        guard hasAllParameters else {
            // The arguments came from an unreachable, polymorphic stack. Nothing
            // needs emitting, but the results still take part in validation.
            for result in calleeType.results {
                _ = valueStack.push(result)
            }
            return nil
        }

        let spAddendSlots =
            stackLayout.stackRegBaseSlotIndex + valueStack.slotHeight
            + FrameHeaderLayout.size(of: calleeType)
        self.maxFrameSlotIndex = max(self.maxFrameSlotIndex, spAddendSlots)

        for result in calleeType.results {
            _ = valueStack.push(result)
        }
        return VReg(slotIndex: spAddendSlots)
    }
    mutating func visitCall(functionIndex: UInt32) throws(WasmKitError) -> Output {
        let calleeType = try self.module.functionType(functionIndex, interner: funcTypeInterner)
        guard let spAddend = try visitCallLike(calleeType: calleeType) else { return }
        guard let callee = self.module.resolveCallee(functionIndex) else {
            // Skip actual code emission if validation-only mode
            return
        }
        if callee.isWasm {
            if module.isSameInstance(callee.wasm.instance) {
                emit(.compilingCall(Instruction.CallOperand(callee: callee, spAddend: spAddend)))
                return
            }
        }
        emit(.call(Instruction.CallOperand(callee: callee, spAddend: spAddend)))
    }

    mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws(WasmKitError) -> Output {
        let addressType = try module.addressType(tableIndex: tableIndex)
        let address = try popVRegOperand(addressType)  // function address
        let calleeType = try self.module.resolveType(typeIndex)
        guard let spAddend = try visitCallLike(calleeType: calleeType) else { return }
        guard let address = address else { return }
        let internType = funcTypeInterner.intern(calleeType)
        let operand = Instruction.CallIndirectOperand(
            tableIndex: tableIndex,
            type: internType,
            index: address,
            spAddend: spAddend
        )
        emit(.callIndirect(operand))
    }

    /// Emit instructions to prepare the frame header for a return call to replace the
    /// current frame header with the callee's frame header layout.
    ///
    /// The frame header should have the callee's frame header layout and parameter
    /// slots are filled with arguments on the caller's stack.
    ///
    /// - Parameters:
    ///   - calleeType: The type of the callee function.
    ///   - stackTopHeightToCopy: The height of the stack top needed to be available at the
    ///     return-call-like instruction point.
    private mutating func prepareFrameHeaderForReturnCall(calleeType: FunctionType, stackTopHeightToCopy: Int) throws(WasmKitError) {
        let calleeFrameHeader = FrameHeaderLayout(type: calleeType)
        if calleeType == self.type {
            // Fast path: If the callee and the caller have the same signature, we can
            // skip reconstructing the frame header and we can just copy the parameters.
        } else {
            // Ensure all parameters are on stack to avoid conflicting with the next resize.
            preserveOnStack(depth: calleeType.parameters.count)
            // Resize the current frame header while moving stack slots after the header
            // to the resized positions
            let newHeaderSize = FrameHeaderLayout.size(of: calleeType)
            let delta = newHeaderSize - FrameHeaderLayout.size(of: type)
            let slotsToCopy =
                FrameHeaderLayout.numberOfSavingSlots + stackLayout.stackRegBaseSlotIndex + stackTopHeightToCopy
            self.maxFrameSlotIndex = max(self.maxFrameSlotIndex, slotsToCopy)
            guard VReg.canRepresent(slotIndex: delta), let sizeToCopy = UInt16(exactly: slotsToCopy) else {
                throw WasmKitError("The frame header of a return_call is too large to encode")
            }
            emit(.resizeFrameHeader(Instruction.ResizeFrameHeaderOperand(delta: VReg(slotIndex: delta), sizeToCopy: sizeToCopy)))
        }
        try copyValuesIntoParamSlots(calleeType.parameters, frameHeader: calleeFrameHeader)
    }

    mutating func visitReturnCall(functionIndex: UInt32) throws(WasmKitError) {
        let calleeType = try self.module.functionType(functionIndex, interner: funcTypeInterner)
        try validator.validateReturnCallLike(calleeType: calleeType, callerType: type)

        guard let callee = self.module.resolveCallee(functionIndex) else {
            // Skip actual code emission if validation-only mode
            return
        }
        // Clean up all exception handlers before the tail call
        let handlersToUnwind = controlStack.catchHandlersToUnwind(
            relativeDepth: UInt32(controlStack.numberOfFrames - 1)
        )
        if handlersToUnwind > 0 {
            emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: handlersToUnwind)))
        }
        try prepareFrameHeaderForReturnCall(calleeType: calleeType, stackTopHeightToCopy: valueStack.slotHeight)
        emit(.returnCall(Instruction.ReturnCallOperand(callee: callee)))
        try markUnreachable()
    }

    mutating func visitReturnCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws(WasmKitError) {
        let stackTopHeightToCopy = valueStack.slotHeight
        let addressType = try module.addressType(tableIndex: tableIndex)
        // Preserve function index slot on stack
        let address = try popOnStackOperand(addressType)  // function address
        guard let address = address else { return }

        let calleeType = try self.module.resolveType(typeIndex)
        let internType = funcTypeInterner.intern(calleeType)

        // Clean up all exception handlers before the tail call
        let handlersToUnwind = controlStack.catchHandlersToUnwind(
            relativeDepth: UInt32(controlStack.numberOfFrames - 1)
        )
        if handlersToUnwind > 0 {
            emit(.catchHandlersEnd(Instruction.CatchHandlersEndOperand(count: handlersToUnwind)))
        }
        try prepareFrameHeaderForReturnCall(
            calleeType: calleeType,
            // Keep the stack space including the function index slot to be
            // accessible at the `return_call_indirect` instruction point.
            stackTopHeightToCopy: stackTopHeightToCopy
        )

        let operand = Instruction.ReturnCallIndirectOperand(
            tableIndex: tableIndex,
            type: internType,
            index: address
        )
        emit(.returnCallIndirect(operand))
        try markUnreachable()
    }

    // MARK: - Exception handling

    mutating func visitThrow(tagIndex: UInt32) throws(WasmKitError) -> Output {
        let tag = try module.tags[validating: Int(tagIndex)]
        let tagType = funcTypeInterner.resolve(tag.type)
        // Pop tag parameter values and ensure they're on the physical stack
        for param in tagType.parameters.reversed() {
            guard (try popOnStackOperand(param)) != nil else { return }
        }
        let payloadBase = valueStack.stackRegBase + VReg(slotIndex: valueStack.slotHeight)
        // Push the parameter values back (they've been popped for on-stack guarantee)
        for param in tagType.parameters {
            _ = valueStack.push(param)
        }
        emit(.throwTag(Instruction.ThrowTagOperand(tagIndex: tagIndex, payloadBase: payloadBase)))
        try markUnreachable()
    }

    mutating func visitThrowRef() throws(WasmKitError) -> Output {
        guard let exnRef = try popVRegOperand(.ref(.init(isNullable: true, heapType: .abstract(.exnRef)))) else { return }
        emit(.throwRef(Instruction.ThrowRefOperand(exnRef: exnRef)))
        try markUnreachable()
    }

    mutating func visitTryTable(blockType: WasmParser.BlockType, tryCatch: WasmParser.TryCatch) throws(WasmKitError) -> Output {
        let blockType = try module.resolveBlockType(blockType)
        let endLabel = iseqBuilder.allocLabel()

        self.preserveOnStack(depth: self.valueStack.valueHeight)
        let stackHeight = try popPushValues(blockType.parameters)

        guard let catchCount = UInt16(exactly: tryCatch.catches.count) else {
            throw WasmKitError(message: .vectorTooLargeForInterpreter("this `try_table`", count: tryCatch.catches.count))
        }

        // Allocate the catch table
        let catchTable = allocator.allocateCatchTable(capacity: tryCatch.catches.count)

        // Emit the catchHandlers instruction first so we know its PC position.
        let operand = Instruction.CatchHandlersOperand(
            baseAddress: UnsafePointer(catchTable.baseAddress!),
            count: catchCount
        )
        emit(.catchHandlers(operand))

        // After emission, insertingPC points past the catchHandlers instruction.
        // This is the reference point for pcOffset values.
        let catchHandlersEndPC = iseqBuilder.insertingPC

        // Process catch clauses BEFORE pushing the try_table frame, because
        // catch clause label depths are relative to the enclosing scope
        // (the try_table's own label is not in scope for catch clauses per spec).
        for (i, clause) in tryCatch.catches.enumerated() {
            let tagIndex: UInt32?
            let labelDepth: UInt32
            let isRef: Bool

            switch clause {
            case .catch(let tIdx, let lIdx):
                tagIndex = tIdx
                labelDepth = lIdx
                isRef = false
            case .catchRef(let tIdx, let lIdx):
                tagIndex = tIdx
                labelDepth = lIdx
                isRef = true
            case .catchAll(let lIdx):
                tagIndex = nil
                labelDepth = lIdx
                isRef = false
            case .catchAllRef(let lIdx):
                tagIndex = nil
                labelDepth = lIdx
                isRef = true
            }

            let targetFrame = try controlStack.branchTarget(relativeDepth: labelDepth)

            // Resolve the tag to get the InternalTag handle
            let tag: InternalTag?
            var catchTypes: [ValueType]
            if let tagIndex {
                tag = try module.tags[validating: Int(tagIndex)]
                let tagType = funcTypeInterner.resolve(tag!.type)
                catchTypes = tagType.parameters
            } else {
                tag = nil
                catchTypes = []
            }
            if isRef {
                catchTypes.append(.ref(.init(isNullable: true, heapType: .abstract(.exnRef))))
            }

            // Validate that the caught value types match the target label's copy types
            guard catchTypes == targetFrame.copyTypes else {
                throw WasmKitError(message: .catchTypeMismatch)
            }

            // The payload register base is where the handler will write values.
            // This is at the target frame's stack base.
            let payloadRegBase = valueStack.stackRegBase + VReg(slotIndex: targetFrame.slotStackHeight)

            // Initialize the entry with a placeholder pcOffset (will be resolved)
            catchTable[i] = CatchTableEntry(
                tag: tag,
                isRef: isRef,
                pcOffset: 0,  // placeholder
                payloadRegBase: payloadRegBase
            )

            // Schedule the pcOffset to be filled when the target label is resolved.
            // The offset is relative to catchHandlersEndPC.
            iseqBuilder.fillCatchTableEntry(
                targetFrame.continuation, table: catchTable, index: i,
                catchHandlersPC: catchHandlersEndPC
            )
        }

        // Push the try_table frame AFTER processing catch clauses.
        // The try_table's own label is only in scope for the body instructions.
        controlStack.pushFrame(
            ControlStack.ControlFrame(
                blockType: blockType,
                valueStackHeight: stackHeight.valueHeight,
                slotStackHeight: stackHeight.slotHeight,
                continuation: endLabel,
                kind: .tryTable(catchCount: catchCount)
            )
        )
    }

    mutating func visitDrop() throws(WasmKitError) -> Output {
        refundFuelForFreeOperator()
        _ = try popAnyOperand()
        iseqBuilder.resetLastEmission()
    }
    mutating func visitSelect() throws(WasmKitError) -> Output {
        // Captured before `popVRegOperand`, which resets the last emission.
        let fusable = iseqBuilder.fusableEmission
        let accCandidate = iseqBuilder.accProducer
        let condition = try popVRegOperand(.i32)
        let (value1Type, value1) = try popAnyOperand()
        let (value2Type, value2) = try popAnyOperand()
        switch (value1Type, value2Type) {
        case (.some(.ref(_)), _), (_, .some(.ref(_))):
            throw WasmKitError(message: .cannotSelectOnReferenceTypes)
        case (.some(let type1), .some(let type2)):
            guard type1 == type2 else {
                throw WasmKitError(message: .typeMismatchOnSelect(expected: type1, actual: type2))
            }
        case (.unknown, _), (_, .unknown):
            break
        }
        let result = valueStack.push(value1Type)
        if let condition = condition, let value1 = value1, let value2 = value2 {
            let onTrue = ensureOnVReg(value2)
            let onFalse = ensureOnVReg(value1)
            emitSelect(
                result: result, condition: condition, onTrue: onTrue, onFalse: onFalse,
                isV128: value1Type.concreteType == .v128, fusable: fusable, accCandidate: accCandidate)
        }
    }
    mutating func visitTypedSelect(type: WasmTypes.ValueType) throws(WasmKitError) -> Output {
        let type = try module.typeCanonicalizer.canonicalize(type)
        // Captured before `popVRegOperand`, which resets the last emission.
        let fusable = iseqBuilder.fusableEmission
        let accCandidate = iseqBuilder.accProducer
        let condition = try popVRegOperand(.i32)
        let (value1Type, value1) = try popAnyOperand()
        let (value2Type, value2) = try popAnyOperand()
        // Both operands must have the annotated type. Without this check the
        // result was pushed with the *operand's* type while the copy width came
        // from the *annotation*, so a `(select (result i64))` over two `v128`
        // operands copied only 8 of the 16 bytes and left the rest of the
        // result slot holding whatever the stack happened to contain.
        for operandType in [value1Type, value2Type] {
            switch operandType {
            case .unknown:
                // Polymorphic stack after `unreachable`; nothing to check.
                break
            case .some(let operandType):
                guard operandType == type else {
                    throw WasmKitError(message: .typeMismatchOnSelect(expected: type, actual: operandType))
                }
            }
        }
        let result = valueStack.push(type)
        if let condition = condition, let value1 = value1, let value2 = value2 {
            let onTrue = ensureOnVReg(value2)
            let onFalse = ensureOnVReg(value1)
            emitSelect(
                result: result, condition: condition, onTrue: onTrue, onFalse: onFalse,
                isV128: type == .v128, fusable: fusable, accCandidate: accCandidate)
        }
    }

    /// Emits `select` so that a following `local.set` can relink its result,
    /// taking the condition from the accumulator when the instruction right
    /// before produced it.
    private mutating func emitSelect(
        result: VReg, condition: VReg, onTrue: VReg, onFalse: VReg,
        isV128: Bool, fusable: FusableEmission?, accCandidate: AccProducer?
    ) {
        if isV128 {
            emit(.select(.init(result: result, condition: condition, onTrue: onTrue, onFalse: onFalse)))
            emit(.select(.init(result: result.nextSlot, condition: condition, onTrue: onTrue.nextSlot, onFalse: onFalse.nextSlot)))
            return
        }
        if let makeFused = fuseCompareIntoSelect(fusable, condition: condition, onTrue: onTrue, onFalse: onFalse) {
            emit(makeFused(result), resultRelink: { newResult in makeFused(newResult) })
            return
        }
        if let producer = accConditionProducer(accCandidate, condition: condition), onTrue != condition, onFalse != condition {
            rewindProducerIntoAccumulator(producer)
            emit(
                .selectAcc(.init(result: result, onTrue: onTrue, onFalse: onFalse)),
                resultRelink: { newResult in .selectAcc(.init(result: newResult, onTrue: onTrue, onFalse: onFalse)) }
            )
            return
        }
        emit(
            .select(.init(result: result, condition: condition, onTrue: onTrue, onFalse: onFalse)),
            resultRelink: { newResult in
                .select(.init(result: newResult, condition: condition, onTrue: onTrue, onFalse: onFalse))
            }
        )
    }
    mutating func visitLocalGet(localIndex: UInt32) throws(WasmKitError) -> Output {
        iseqBuilder.dropResultRelink()
        try valueStack.pushLocal(localIndex, locals: &locals)
    }
    /// Shared lowering of `local.set` and `local.tee`. `local.tee` differs
    /// only in that its caller re-pushes the local afterwards.
    mutating func visitLocalSetOrTee(localIndex: UInt32) throws(WasmKitError) {
        preserveLocalsOnStack(localIndex)
        let type = try locals.type(of: localIndex)
        let result = localReg(localIndex)

        guard try checkBeforePop(typeHint: type) else { return }
        let op = try valueStack.pop(type)

        if case .const(let value, _) = op {
            // Optimize (local.set $x (i32.const $c)) to reg:$x = 42 rather than through const slot
            let is32Bit = type == .i32 || type == .f32
            if is32Bit {
                emit(.const32(Instruction.Const32Operand(value: UInt32(value.storage), result: LVReg(result))))
            } else {
                emit(.const64(Instruction.Const64Operand(value: value, result: LLVReg(result))))
            }
            return
        }

        let value = ensureOnVReg(op)
        guard try controlStack.currentFrame().reachable else { return }
        // Relink the producing instruction to write the local's slot directly,
        // dropping the copy that would otherwise move the value there.
        //
        // `local.tee` is included: the value it leaves on the stack is pushed
        // back as `.local(localIndex)` by `visitLocalTee`, i.e. it *already*
        // aliases the local's slot whether the value got there by a copy or by
        // the producer writing it. A later write to the same local before the
        // tee'd value is consumed is handled by the existing
        // `preserveLocalsOnStack` mechanism, exactly as it is for `local.get`.
        //
        // `v128` is included as well: a v128 producer writes both slots of its
        // result from one base register (`sp.storeV128(_:at:)`), and a v128
        // local owns two consecutive slots, so redirecting the base register is
        // all that is needed -- there is nothing per-slot to relink.
        //
        // Note that when `preserveLocalsOnStack(localIndex)` above emitted
        // copies, the relink is refused (those copies are the last emission,
        // and they carry no `resultRelink`). That is load-bearing rather than
        // accidental: those copies read the local's *old* value, and relinking
        // would move the write of its new value before them.
        if iseqBuilder.relinkLastInstructionResult(result) {
            // Good news, copyStack is optimized out :)
            return
        }
        // `t = <op>; a = copy b; x = copy t` keeps `t` in the accumulator
        // across the copy and writes it to `x` with the copy.
        if case .vreg = op, type == .i32 || type == .i64,
            let across = iseqBuilder.accProducerAcrossCopy(of: value)
        {
            rewindProducerIntoAccumulator(across.producer)
            emit(.copyStackAccToSlot(Instruction.CopyStackAccToSlotOperand(source: across.source, dest: across.dest, result: result)))
            return
        }
        emitCopyValueSlots(type, from: value, to: result)
    }
    mutating func visitLocalSet(localIndex: UInt32) throws(WasmKitError) -> Output {
        try visitLocalSetOrTee(localIndex: localIndex)
    }
    mutating func visitLocalTee(localIndex: UInt32) throws(WasmKitError) -> Output {
        try visitLocalSetOrTee(localIndex: localIndex)
        _ = try valueStack.pushLocal(localIndex, locals: &locals)
    }
    mutating func visitGlobalGet(globalIndex: UInt32) throws(WasmKitError) -> Output {
        let type = try module.globalType(globalIndex)
        let result = valueStack.push(type)
        guard let global = module.resolveGlobal(globalIndex) else {
            // Skip actual code emission if validation-only mode
            return
        }
        let operand = Instruction.GlobalAndVRegOperand(reg: LLVReg(result), global: global)
        // The shape of a global never changes, so pick the handler here instead
        // of testing the value's tag on every access.
        switch type {
        case .v128:
            emit(.globalGetV128(operand))
        case .i32, .i64:
            emit(.globalGet(operand))
            iseqBuilder.recordAcc(AccRecords(producer: .globalGet(type: type, global: global, result: result)))
        default:
            emit(.globalGet(operand))
        }
    }
    mutating func visitGlobalSet(globalIndex: UInt32) throws(WasmKitError) -> Output {
        let type = try module.globalType(globalIndex)
        guard let value = try popVRegOperand(type) else { return }
        guard let global = module.resolveGlobal(globalIndex) else {
            // Skip actual code emission if validation-only mode
            return
        }
        try validator.validateGlobalSet(global.globalType)
        let operand = Instruction.GlobalAndVRegOperand(reg: LLVReg(value), global: global)
        emit(type == .v128 ? .globalSetV128(operand) : .globalSet(operand))
    }

    private mutating func pushEmit(
        _ type: ValueType,
        _ instruction: @escaping (VReg) -> Instruction
    ) {
        let register = valueStack.push(type)
        emit(
            instruction(register),
            resultRelink: { newResult in
                instruction(newResult)
            })
    }
    private mutating func popPushEmit(
        _ pop: ValueType,
        _ push: ValueType,
        _ instruction: @escaping (_ popped: VReg, _ result: VReg) -> Instruction
    ) throws(WasmKitError) {
        let value = try popVRegOperand(pop)
        let result = valueStack.push(push)
        if let value = value {
            emit(
                instruction(value, result),
                resultRelink: { newResult in
                    instruction(value, newResult)
                })
        }
    }

    private mutating func pop3Emit(
        _ pops: (ValueType, ValueType, ValueType),
        _ instruction: (
            _ popped: (VReg, VReg, VReg),
            inout ValueStack
        ) -> Instruction
    ) throws(WasmKitError) {
        guard let pop1 = try popVRegOperand(pops.0),
            let pop2 = try popVRegOperand(pops.1),
            let pop3 = try popVRegOperand(pops.2)
        else { return }
        emit(instruction((pop1, pop2, pop3), &valueStack))
    }

    private mutating func pop2Emit(
        _ pops: (ValueType, ValueType),
        _ instruction: (
            _ popped: (VReg, VReg),
            inout ValueStack
        ) -> Instruction
    ) throws(WasmKitError) {
        guard let pop1 = try popVRegOperand(pops.0),
            let pop2 = try popVRegOperand(pops.1)
        else { return }
        emit(instruction((pop1, pop2), &valueStack))
    }

    private mutating func pop2PushEmit(
        _ pops: (ValueType, ValueType),
        _ push: ValueType,
        _ instruction:
            @escaping (
                _ popped: (VReg, VReg),
                _ result: VReg
            ) -> Instruction
    ) throws(WasmKitError) {
        guard let pop1 = try popVRegOperand(pops.0),
            let pop2 = try popVRegOperand(pops.1)
        else { return }
        let result = valueStack.push(push)
        emit(
            instruction((pop1, pop2), result),
            resultRelink: { result in
                instruction((pop1, pop2), result)
            })
    }

    private mutating func pop3PushEmit(
        _ pops: (ValueType, ValueType, ValueType),
        _ push: ValueType,
        _ instruction: @escaping (_ popped: (VReg, VReg, VReg), _ result: VReg) -> Instruction
    ) throws(WasmKitError) {
        guard let pop1 = try popVRegOperand(pops.0),
            let pop2 = try popVRegOperand(pops.1),
            let pop3 = try popVRegOperand(pops.2)
        else { return }
        let result = valueStack.push(push)
        emit(
            instruction((pop1, pop2, pop3), result),
            resultRelink: { result in
                instruction((pop1, pop2, pop3), result)
            })
    }

    private mutating func visitLoad(
        _ memarg: MemArg,
        _ type: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.LoadOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        try popPushEmit(.address(isMemory64: isMemory64), type) { value, result in
            let loadOperand = Instruction.LoadOperand(
                offset: memarg.offset,
                pointer: value,
                result: result
            )
            return instruction(loadOperand)
        }
    }
    /// A load on a 32-bit memory, which can take its guest address from the
    /// accumulator and hand its result to the next instruction there.
    private mutating func visitAccLoad(
        _ load: WasmParser.Instruction.Load, _ forms: AccLoadForms, memarg: MemArg, offset: UInt32
    ) throws(WasmKitError) {
        try validator.validateMemArg(memarg, naturalAlignment: load.naturalAlignment)
        // Captured before `popVRegOperand`, which resets the last emission.
        let accCandidate = iseqBuilder.accProducer
        let pointer = try popVRegOperand(.address(isMemory64: false))
        let result = valueStack.push(load.type)
        guard let pointer else { return }
        if let accCandidate, accCandidate.form.type == .i32, accCandidate.form.result == pointer,
            accCandidate.producing(into: .integer) != nil, iseqBuilder.canRewind(to: accCandidate)
        {
            rewindProducerIntoAccumulator(accCandidate)
            emit(
                forms.fromAcc(Instruction.AccMemoryResultOperand(result: result, offset: offset)),
                resultRelink: { newResult in
                    forms.fromAcc(Instruction.AccMemoryResultOperand(result: newResult, offset: offset))
                }
            )
            iseqBuilder.recordAcc(AccRecords(producer: .loadFromAcc(load, offset: offset, result: result)))
            return
        }
        // The address was just copied: read the copy's source and perform the
        // copy in the load.
        if !module.isDebuggable,
            let copy = iseqBuilder.copy(into: pointer), let withCopy = Self.loadWithCopyInstruction(load)
        {
            iseqBuilder.rewind(to: copy.position)
            self.rewindInstructionMapping(to: copy.position)
            let make = { (result: VReg) in
                withCopy(Instruction.LoadWithCopyOperand(pointer: copy.source, result: result, offset: offset, copyDest: pointer))
            }
            emit(make(result), resultRelink: { newResult in make(newResult) })
            return
        }
        emit(
            forms.plain(Instruction.LoadOperand(offset: UInt64(offset), pointer: pointer, result: result)),
            resultRelink: { newResult in
                forms.plain(Instruction.LoadOperand(offset: UInt64(offset), pointer: pointer, result: newResult))
            }
        )
        iseqBuilder.recordAcc(AccRecords(producer: .load(load, pointer: pointer, offset: offset, result: result)))
    }

    /// A store on a 32-bit memory, which can take its value or its guest
    /// address from the accumulator.
    private mutating func visitAccStore(
        _ store: WasmParser.Instruction.Store, _ forms: AccStoreForms, memarg: MemArg, offset: UInt32
    ) throws(WasmKitError) {
        try validator.validateMemArg(memarg, naturalAlignment: store.naturalAlignment)
        // Captured before `popVRegOperand`, which resets the last emission.
        let accCandidate = iseqBuilder.accProducer
        let value = try popVRegOperand(store.type)
        let pointer = try popVRegOperand(.address(isMemory64: false))
        guard let value, let pointer else { return }
        if let accCandidate, iseqBuilder.canRewind(to: accCandidate) {
            let accResult = accCandidate.form.result
            if accResult == value, value != pointer, accCandidate.form.type == store.type {
                // A raw copy through `ireg` serves any producer that has an
                // integer form, `f64.load` included; `freg` serves float
                // arithmetic.
                if accCandidate.producing(into: .integer) != nil {
                    rewindProducerIntoAccumulator(accCandidate)
                    emit(forms.fromAcc(Instruction.AccMemoryPointerOperand(pointer: pointer, offset: offset)))
                    return
                }
                if store == .f64Store, accCandidate.producing(into: .float) != nil {
                    rewindProducerIntoAccumulator(accCandidate, .float)
                    emit(.f64StoreFromFAcc(Instruction.AccMemoryPointerOperand(pointer: pointer, offset: offset)))
                    return
                }
            }
            if accResult == pointer, pointer != value, accCandidate.form.type == .i32,
                accCandidate.producing(into: .integer) != nil
            {
                rewindProducerIntoAccumulator(accCandidate)
                emit(forms.addrFromAcc(Instruction.AccMemoryValueOperand(value: value, offset: offset)))
                return
            }
        }
        emit(
            forms.plain(Instruction.StoreOperand(offset: UInt64(offset), pointer: pointer, value: value)))
    }

    private mutating func visitStore(
        _ memarg: MemArg,
        _ type: ValueType,
        _ naturalAlignment: Int,
        _ instruction: (Instruction.StoreOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let value = try popVRegOperand(type)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        if let value = value, let pointer = pointer {
            let storeOperand = Instruction.StoreOperand(
                offset: memarg.offset,
                pointer: pointer,
                value: value
            )
            emit(instruction(storeOperand))
        }
    }

    mutating func visitLoad(_ load: WasmParser.Instruction.Load, memarg: MemArg) throws(WasmKitError) {
        if let forms = Self.accLoadForms(load), try !module.isMemory64(memoryIndex: 0),
            let offset = UInt32(exactly: memarg.offset)
        {
            return try visitAccLoad(load, forms, memarg: memarg, offset: offset)
        }
        let instruction: (Instruction.LoadOperand) -> Instruction
        switch load {
        case .i32Load: instruction = Instruction.i32Load
        case .i64Load: instruction = Instruction.i64Load
        case .f32Load: instruction = Instruction.f32Load
        case .f64Load: instruction = Instruction.f64Load
        case .v128Load, .v128Load8X8S, .v128Load8X8U, .v128Load16X4S, .v128Load16X4U,
            .v128Load32X2S, .v128Load32X2U, .v128Load8Splat, .v128Load16Splat, .v128Load32Splat,
            .v128Load64Splat, .v128Load32Zero, .v128Load64Zero:
            let isMemory64 = try module.isMemory64(memoryIndex: 0)
            try validator.validateMemArg(memarg, naturalAlignment: load.naturalAlignment)
            guard let opcode = SIMDOpcode.fromLoad(load) else { preconditionFailure("missing SIMDOpcode mapping: \(load)") }
            try popPushEmit(.address(isMemory64: isMemory64), .v128) { pointer, result in
                .simd(
                    Instruction.SimdOperand(
                        opcode: opcode.rawValue,
                        lane: 0,
                        reserved: 0,
                        offset: memarg.offset,
                        input0: pointer,
                        input1: .zero,
                        input2: .zero,
                        result: result
                    ))
            }
            return
        case .i32Load8S: instruction = Instruction.i32Load8S
        case .i32Load8U: instruction = Instruction.i32Load8U
        case .i32Load16S: instruction = Instruction.i32Load16S
        case .i32Load16U: instruction = Instruction.i32Load16U
        case .i64Load8S: instruction = Instruction.i64Load8S
        case .i64Load8U: instruction = Instruction.i64Load8U
        case .i64Load16S: instruction = Instruction.i64Load16S
        case .i64Load16U: instruction = Instruction.i64Load16U
        case .i64Load32S: instruction = Instruction.i64Load32S
        case .i64Load32U: instruction = Instruction.i64Load32U
        case .i32AtomicLoad: instruction = Instruction.i32AtomicLoad
        case .i64AtomicLoad: instruction = Instruction.i64AtomicLoad
        case .i32AtomicLoad8U: instruction = Instruction.i32AtomicLoad8U
        case .i32AtomicLoad16U: instruction = Instruction.i32AtomicLoad16U
        case .i64AtomicLoad8U: instruction = Instruction.i64AtomicLoad8U
        case .i64AtomicLoad16U: instruction = Instruction.i64AtomicLoad16U
        case .i64AtomicLoad32U: instruction = Instruction.i64AtomicLoad32U

        }
        try visitLoad(memarg, load.type, load.naturalAlignment, instruction)
    }

    mutating func visitStore(_ store: WasmParser.Instruction.Store, memarg: MemArg) throws(WasmKitError) {
        if let forms = Self.accStoreForms(store), try !module.isMemory64(memoryIndex: 0),
            let offset = UInt32(exactly: memarg.offset)
        {
            return try visitAccStore(store, forms, memarg: memarg, offset: offset)
        }
        let instruction: (Instruction.StoreOperand) -> Instruction
        switch store {
        case .i32Store: instruction = Instruction.i32Store
        case .i64Store: instruction = Instruction.i64Store
        case .f32Store: instruction = Instruction.f32Store
        case .f64Store: instruction = Instruction.f64Store
        case .v128Store:
            let isMemory64 = try module.isMemory64(memoryIndex: 0)
            try validator.validateMemArg(memarg, naturalAlignment: store.naturalAlignment)
            guard let opcode = SIMDOpcode.fromStore(store) else { preconditionFailure("missing SIMDOpcode mapping: \(store)") }
            let value = try popVRegOperand(.v128)
            let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
            if let value = value, let pointer = pointer {
                emit(
                    .simd(
                        Instruction.SimdOperand(
                            opcode: opcode.rawValue,
                            lane: 0,
                            reserved: 0,
                            offset: memarg.offset,
                            input0: pointer,
                            input1: value,
                            input2: .zero,
                            result: .zero
                        )))
            }
            return
        case .i32Store8: instruction = Instruction.i32Store8
        case .i32Store16: instruction = Instruction.i32Store16
        case .i64Store8: instruction = Instruction.i64Store8
        case .i64Store16: instruction = Instruction.i64Store16
        case .i64Store32: instruction = Instruction.i64Store32
        case .i32AtomicStore: instruction = Instruction.i32AtomicStore
        case .i64AtomicStore: instruction = Instruction.i64AtomicStore
        case .i32AtomicStore8: instruction = Instruction.i32AtomicStore8
        case .i32AtomicStore16: instruction = Instruction.i32AtomicStore16
        case .i64AtomicStore8: instruction = Instruction.i64AtomicStore8
        case .i64AtomicStore16: instruction = Instruction.i64AtomicStore16
        case .i64AtomicStore32: instruction = Instruction.i64AtomicStore32
        }
        try visitStore(memarg, store.type, store.naturalAlignment, instruction)
    }

    mutating func visitV128Const(value: V128) throws(WasmKitError) {
        let storage = V128Storage(value)
        pushEmit(.v128) { result in
            .v128Const(.init(lo: storage.lo, hi: storage.hi, result: result))
        }
    }

    mutating func visitI8x16Shuffle(lanes: V128ShuffleMask) throws(WasmKitError) {
        for lane in lanes.lanes where lane >= 32 {
            throw WasmKitError(message: .invalidLaneIndex(lane: lane, laneCount: 32))
        }
        try pop2PushEmit((.v128, .v128), .v128) { popped, result in
            let rhs = popped.0
            let lhs = popped.1
            let ls = lanes.lanes
            precondition(ls.count == 16)
            return .i8x16Shuffle(
                .init(
                    lane0: ls[0], lane1: ls[1], lane2: ls[2], lane3: ls[3],
                    lane4: ls[4], lane5: ls[5], lane6: ls[6], lane7: ls[7],
                    lane8: ls[8], lane9: ls[9], lane10: ls[10], lane11: ls[11],
                    lane12: ls[12], lane13: ls[13], lane14: ls[14], lane15: ls[15],
                    lhs: lhs, rhs: rhs, result: result
                ))
        }
    }

    mutating func visitSimd(_ simd: WasmParser.Instruction.Simd) throws(WasmKitError) {
        guard let opcode = SIMDOpcode.fromSimd(simd) else { preconditionFailure("missing SIMDOpcode mapping: \(simd)") }
        func emitUnaryV128() throws(WasmKitError) {
            try popPushEmit(.v128, .v128) { v0, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: v0, input1: .zero, input2: .zero, result: result))
            }
        }
        func emitBinaryV128() throws(WasmKitError) {
            try pop2PushEmit((.v128, .v128), .v128) { popped, result in
                let rhs = popped.0
                let lhs = popped.1
                return .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: lhs, input1: rhs, input2: .zero, result: result))
            }
        }
        func emitTernaryV128() throws(WasmKitError) {
            try pop3PushEmit((.v128, .v128, .v128), .v128) { popped, result in
                let mask = popped.0
                let b = popped.1
                let a = popped.2
                return .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: a, input1: b, input2: mask, result: result))
            }
        }
        func emitUnaryI32() throws(WasmKitError) {
            try popPushEmit(.v128, .i32) { v0, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: v0, input1: .zero, input2: .zero, result: result))
            }
        }
        func emitShift() throws(WasmKitError) {
            try pop2PushEmit((.i32, .v128), .v128) { popped, result in
                let shift = popped.0
                let vec = popped.1
                return .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: vec, input1: shift, input2: .zero, result: result))
            }
        }

        switch simd {
        case .i8x16Splat, .i16x8Splat, .i32x4Splat:
            try popPushEmit(.i32, .v128) { scalar, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: scalar, input1: .zero, input2: .zero, result: result))
            }
        case .i64x2Splat:
            try popPushEmit(.i64, .v128) { scalar, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: scalar, input1: .zero, input2: .zero, result: result))
            }
        case .f32x4Splat:
            try popPushEmit(.f32, .v128) { scalar, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: scalar, input1: .zero, input2: .zero, result: result))
            }
        case .f64x2Splat:
            try popPushEmit(.f64, .v128) { scalar, result in
                .simd(.init(opcode: opcode.rawValue, lane: 0, reserved: 0, offset: 0, input0: scalar, input1: .zero, input2: .zero, result: result))
            }

        case .v128Bitselect:
            try emitTernaryV128()

        case .v128AnyTrue, .i8x16AllTrue, .i8x16Bitmask, .i16x8AllTrue, .i16x8Bitmask, .i32x4AllTrue, .i32x4Bitmask, .i64x2AllTrue, .i64x2Bitmask:
            try emitUnaryI32()

        case .i8x16Shl, .i8x16ShrS, .i8x16ShrU,
            .i16x8Shl, .i16x8ShrS, .i16x8ShrU,
            .i32x4Shl, .i32x4ShrS, .i32x4ShrU,
            .i64x2Shl, .i64x2ShrS, .i64x2ShrU:
            try emitShift()

        case .v128Not,
            .i8x16Abs, .i8x16Neg,
            .i16x8Abs, .i16x8Neg,
            .i32x4Abs, .i32x4Neg,
            .i64x2Abs, .i64x2Neg,
            .f32x4Ceil, .f32x4Floor, .f32x4Trunc, .f32x4Nearest,
            .f64x2Ceil, .f64x2Floor, .f64x2Trunc, .f64x2Nearest,
            .f32x4Abs, .f32x4Neg, .f32x4Sqrt,
            .f64x2Abs, .f64x2Neg, .f64x2Sqrt,
            .i32x4TruncSatF32X4S, .i32x4TruncSatF32X4U,
            .f32x4ConvertI32X4S, .f32x4ConvertI32X4U,
            .f64x2ConvertLowI32X4S, .f64x2ConvertLowI32X4U,
            .i32x4TruncSatF64X2SZero, .i32x4TruncSatF64X2UZero,
            .f32x4DemoteF64X2Zero, .f64x2PromoteLowF32X4,
            .i8x16Popcnt,
            .i16x8ExtaddPairwiseI8X16S, .i16x8ExtaddPairwiseI8X16U,
            .i32x4ExtaddPairwiseI16X8S, .i32x4ExtaddPairwiseI16X8U,
            .i16x8ExtendLowI8X16S, .i16x8ExtendHighI8X16S, .i16x8ExtendLowI8X16U, .i16x8ExtendHighI8X16U,
            .i32x4ExtendLowI16X8S, .i32x4ExtendHighI16X8S, .i32x4ExtendLowI16X8U, .i32x4ExtendHighI16X8U,
            .i64x2ExtendLowI32X4S, .i64x2ExtendHighI32X4S, .i64x2ExtendLowI32X4U, .i64x2ExtendHighI32X4U:
            try emitUnaryV128()

        case .v128And, .v128Andnot, .v128Or, .v128Xor,
            .i8x16Swizzle,
            .i8x16Eq, .i8x16Ne, .i8x16LtS, .i8x16LtU, .i8x16GtS, .i8x16GtU, .i8x16LeS, .i8x16LeU, .i8x16GeS, .i8x16GeU,
            .i16x8Eq, .i16x8Ne, .i16x8LtS, .i16x8LtU, .i16x8GtS, .i16x8GtU, .i16x8LeS, .i16x8LeU, .i16x8GeS, .i16x8GeU,
            .i32x4Eq, .i32x4Ne, .i32x4LtS, .i32x4LtU, .i32x4GtS, .i32x4GtU, .i32x4LeS, .i32x4LeU, .i32x4GeS, .i32x4GeU,
            .i64x2Eq, .i64x2Ne, .i64x2LtS, .i64x2GtS, .i64x2LeS, .i64x2GeS,
            .f32x4Eq, .f32x4Ne, .f32x4Lt, .f32x4Gt, .f32x4Le, .f32x4Ge,
            .f64x2Eq, .f64x2Ne, .f64x2Lt, .f64x2Gt, .f64x2Le, .f64x2Ge,
            .i8x16NarrowI16X8S, .i8x16NarrowI16X8U,
            .i16x8NarrowI32X4S, .i16x8NarrowI32X4U,
            .i8x16Add, .i8x16AddSatS, .i8x16AddSatU, .i8x16Sub, .i8x16SubSatS, .i8x16SubSatU, .i8x16MinS, .i8x16MinU, .i8x16MaxS, .i8x16MaxU, .i8x16AvgrU,
            .i16x8Add, .i16x8AddSatS, .i16x8AddSatU, .i16x8Sub, .i16x8SubSatS, .i16x8SubSatU, .i16x8Mul, .i16x8MinS, .i16x8MinU, .i16x8MaxS, .i16x8MaxU, .i16x8AvgrU,
            .i32x4Add, .i32x4Sub, .i32x4Mul, .i32x4MinS, .i32x4MinU, .i32x4MaxS, .i32x4MaxU,
            .i64x2Add, .i64x2Sub, .i64x2Mul,
            .f32x4Add, .f32x4Sub, .f32x4Mul, .f32x4Div, .f32x4Min, .f32x4Max, .f32x4Pmin, .f32x4Pmax,
            .f64x2Add, .f64x2Sub, .f64x2Mul, .f64x2Div, .f64x2Min, .f64x2Max, .f64x2Pmin, .f64x2Pmax,
            .i32x4DotI16X8S,
            .i16x8ExtmulLowI8X16S, .i16x8ExtmulHighI8X16S, .i16x8ExtmulLowI8X16U, .i16x8ExtmulHighI8X16U,
            .i32x4ExtmulLowI16X8S, .i32x4ExtmulHighI16X8S, .i32x4ExtmulLowI16X8U, .i32x4ExtmulHighI16X8U,
            .i64x2ExtmulLowI32X4S, .i64x2ExtmulHighI32X4S, .i64x2ExtmulLowI32X4U, .i64x2ExtmulHighI32X4U,
            .i16x8Q15MulrSatS:
            try emitBinaryV128()

        case .i32x4RelaxedTruncF32X4S, .i32x4RelaxedTruncF32X4U,
            .i32x4RelaxedTruncF64X2SZero, .i32x4RelaxedTruncF64X2UZero:
            try emitUnaryV128()
        case .i8x16RelaxedSwizzle,
            .f32x4RelaxedMin, .f32x4RelaxedMax, .f64x2RelaxedMin, .f64x2RelaxedMax,
            .i16x8RelaxedQ15MulrS, .i16x8RelaxedDotI8X16I7X16S:
            try emitBinaryV128()
        case .i8x16RelaxedLaneselect, .i16x8RelaxedLaneselect, .i32x4RelaxedLaneselect, .i64x2RelaxedLaneselect,
            .f32x4RelaxedMadd, .f32x4RelaxedNmadd, .f64x2RelaxedMadd, .f64x2RelaxedNmadd,
            .i32x4RelaxedDotI8X16I7X16AddS:
            try emitTernaryV128()
        }
    }

    mutating func visitSimdLane(_ simdLane: WasmParser.Instruction.SimdLane, lane: UInt8) throws(WasmKitError) {
        guard let opcode = SIMDOpcode.fromSimdLane(simdLane) else { preconditionFailure("missing SIMDOpcode mapping: \(simdLane)") }
        let laneCount: UInt8
        switch simdLane {
        case .i8x16ExtractLaneS, .i8x16ExtractLaneU, .i8x16ReplaceLane: laneCount = 16
        case .i16x8ExtractLaneS, .i16x8ExtractLaneU, .i16x8ReplaceLane: laneCount = 8
        case .i32x4ExtractLane, .i32x4ReplaceLane, .f32x4ExtractLane, .f32x4ReplaceLane: laneCount = 4
        case .i64x2ExtractLane, .i64x2ReplaceLane, .f64x2ExtractLane, .f64x2ReplaceLane: laneCount = 2
        }
        if lane >= laneCount {
            throw WasmKitError(message: .invalidLaneIndex(lane: lane, laneCount: laneCount))
        }
        switch simdLane {
        case .i8x16ExtractLaneS, .i8x16ExtractLaneU, .i16x8ExtractLaneS, .i16x8ExtractLaneU, .i32x4ExtractLane:
            try popPushEmit(.v128, .i32) { vec, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: vec, input1: .zero, input2: .zero, result: result))
            }
        case .i64x2ExtractLane:
            try popPushEmit(.v128, .i64) { vec, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: vec, input1: .zero, input2: .zero, result: result))
            }
        case .f32x4ExtractLane:
            try popPushEmit(.v128, .f32) { vec, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: vec, input1: .zero, input2: .zero, result: result))
            }
        case .f64x2ExtractLane:
            try popPushEmit(.v128, .f64) { vec, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: vec, input1: .zero, input2: .zero, result: result))
            }
        case .i8x16ReplaceLane:
            try pop2PushEmit((.i32, .v128), .v128) { popped, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: popped.1, input1: popped.0, input2: .zero, result: result))
            }
        case .i16x8ReplaceLane, .i32x4ReplaceLane:
            try pop2PushEmit((.i32, .v128), .v128) { popped, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: popped.1, input1: popped.0, input2: .zero, result: result))
            }
        case .i64x2ReplaceLane:
            try pop2PushEmit((.i64, .v128), .v128) { popped, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: popped.1, input1: popped.0, input2: .zero, result: result))
            }
        case .f32x4ReplaceLane:
            try pop2PushEmit((.f32, .v128), .v128) { popped, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: popped.1, input1: popped.0, input2: .zero, result: result))
            }
        case .f64x2ReplaceLane:
            try pop2PushEmit((.f64, .v128), .v128) { popped, result in
                .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: 0, input0: popped.1, input1: popped.0, input2: .zero, result: result))
            }
        }
    }

    mutating func visitSimdMemLane(_ simdMemLane: WasmParser.Instruction.SimdMemLane, memarg: MemArg, lane: UInt8) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        guard let opcode = SIMDOpcode.fromSimdMemLane(simdMemLane) else { preconditionFailure("missing SIMDOpcode mapping: \(simdMemLane)") }
        let naturalAlignment: Int
        let laneCount: UInt8
        switch simdMemLane {
        case .v128Load8Lane, .v128Store8Lane: (naturalAlignment, laneCount) = (0, 16)
        case .v128Load16Lane, .v128Store16Lane: (naturalAlignment, laneCount) = (1, 8)
        case .v128Load32Lane, .v128Store32Lane: (naturalAlignment, laneCount) = (2, 4)
        case .v128Load64Lane, .v128Store64Lane: (naturalAlignment, laneCount) = (3, 2)
        }
        if lane >= laneCount {
            throw WasmKitError(message: .invalidLaneIndex(lane: lane, laneCount: laneCount))
        }
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)

        switch simdMemLane {
        case .v128Load8Lane, .v128Load16Lane, .v128Load32Lane, .v128Load64Lane:
            try pop2PushEmit((.v128, .address(isMemory64: isMemory64)), .v128) { popped, result in
                let vec = popped.0
                let ptr = popped.1
                return .simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: memarg.offset, input0: ptr, input1: vec, input2: .zero, result: result))
            }
        case .v128Store8Lane, .v128Store16Lane, .v128Store32Lane, .v128Store64Lane:
            let vec = try popVRegOperand(.v128)
            let ptr = try popVRegOperand(.address(isMemory64: isMemory64))
            if let vec = vec, let ptr = ptr {
                emit(.simd(.init(opcode: opcode.rawValue, lane: lane, reserved: 0, offset: memarg.offset, input0: ptr, input1: vec, input2: .zero, result: .zero)))
            }
        }
    }

    mutating func visitMemorySize(memory: UInt32) throws(WasmKitError) -> Output {
        let sizeType: ValueType = try module.isMemory64(memoryIndex: memory) ? .i64 : .i32
        pushEmit(sizeType, { .memorySize(Instruction.MemorySizeOperand(memoryIndex: memory, result: LVReg($0))) })
    }
    mutating func visitMemoryGrow(memory: UInt32) throws(WasmKitError) -> Output {
        let isMemory64 = try module.isMemory64(memoryIndex: memory)
        let sizeType = ValueType.address(isMemory64: isMemory64)
        // Just pop/push the same type (i64 or i32) value
        try popPushEmit(sizeType, sizeType) { value, result in
            .memoryGrow(
                Instruction.MemoryGrowOperand(
                    result: result, delta: value, memory: memory
                ))
        }
    }

    private mutating func visitConst(_ type: ValueType, _ value: Value) {
        // A constant is pushed without emitting anything. The consumer decides
        // how it materializes: as an instruction immediate, or, when read as a
        // register, as a constant-pool slot. When the pool cannot take another
        // constant, it is written to its stack slot here instead.
        let value = UntypedValue(value)
        if constantSlots.reserve(value) {
            valueStack.pushConst(value, type: type)
            iseqBuilder.dropResultRelink()
            return
        }
        let is32Bit = type == .i32 || type == .f32
        if is32Bit {
            pushEmit(
                type,
                {
                    .const32(Instruction.Const32Operand(value: UInt32(value.storage), result: LVReg($0)))
                })
        } else {
            pushEmit(type, { .const64(Instruction.Const64Operand(value: value, result: LLVReg($0))) })
        }
    }
    mutating func visitI32Const(value: Int32) -> Output { visitConst(.i32, .i32(UInt32(bitPattern: value))) }
    mutating func visitI64Const(value: Int64) -> Output { visitConst(.i64, .i64(UInt64(bitPattern: value))) }
    mutating func visitF32Const(value: IEEE754.Float32) -> Output { visitConst(.f32, .f32(value.bitPattern)) }
    mutating func visitF64Const(value: IEEE754.Float64) -> Output { visitConst(.f64, .f64(value.bitPattern)) }
    mutating func visitRefNull(type: HeapType) throws(WasmKitError) {
        guard case .abstract(let abstractType) = type else {
            throw WasmKitError("concrete heap type is not implemented yet")
        }
        let typeToPush = ReferenceType(isNullable: true, heapType: type)
        pushEmit(.ref(typeToPush), { .refNull(Instruction.RefNullOperand(result: $0, type: abstractType)) })
    }
    mutating func visitRefIsNull() throws(WasmKitError) -> Output {
        let value = try popRefOperand()
        let result = valueStack.push(.i32)
        guard let value else { return }
        emit(.refIsNull(Instruction.RefIsNullOperand(value: LVReg(ensureOnVReg(value)), result: LVReg(result))))
    }
    mutating func visitRefFunc(functionIndex: UInt32) throws(WasmKitError) -> Output {
        try validator.validateRefFunc(functionIndex: functionIndex)
        pushEmit(.ref(.funcRef), { .refFunc(Instruction.RefFuncOperand(index: functionIndex, result: LVReg($0))) })
    }

    /// Rejects an instruction of the typed function references proposal unless
    /// the module was parsed with that feature. The binary parser decodes these
    /// opcodes unconditionally.
    private func requireFunctionReferences(_ instruction: String) throws(WasmKitError) {
        guard module.features.contains(.functionReferences) else {
            throw WasmKitError("\(instruction) requires the function-references feature")
        }
    }

    // Typed function references instructions. Reject them explicitly: the visitor's
    // default implementation is a no-op that would leave the value stack out of sync.
    mutating func visitCallRef(typeIndex: UInt32) throws(WasmKitError) -> Output {
        try requireFunctionReferences("call_ref")
        throw WasmKitError("call_ref is not implemented yet")
    }
    mutating func visitReturnCallRef(typeIndex: UInt32) throws(WasmKitError) -> Output {
        try requireFunctionReferences("return_call_ref")
        throw WasmKitError("return_call_ref is not implemented yet")
    }
    mutating func visitRefAsNonNull() throws(WasmKitError) -> Output {
        try requireFunctionReferences("ref.as_non_null")
        throw WasmKitError("ref.as_non_null is not implemented yet")
    }
    mutating func visitBrOnNull(relativeDepth: UInt32) throws(WasmKitError) -> Output {
        try requireFunctionReferences("br_on_null")
        throw WasmKitError("br_on_null is not implemented yet")
    }
    mutating func visitBrOnNonNull(relativeDepth: UInt32) throws(WasmKitError) -> Output {
        try requireFunctionReferences("br_on_non_null")
        throw WasmKitError("br_on_non_null is not implemented yet")
    }

    private mutating func visitUnary(_ operand: ValueType, _ instruction: @escaping (Instruction.UnaryOperand) -> Instruction) throws(WasmKitError) {
        try popPushEmit(operand, operand) { value, result in
            return instruction(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(value)))
        }
    }
    private mutating func visitBinary(
        _ operand: ValueType,
        _ result: ValueType,
        _ instruction: @escaping (Instruction.BinaryOperand) -> Instruction
    ) throws(WasmKitError) {
        let rhs = try popVRegOperand(operand)
        let lhs = try popVRegOperand(operand)
        let result = valueStack.push(result)
        guard let lhs = lhs, let rhs = rhs else { return }
        emit(
            instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result))),
            resultRelink: { result in
                return instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result)))
            }
        )
    }
    /// Emits a binary operation, folding it with the operation that produced
    /// one of its operands whenever there is a superinstruction for the pair.
    ///
    /// The fold applies when the previous instruction is a binary operation
    /// of the same type, is still the last thing in the instruction buffer,
    /// and its result is exactly one of this operation's two operands. That
    /// result is a value-stack temporary this operation pops, so nothing else
    /// can read it and the write to its slot can simply disappear.
    ///
    /// The intermediate may be the left operand, the right operand of a
    /// commutative consumer (operands swapped), or the right operand of a
    /// consumer with a reversed opcode.
    ///
    /// An integer `and` also records a fusable condition for a following
    /// conditional branch. A fused emission records none, since the branch
    /// fusion would have to re-materialize the absorbed producer.
    @inline(never)
    private mutating func visitFusableBinary(
        _ type: ValueType,
        _ op: BinBinOp
    ) throws(WasmKitError) {
        // Captured before `popOperand`, which resets the last emission.
        let candidate = iseqBuilder.binaryEmission
        let accCandidate = iseqBuilder.accProducer
        // Popped as sources, so that a constant operand gets a pool slot only
        // when no immediate form takes it.
        let rhsSource = try popOperand(type)
        let lhsSource = try popOperand(type)
        let result = valueStack.push(type)
        guard let lhsSource, let rhsSource else { return }
        // A fold matches the register a previous instruction wrote, which is
        // always a stack temporary.
        let lhsProduced = lhsSource.stackRegister
        let rhsProduced = rhsSource.stackRegister

        if let candidate, candidate.operation.type == type, iseqBuilder.canRewind(to: candidate) {
            let produced = candidate.operation
            // `z` must not be the intermediate itself: its slot is no longer
            // written once the producer is rewound away.
            var fused: (make: (Instruction.BinBinOperand) -> Instruction, z: ValueSource)?
            if produced.result == lhsProduced, produced.result != rhsProduced,
                let make = Self.binBinInstruction(type, produced.op, op, reversed: false)
            {
                fused = (make, rhsSource)
            } else if produced.result == rhsProduced, produced.result != lhsProduced {
                if op.isCommutative,
                    let make = Self.binBinInstruction(type, produced.op, op, reversed: false)
                {
                    fused = (make, lhsSource)
                } else if let make = Self.binBinInstruction(type, produced.op, op, reversed: true) {
                    fused = (make, lhsSource)
                }
            }
            // A producer that carried its constant in the instruction needs it
            // in the pool now; no fold when the pool is full.
            if fused != nil, let constant = produced.rhsConstant, !constantSlots.reserve(constant) {
                fused = nil
            }
            if let (make, zSource) = fused {
                let z = ensureOnVReg(zSource)
                let x = produced.lhs
                let y = produced.rhsConstant.map { stackLayout.constReg(constantSlots.allocate($0)) } ?? produced.rhs
                iseqBuilder.rewind(to: candidate.position)
                self.rewindInstructionMapping(to: candidate.position)
                if let prefix = candidate.prefix {
                    emit(prefix.plain)
                }
                emit(
                    make(Instruction.BinBinOperand(result: result, x: x, y: y, z: z)),
                    resultRelink: { newResult in
                        make(Instruction.BinBinOperand(result: newResult, x: x, y: y, z: z))
                    }
                )
                if type == .f64 {
                    iseqBuilder.recordAcc(
                        AccRecords(producer: .floatBinBin(op1: produced.op, op2: op, x: x, y: y, z: z, result: result)))
                }
                return
            }
        }

        let accForms = Self.accBinaryForms(type, op)
        // Without a superinstruction, hand the operand over in the accumulator.
        // The value must be exactly one of the two operands; a commutative
        // operation takes it on either side.
        if let accCandidate, let accForms, accCandidate.form.type == type,
            accCandidate.producing(into: .integer) != nil, iseqBuilder.canRewind(to: accCandidate)
        {
            let accResult = accCandidate.form.result
            // Matched against the slot each operand occupies, which is a local's
            // slot when the producer was relinked into it.
            let lhsSlot = existingSlot(of: lhsSource)
            let rhsSlot = existingSlot(of: rhsSource)
            var operandSource: ValueSource?
            if accResult == lhsSlot, accResult != rhsSlot {
                operandSource = rhsSource
            } else if accResult == rhsSlot, accResult != lhsSlot, op.isCommutative {
                operandSource = lhsSource
            }
            // A producer that keeps its slot saves only the consumer's load,
            // which an immediate form also saves without a pool slot.
            if accCandidate.keepsSlot, let constant = operandSource?.constant,
                Self.immBinaryForms(type, op == .sub ? .add : op) != nil,
                Self.immediateEncoding(of: op == .sub ? 0 &- constant : constant, as: type) != nil
            {
                operandSource = nil
            }
            if let operandSource {
                let operand = ensureOnVReg(operandSource)
                rewindProducerIntoAccumulator(accCandidate)
                let fromAcc = accForms.fromAcc(Instruction.AccUnaryOperand(operand: operand, result: LVReg(result)))
                emit(
                    fromAcc,
                    resultRelink: { newResult in
                        accForms.fromAcc(Instruction.AccUnaryOperand(operand: operand, result: LVReg(newResult)))
                    },
                    fusable: FusedAndWidth(type: type, op: op).map {
                        (.and(width: $0, lhs: accResult, rhs: operand), result, accCandidate.position)
                    },
                    binary: BinaryOperation(type: type, op: op, lhs: accResult, rhs: operand, result: result)
                )
                iseqBuilder.recordAcc(
                    AccRecords(
                        producer: .fromAcc(type: type, op: op, operand: operand, result: result),
                        prefix: (accCandidate.position, accCandidate.form)))
                return
            }
        }

        // The same for `f64`, through the float accumulator. A value arriving
        // as the right operand of `sub` or `div` uses a reversed form.
        let floatAccForms = Self.floatAccBinaryForms(type, op)
        if let accCandidate, let floatAccForms, accCandidate.producing(into: .float) != nil,
            iseqBuilder.canRewind(to: accCandidate)
        {
            let accResult = accCandidate.form.result
            var choice: (operand: ValueSource, reversed: Bool)?
            if accResult == lhsProduced, accResult != rhsProduced {
                choice = (rhsSource, false)
            } else if accResult == rhsProduced, accResult != lhsProduced {
                choice = op.isCommutative ? (lhsSource, false) : (lhsSource, true)
            }
            if let (operandSource, reversed) = choice {
                let lhs = ensureOnVReg(lhsSource)
                let rhs = ensureOnVReg(rhsSource)
                let operand = ensureOnVReg(operandSource)
                rewindProducerIntoAccumulator(accCandidate, .float)
                let make = reversed ? floatAccForms.fromAccRev! : floatAccForms.fromAcc
                emit(
                    make(Instruction.AccUnaryOperand(operand: operand, result: LVReg(result))),
                    resultRelink: { newResult in
                        make(Instruction.AccUnaryOperand(operand: operand, result: LVReg(newResult)))
                    },
                    // In source operand order: every shape above computes
                    // `lhs <op> rhs`, and a superinstruction built on it reads
                    // the slots in the same order as the unfolded translation.
                    binary: BinaryOperation(type: type, op: op, lhs: lhs, rhs: rhs, result: result)
                )
                iseqBuilder.recordAcc(
                    AccRecords(
                        producer: .fromFloatAcc(op: op, operand: operand, reversed: reversed, result: result),
                        prefix: (accCandidate.position, accCandidate.form)))
                return
            }
        }

        // A constant operand is carried in the instruction when nothing above
        // folded: a superinstruction removes a dispatch and the accumulator a
        // frame-slot round trip, which both beat the one load an immediate saves.
        if emitsImmediateOperands, let form = immediateBinaryForm(type, op, lhs: lhsSource, rhs: rhsSource) {
            let forms = form.forms
            let lhs = form.lhs
            let imm = form.imm
            emit(
                forms.plain(Instruction.BinaryImmOperand(result: result, lhs: lhs, imm: imm)),
                resultRelink: { newResult in
                    forms.plain(Instruction.BinaryImmOperand(result: newResult, lhs: lhs, imm: imm))
                },
                fusable: FusedAndWidth(type: type, op: op).map { (.andImm(width: $0, lhs: lhs, imm: imm), result, nil) },
                binary: BinaryOperation(
                    type: type, op: op, lhs: lhs, rhs: lhs, result: result, rhsConstant: form.constant)
            )
            iseqBuilder.recordAcc(
                AccRecords(producer: .binaryImm(type: type, op: form.op, lhs: lhs, imm: imm, result: result)))
            return
        }

        let lhs = ensureOnVReg(lhsSource)
        let rhs = ensureOnVReg(rhsSource)
        let instruction = Self.plainBinaryInstruction(type, op)
        let plain = instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result)))
        emit(
            plain,
            resultRelink: { newResult in
                instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(newResult)))
            },
            fusable: FusedAndWidth(type: type, op: op).map { (.and(width: $0, lhs: lhs, rhs: rhs), result, nil) },
            binary: BinaryOperation(type: type, op: op, lhs: lhs, rhs: rhs, result: result)
        )
        if accForms != nil || floatAccForms != nil {
            iseqBuilder.recordAcc(AccRecords(producer: .binary(type: type, op: op, lhs: lhs, rhs: rhs, result: result)))
        }
    }

    /// Immediate-operand forms are emitted under direct threading only; the
    /// token-threaded dispatcher has no cases for them.
    private var emitsImmediateOperands: Bool {
        engineConfiguration.threadingModel == .direct
    }

    /// The 32-bit immediate encoding `raw` as an operand of `type`: every `i32`
    /// fits, and an `i64` fits when it survives sign extension.
    private static func immediateEncoding(of raw: UInt64, as type: ValueType) -> Int32? {
        let low = Int32(bitPattern: UInt32(truncatingIfNeeded: raw))
        switch type {
        case .i32: return low
        case .i64: return UInt64(bitPattern: Int64(low)) == raw ? low : nil
        default: return nil
        }
    }

    /// The immediate-operand form of `lhs <op> rhs` when one operand is a
    /// constant that fits. `x - c` is emitted as `x + (-c)`, and a constant on
    /// the left moves right only when the operation commutes. `constant` is the
    /// right operand of `op` itself, for a later superinstruction fold.
    private mutating func immediateBinaryForm(
        _ type: ValueType, _ op: BinBinOp, lhs lhsSource: ValueSource, rhs rhsSource: ValueSource
    ) -> (forms: ImmBinaryForms, op: BinBinOp, lhs: VReg, imm: Int32, constant: UntypedValue)? {
        let immOp: BinBinOp = op == .sub ? .add : op
        guard let forms = Self.immBinaryForms(type, immOp) else { return nil }
        if let raw = rhsSource.constant {
            // Negation wraps, so it is exact for every constant.
            let value = op == .sub ? 0 &- raw : raw
            if let imm = Self.immediateEncoding(of: value, as: type) {
                return (forms, immOp, ensureOnVReg(lhsSource), imm, UntypedValue(storage: raw))
            }
        }
        if op.isCommutative, let raw = lhsSource.constant, let imm = Self.immediateEncoding(of: raw, as: type) {
            return (forms, immOp, ensureOnVReg(rhsSource), imm, UntypedValue(storage: raw))
        }
        return nil
    }

    /// Emits a comparison, recording it as a candidate for compare+branch
    /// fusion. `makeCondition` builds the ``FusableCondition`` from the
    /// comparison's operand registers.
    private mutating func visitCmp(
        _ operand: ValueType,
        _ makeCondition: (_ lhs: VReg, _ rhs: VReg) -> FusableCondition,
        _ instruction: @escaping (Instruction.BinaryOperand) -> Instruction
    ) throws(WasmKitError) {
        // Captured before `popOperand`, which resets the last emission.
        let accCandidate = iseqBuilder.accProducer
        let rhsSource = try popOperand(operand)
        let lhsSource = try popOperand(operand)
        let result = valueStack.push(.i32)
        guard let lhsSource, let rhsSource else { return }
        // Compare against a constant carried in the instruction.
        if emitsImmediateOperands, case .compare(let kind, _, _) = makeCondition(.zero, .zero) {
            var immediate: (kind: FusedCmpKind, lhs: VReg, imm: Int32)?
            if let raw = rhsSource.constant, let imm = Self.immediateEncoding(of: raw, as: operand) {
                immediate = (kind, ensureOnVReg(lhsSource), imm)
            } else if let raw = lhsSource.constant, let imm = Self.immediateEncoding(of: raw, as: operand) {
                immediate = (kind.swapped, ensureOnVReg(rhsSource), imm)
            }
            if let immediate {
                let make = immediate.kind.makeCmpImm
                emit(
                    make(Instruction.BinaryImmOperand(result: result, lhs: immediate.lhs, imm: immediate.imm)),
                    resultRelink: { newResult in
                        make(Instruction.BinaryImmOperand(result: newResult, lhs: immediate.lhs, imm: immediate.imm))
                    },
                    fusable: (.compareImm(kind: immediate.kind, lhs: immediate.lhs, imm: immediate.imm), result, nil)
                )
                return
            }
        }
        let lhs = ensureOnVReg(lhsSource)
        let rhs = ensureOnVReg(rhsSource)
        let condition = makeCondition(lhs, rhs)
        // Record whether a branch fusing this comparison can also take one
        // operand from the accumulator. A right operand swaps the predicate.
        var accCompare: AccCompare?
        if let accCandidate, iseqBuilder.canRewind(to: accCandidate) {
            let accResult = accCandidate.form.result
            let slot: (rhs: VReg, swapped: Bool)?
            if accResult == lhs, accResult != rhs {
                slot = (rhs, false)
            } else if accResult == rhs, accResult != lhs {
                slot = (lhs, true)
            } else {
                slot = nil
            }
            var kind: AccCompare.Kind?
            switch condition {
            case .compare(let cmp, _, _)
            where accCandidate.form.type == cmp.operandType
                && accCandidate.producing(into: .integer) != nil:
                kind = slot.map { .integer($0.swapped ? cmp.swapped : cmp) }
            case .floatCompare(let cmp, _, _)
            where cmp.operandType == .f64
                && accCandidate.producing(into: .float) != nil:
                kind = slot.map { .float($0.swapped ? cmp.swapped : cmp) }
            default:
                kind = nil
            }
            if let kind, let slot {
                accCompare = AccCompare(
                    kind: kind, rhs: slot.rhs, producerPosition: accCandidate.position, producer: accCandidate)
            }
        }
        emit(
            instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result))),
            resultRelink: { result in
                return instruction(Instruction.BinaryOperand(lhs: lhs, rhs: rhs, result: LVReg(result)))
            },
            fusable: (condition, result, nil)
        )
        if let accCompare {
            iseqBuilder.recordAcc(AccRecords(compare: accCompare))
        }
    }
    private mutating func visitConversion(_ from: ValueType, _ to: ValueType, _ instruction: @escaping (Instruction.UnaryOperand) -> Instruction) throws(WasmKitError) {
        try popPushEmit(from, to) { value, result in
            return instruction(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(value)))
        }
    }
    mutating func visitI32Eqz() throws(WasmKitError) -> Output {
        // Captured before `popVRegOperand`, which resets the last emission.
        let candidate = iseqBuilder.fusableEmission
        let value = try popVRegOperand(.i32)
        let result = valueStack.push(.i32)
        guard let value = value else { return }
        // When the operand is a condition another instruction just computed,
        // the pair is itself a fusable condition: the negation of the first.
        // It is recorded with that instruction's start position, so a branch
        // consuming this `i32.eqz` rewinds both away and emits a single fused
        // branch of the opposite polarity. Nothing is lost when no branch
        // follows: the `i32.eqz` below is still emitted and still materializes
        // the boolean.
        let fusable: (condition: FusableCondition, result: VReg, start: MetaProgramCounter?)
        var prefix: (position: MetaProgramCounter, producer: AccProducerForm)?
        var accCompare: AccCompare?
        if let candidate, candidate.result == value, iseqBuilder.canRewind(to: candidate) {
            fusable = (.negated(candidate.condition), result, candidate.position)
            prefix = candidate.prefix.map { (candidate.position, $0) }
            accCompare = candidate.accCompare
            accCompare?.negated.toggle()
        } else {
            fusable = (.i32Eqz(input: value), result, nil)
        }
        emit(
            .i32Eqz(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(value))),
            resultRelink: { newResult in
                .i32Eqz(Instruction.UnaryOperand(result: LVReg(newResult), input: LVReg(value)))
            },
            fusable: fusable
        )
        if prefix != nil || accCompare != nil {
            iseqBuilder.recordAcc(AccRecords(compare: accCompare, prefix: prefix))
        }
    }
    mutating func visitCmp(_ cmp: WasmParser.Instruction.Cmp) throws(WasmKitError) {
        let operand: ValueType
        let instruction: (Instruction.BinaryOperand) -> Instruction
        let fusedKind: FusedCmpKind?
        let fusedFloatKind: FusedFCmpKind?
        switch cmp {
        case .i32Eq: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32Eq, .i32Eq, nil)
        case .i32Ne: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32Ne, .i32Ne, nil)
        case .i32LtS: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32LtS, .i32LtS, nil)
        case .i32LtU: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32LtU, .i32LtU, nil)
        case .i32GtS: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32GtS, .i32GtS, nil)
        case .i32GtU: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32GtU, .i32GtU, nil)
        case .i32LeS: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32LeS, .i32LeS, nil)
        case .i32LeU: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32LeU, .i32LeU, nil)
        case .i32GeS: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32GeS, .i32GeS, nil)
        case .i32GeU: (operand, instruction, fusedKind, fusedFloatKind) = (.i32, Instruction.i32GeU, .i32GeU, nil)
        case .i64Eq: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64Eq, .i64Eq, nil)
        case .i64Ne: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64Ne, .i64Ne, nil)
        case .i64LtS: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64LtS, .i64LtS, nil)
        case .i64LtU: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64LtU, .i64LtU, nil)
        case .i64GtS: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64GtS, .i64GtS, nil)
        case .i64GtU: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64GtU, .i64GtU, nil)
        case .i64LeS: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64LeS, .i64LeS, nil)
        case .i64LeU: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64LeU, .i64LeU, nil)
        case .i64GeS: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64GeS, .i64GeS, nil)
        case .i64GeU: (operand, instruction, fusedKind, fusedFloatKind) = (.i64, Instruction.i64GeU, .i64GeU, nil)
        case .f32Eq: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Eq, nil, .f32Eq)
        case .f32Ne: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Ne, nil, .f32Ne)
        case .f32Lt: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Lt, nil, .f32Lt)
        case .f32Gt: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Gt, nil, .f32Gt)
        case .f32Le: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Le, nil, .f32Le)
        case .f32Ge: (operand, instruction, fusedKind, fusedFloatKind) = (.f32, Instruction.f32Ge, nil, .f32Ge)
        case .f64Eq: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Eq, nil, .f64Eq)
        case .f64Ne: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Ne, nil, .f64Ne)
        case .f64Lt: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Lt, nil, .f64Lt)
        case .f64Gt: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Gt, nil, .f64Gt)
        case .f64Le: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Le, nil, .f64Le)
        case .f64Ge: (operand, instruction, fusedKind, fusedFloatKind) = (.f64, Instruction.f64Ge, nil, .f64Ge)
        }
        let makeCondition: (VReg, VReg) -> FusableCondition
        if let fusedKind {
            makeCondition = { .compare(kind: fusedKind, lhs: $0, rhs: $1) }
        } else if let fusedFloatKind {
            makeCondition = { .floatCompare(kind: fusedFloatKind, lhs: $0, rhs: $1) }
        } else {
            preconditionFailure("Internal consistency error: every comparison has a fused form")
        }
        try visitCmp(operand, makeCondition, instruction)
    }
    public mutating func visitBinary(_ binary: WasmParser.Instruction.Binary) throws(WasmKitError) {
        // Operations with a superinstruction form go through
        // `visitFusableBinary`, which folds adjacent pairs.
        switch binary {
        case .f32Add: return try visitFusableBinary(.f32, .add)
        case .f32Sub: return try visitFusableBinary(.f32, .sub)
        case .f32Mul: return try visitFusableBinary(.f32, .mul)
        case .f32Div: return try visitFusableBinary(.f32, .div)
        case .f64Add: return try visitFusableBinary(.f64, .add)
        case .f64Sub: return try visitFusableBinary(.f64, .sub)
        case .f64Mul: return try visitFusableBinary(.f64, .mul)
        case .f64Div: return try visitFusableBinary(.f64, .div)
        case .i32Add: return try visitFusableBinary(.i32, .add)
        case .i32Sub: return try visitFusableBinary(.i32, .sub)
        case .i32Mul: return try visitFusableBinary(.i32, .mul)
        case .i32And: return try visitFusableBinary(.i32, .and)
        case .i32Or: return try visitFusableBinary(.i32, .or)
        case .i32Xor: return try visitFusableBinary(.i32, .xor)
        case .i32Shl: return try visitFusableBinary(.i32, .shl)
        case .i32ShrS: return try visitFusableBinary(.i32, .shrS)
        case .i32ShrU: return try visitFusableBinary(.i32, .shrU)
        case .i32Rotl: return try visitFusableBinary(.i32, .rotl)
        case .i32Rotr: return try visitFusableBinary(.i32, .rotr)
        case .i64Add: return try visitFusableBinary(.i64, .add)
        case .i64Sub: return try visitFusableBinary(.i64, .sub)
        case .i64Mul: return try visitFusableBinary(.i64, .mul)
        case .i64And: return try visitFusableBinary(.i64, .and)
        case .i64Or: return try visitFusableBinary(.i64, .or)
        case .i64Xor: return try visitFusableBinary(.i64, .xor)
        case .i64Shl: return try visitFusableBinary(.i64, .shl)
        case .i64ShrS: return try visitFusableBinary(.i64, .shrS)
        case .i64ShrU: return try visitFusableBinary(.i64, .shrU)
        case .i64Rotl: return try visitFusableBinary(.i64, .rotl)
        case .i64Rotr: return try visitFusableBinary(.i64, .rotr)
        default: break
        }
        let operand: ValueType
        let result: ValueType
        let instruction: (Instruction.BinaryOperand) -> Instruction
        switch binary {
        case .i32Add: (operand, result, instruction) = (.i32, .i32, Instruction.i32Add)
        case .i32Sub: (operand, result, instruction) = (.i32, .i32, Instruction.i32Sub)
        case .i32Mul: (operand, result, instruction) = (.i32, .i32, Instruction.i32Mul)
        case .i32DivS: (operand, result, instruction) = (.i32, .i32, Instruction.i32DivS)
        case .i32DivU: (operand, result, instruction) = (.i32, .i32, Instruction.i32DivU)
        case .i32RemS: (operand, result, instruction) = (.i32, .i32, Instruction.i32RemS)
        case .i32RemU: (operand, result, instruction) = (.i32, .i32, Instruction.i32RemU)
        case .i32And: (operand, result, instruction) = (.i32, .i32, Instruction.i32And)
        case .i32Or: (operand, result, instruction) = (.i32, .i32, Instruction.i32Or)
        case .i32Xor: (operand, result, instruction) = (.i32, .i32, Instruction.i32Xor)
        case .i32Shl: (operand, result, instruction) = (.i32, .i32, Instruction.i32Shl)
        case .i32ShrS: (operand, result, instruction) = (.i32, .i32, Instruction.i32ShrS)
        case .i32ShrU: (operand, result, instruction) = (.i32, .i32, Instruction.i32ShrU)
        case .i32Rotl: (operand, result, instruction) = (.i32, .i32, Instruction.i32Rotl)
        case .i32Rotr: (operand, result, instruction) = (.i32, .i32, Instruction.i32Rotr)
        case .i64Add: (operand, result, instruction) = (.i64, .i64, Instruction.i64Add)
        case .i64Sub: (operand, result, instruction) = (.i64, .i64, Instruction.i64Sub)
        case .i64Mul: (operand, result, instruction) = (.i64, .i64, Instruction.i64Mul)
        case .i64DivS: (operand, result, instruction) = (.i64, .i64, Instruction.i64DivS)
        case .i64DivU: (operand, result, instruction) = (.i64, .i64, Instruction.i64DivU)
        case .i64RemS: (operand, result, instruction) = (.i64, .i64, Instruction.i64RemS)
        case .i64RemU: (operand, result, instruction) = (.i64, .i64, Instruction.i64RemU)
        case .i64And: (operand, result, instruction) = (.i64, .i64, Instruction.i64And)
        case .i64Or: (operand, result, instruction) = (.i64, .i64, Instruction.i64Or)
        case .i64Xor: (operand, result, instruction) = (.i64, .i64, Instruction.i64Xor)
        case .i64Shl: (operand, result, instruction) = (.i64, .i64, Instruction.i64Shl)
        case .i64ShrS: (operand, result, instruction) = (.i64, .i64, Instruction.i64ShrS)
        case .i64ShrU: (operand, result, instruction) = (.i64, .i64, Instruction.i64ShrU)
        case .i64Rotl: (operand, result, instruction) = (.i64, .i64, Instruction.i64Rotl)
        case .i64Rotr: (operand, result, instruction) = (.i64, .i64, Instruction.i64Rotr)
        case .f32Add: (operand, result, instruction) = (.f32, .f32, Instruction.f32Add)
        case .f32Sub: (operand, result, instruction) = (.f32, .f32, Instruction.f32Sub)
        case .f32Mul: (operand, result, instruction) = (.f32, .f32, Instruction.f32Mul)
        case .f32Div: (operand, result, instruction) = (.f32, .f32, Instruction.f32Div)
        case .f32Min: (operand, result, instruction) = (.f32, .f32, Instruction.f32Min)
        case .f32Max: (operand, result, instruction) = (.f32, .f32, Instruction.f32Max)
        case .f32Copysign: (operand, result, instruction) = (.f32, .f32, Instruction.f32CopySign)
        case .f64Add: (operand, result, instruction) = (.f64, .f64, Instruction.f64Add)
        case .f64Sub: (operand, result, instruction) = (.f64, .f64, Instruction.f64Sub)
        case .f64Mul: (operand, result, instruction) = (.f64, .f64, Instruction.f64Mul)
        case .f64Div: (operand, result, instruction) = (.f64, .f64, Instruction.f64Div)
        case .f64Min: (operand, result, instruction) = (.f64, .f64, Instruction.f64Min)
        case .f64Max: (operand, result, instruction) = (.f64, .f64, Instruction.f64Max)
        case .f64Copysign: (operand, result, instruction) = (.f64, .f64, Instruction.f64CopySign)
        }
        try visitBinary(operand, result, instruction)
    }
    mutating func visitI64Eqz() throws(WasmKitError) -> Output {
        // Captured before `popVRegOperand`, which resets the last emission.
        let candidate = iseqBuilder.fusableEmission
        let value = try popVRegOperand(.i64)
        let result = valueStack.push(.i32)
        guard let value = value else { return }
        // An `i64.eqz` of a 64-bit `and` the previous instruction just computed is
        // that bit test negated, so a following branch can replace both.
        var fusable: (condition: FusableCondition, result: VReg, start: MetaProgramCounter?)?
        var prefix: (position: MetaProgramCounter, producer: AccProducerForm)?
        var accCompare: AccCompare?
        if let candidate, candidate.result == value, iseqBuilder.canRewind(to: candidate) {
            fusable = (.negated(candidate.condition), result, candidate.position)
            prefix = candidate.prefix.map { (candidate.position, $0) }
            accCompare = candidate.accCompare
            accCompare?.negated.toggle()
        }
        emit(
            .i64Eqz(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(value))),
            resultRelink: { newResult in
                .i64Eqz(Instruction.UnaryOperand(result: LVReg(newResult), input: LVReg(value)))
            },
            fusable: fusable
        )
        if prefix != nil || accCompare != nil {
            iseqBuilder.recordAcc(AccRecords(compare: accCompare, prefix: prefix))
        }
    }
    /// `f64.sqrt`, which can produce its result into the float accumulator.
    private mutating func visitF64Sqrt() throws(WasmKitError) {
        let value = try popVRegOperand(.f64)
        let result = valueStack.push(.f64)
        guard let value else { return }
        emit(
            .f64Sqrt(Instruction.UnaryOperand(result: LVReg(result), input: LVReg(value))),
            resultRelink: { newResult in
                .f64Sqrt(Instruction.UnaryOperand(result: LVReg(newResult), input: LVReg(value)))
            }
        )
        iseqBuilder.recordAcc(AccRecords(producer: .sqrt(operand: value, result: result)))
    }
    mutating func visitUnary(_ unary: WasmParser.Instruction.Unary) throws(WasmKitError) {
        let operand: ValueType
        let instruction: (Instruction.UnaryOperand) -> Instruction
        switch unary {
        case .i32Clz: (operand, instruction) = (.i32, Instruction.i32Clz)
        case .i32Ctz: (operand, instruction) = (.i32, Instruction.i32Ctz)
        case .i32Popcnt: (operand, instruction) = (.i32, Instruction.i32Popcnt)
        case .i64Clz: (operand, instruction) = (.i64, Instruction.i64Clz)
        case .i64Ctz: (operand, instruction) = (.i64, Instruction.i64Ctz)
        case .i64Popcnt: (operand, instruction) = (.i64, Instruction.i64Popcnt)
        case .f32Abs: (operand, instruction) = (.f32, Instruction.f32Abs)
        case .f32Neg: (operand, instruction) = (.f32, Instruction.f32Neg)
        case .f32Ceil: (operand, instruction) = (.f32, Instruction.f32Ceil)
        case .f32Floor: (operand, instruction) = (.f32, Instruction.f32Floor)
        case .f32Trunc: (operand, instruction) = (.f32, Instruction.f32Trunc)
        case .f32Nearest: (operand, instruction) = (.f32, Instruction.f32Nearest)
        case .f32Sqrt: (operand, instruction) = (.f32, Instruction.f32Sqrt)
        case .f64Abs: (operand, instruction) = (.f64, Instruction.f64Abs)
        case .f64Neg: (operand, instruction) = (.f64, Instruction.f64Neg)
        case .f64Ceil: (operand, instruction) = (.f64, Instruction.f64Ceil)
        case .f64Floor: (operand, instruction) = (.f64, Instruction.f64Floor)
        case .f64Trunc: (operand, instruction) = (.f64, Instruction.f64Trunc)
        case .f64Nearest: (operand, instruction) = (.f64, Instruction.f64Nearest)
        case .f64Sqrt: return try visitF64Sqrt()
        case .i32Extend8S: (operand, instruction) = (.i32, Instruction.i32Extend8S)
        case .i32Extend16S: (operand, instruction) = (.i32, Instruction.i32Extend16S)
        case .i64Extend8S: (operand, instruction) = (.i64, Instruction.i64Extend8S)
        case .i64Extend16S: (operand, instruction) = (.i64, Instruction.i64Extend16S)
        case .i64Extend32S: (operand, instruction) = (.i64, Instruction.i64Extend32S)
        }
        try visitUnary(operand, instruction)
    }
    mutating func visitConversion(_ conversion: WasmParser.Instruction.Conversion) throws(WasmKitError) {
        let from: ValueType
        let to: ValueType
        let instruction: (Instruction.UnaryOperand) -> Instruction
        switch conversion {
        case .i32WrapI64: (from, to, instruction) = (.i64, .i32, Instruction.i32WrapI64)
        case .i32TruncF32S: (from, to, instruction) = (.f32, .i32, Instruction.i32TruncF32S)
        case .i32TruncF32U: (from, to, instruction) = (.f32, .i32, Instruction.i32TruncF32U)
        case .i32TruncF64S: (from, to, instruction) = (.f64, .i32, Instruction.i32TruncF64S)
        case .i32TruncF64U: (from, to, instruction) = (.f64, .i32, Instruction.i32TruncF64U)
        case .i64ExtendI32S: (from, to, instruction) = (.i32, .i64, Instruction.i64ExtendI32S)
        case .i64ExtendI32U: (from, to, instruction) = (.i32, .i64, Instruction.i64ExtendI32U)
        case .i64TruncF32S: (from, to, instruction) = (.f32, .i64, Instruction.i64TruncF32S)
        case .i64TruncF32U: (from, to, instruction) = (.f32, .i64, Instruction.i64TruncF32U)
        case .i64TruncF64S: (from, to, instruction) = (.f64, .i64, Instruction.i64TruncF64S)
        case .i64TruncF64U: (from, to, instruction) = (.f64, .i64, Instruction.i64TruncF64U)
        case .f32ConvertI32S: (from, to, instruction) = (.i32, .f32, Instruction.f32ConvertI32S)
        case .f32ConvertI32U: (from, to, instruction) = (.i32, .f32, Instruction.f32ConvertI32U)
        case .f32ConvertI64S: (from, to, instruction) = (.i64, .f32, Instruction.f32ConvertI64S)
        case .f32ConvertI64U: (from, to, instruction) = (.i64, .f32, Instruction.f32ConvertI64U)
        case .f32DemoteF64: (from, to, instruction) = (.f64, .f32, Instruction.f32DemoteF64)
        case .f64ConvertI32S: (from, to, instruction) = (.i32, .f64, Instruction.f64ConvertI32S)
        case .f64ConvertI32U: (from, to, instruction) = (.i32, .f64, Instruction.f64ConvertI32U)
        case .f64ConvertI64S: (from, to, instruction) = (.i64, .f64, Instruction.f64ConvertI64S)
        case .f64ConvertI64U: (from, to, instruction) = (.i64, .f64, Instruction.f64ConvertI64U)
        case .f64PromoteF32: (from, to, instruction) = (.f32, .f64, Instruction.f64PromoteF32)
        case .i32ReinterpretF32: (from, to, instruction) = (.f32, .i32, Instruction.i32ReinterpretF32)
        case .i64ReinterpretF64: (from, to, instruction) = (.f64, .i64, Instruction.i64ReinterpretF64)
        case .f32ReinterpretI32: (from, to, instruction) = (.i32, .f32, Instruction.f32ReinterpretI32)
        case .f64ReinterpretI64: (from, to, instruction) = (.i64, .f64, Instruction.f64ReinterpretI64)
        case .i32TruncSatF32S: (from, to, instruction) = (.f32, .i32, Instruction.i32TruncSatF32S)
        case .i32TruncSatF32U: (from, to, instruction) = (.f32, .i32, Instruction.i32TruncSatF32U)
        case .i32TruncSatF64S: (from, to, instruction) = (.f64, .i32, Instruction.i32TruncSatF64S)
        case .i32TruncSatF64U: (from, to, instruction) = (.f64, .i32, Instruction.i32TruncSatF64U)
        case .i64TruncSatF32S: (from, to, instruction) = (.f32, .i64, Instruction.i64TruncSatF32S)
        case .i64TruncSatF32U: (from, to, instruction) = (.f32, .i64, Instruction.i64TruncSatF32U)
        case .i64TruncSatF64S: (from, to, instruction) = (.f64, .i64, Instruction.i64TruncSatF64S)
        case .i64TruncSatF64U: (from, to, instruction) = (.f64, .i64, Instruction.i64TruncSatF64U)
        }
        try visitConversion(from, to, instruction)
    }

    mutating func visitMemoryInit(dataIndex: UInt32) throws(WasmKitError) -> Output {
        try self.validator.validateDataSegment(dataIndex)
        let addressType = try module.addressType(memoryIndex: 0)
        try pop3Emit((.i32, .i32, addressType)) { values, stack in
            let (size, sourceOffset, destOffset) = values
            return .memoryInit(
                Instruction.MemoryInitOperand(
                    segmentIndex: dataIndex,
                    destOffset: destOffset,
                    sourceOffset: sourceOffset,
                    size: size
                )
            )
        }
    }
    mutating func visitDataDrop(dataIndex: UInt32) throws(WasmKitError) -> Output {
        try self.validator.validateDataSegment(dataIndex)
        emit(.memoryDataDrop(Instruction.MemoryDataDropOperand(segmentIndex: dataIndex)))
    }
    mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws(WasmKitError) -> Output {
        //     C.mems[0] = it limits
        // -----------------------------
        // C ⊦ memory.fill : [it i32 it] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        let addressType = try module.addressType(memoryIndex: 0)
        try pop3Emit((addressType, addressType, addressType)) { values, stack in
            let (size, sourceOffset, destOffset) = values
            return .memoryCopy(
                Instruction.MemoryCopyOperand(
                    destOffset: destOffset,
                    sourceOffset: sourceOffset,
                    size: LVReg(size)
                )
            )
        }
    }
    mutating func visitMemoryFill(memory: UInt32) throws(WasmKitError) -> Output {
        //     C.mems[0] = it limits
        // -----------------------------
        // C ⊦ memory.fill : [it i32 it] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        let addressType = try module.addressType(memoryIndex: 0)
        try pop3Emit((addressType, .i32, addressType)) { values, stack in
            let (size, value, destOffset) = values
            return .memoryFill(
                Instruction.MemoryFillOperand(
                    destOffset: destOffset,
                    value: value,
                    size: LVReg(size)
                )
            )
        }
    }
    mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws(WasmKitError) -> Output {
        try validator.validateTableInit(elemIndex: elemIndex, table: table)

        try pop3Emit((.i32, .i32, module.addressType(tableIndex: table))) { values, stack in
            let (size, sourceOffset, destOffset) = values
            return .tableInit(
                Instruction.TableInitOperand(
                    tableIndex: table,
                    segmentIndex: elemIndex,
                    destOffset: destOffset,
                    sourceOffset: sourceOffset,
                    size: size
                )
            )
        }
    }
    mutating func visitElemDrop(elemIndex: UInt32) throws(WasmKitError) -> Output {
        try self.module.validateElementSegment(elemIndex)
        emit(.tableElementDrop(Instruction.TableElementDropOperand(index: elemIndex)))
    }
    mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws(WasmKitError) -> Output {
        //   C.tables[d] = iN limits t   C.tables[s] = iM limits t    K = min {N, M}
        // -----------------------------------------------------------------------------
        // C ⊦ table.copy d s : [iN iM iK] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        try validator.validateTableCopy(dest: dstTable, source: srcTable)
        let destIsMemory64 = try module.isMemory64(tableIndex: dstTable)
        let sourceIsMemory64 = try module.isMemory64(tableIndex: srcTable)
        let lengthIsMemory64 = destIsMemory64 && sourceIsMemory64
        try pop3Emit(
            (
                .address(isMemory64: lengthIsMemory64),
                .address(isMemory64: sourceIsMemory64),
                .address(isMemory64: destIsMemory64)
            )
        ) { values, stack in
            let (size, sourceOffset, destOffset) = values
            return .tableCopy(
                Instruction.TableCopyOperand(
                    sourceIndex: srcTable,
                    destIndex: dstTable,
                    destOffset: destOffset,
                    sourceOffset: sourceOffset,
                    size: size
                )
            )
        }
    }
    mutating func visitTableFill(table: UInt32) throws(WasmKitError) -> Output {
        let address = try module.addressType(tableIndex: table)
        let type = try module.tableType(table)
        try pop3Emit((address, .ref(type.elementType), address)) { values, stack in
            let (size, value, destOffset) = values
            return .tableFill(
                Instruction.TableFillOperand(
                    tableIndex: table,
                    destOffset: destOffset,
                    value: value,
                    size: size
                )
            )
        }
    }
    mutating func visitTableGet(table: UInt32) throws(WasmKitError) -> Output {
        let type = try module.tableType(table)
        try popPushEmit(
            module.addressType(tableIndex: table),
            .ref(type.elementType)
        ) { index, result in
            return .tableGet(
                Instruction.TableGetOperand(
                    index: index,
                    result: result,
                    tableIndex: table
                )
            )
        }
    }
    mutating func visitTableSet(table: UInt32) throws(WasmKitError) -> Output {
        let type = try module.tableType(table)
        try pop2Emit((.ref(type.elementType), module.addressType(tableIndex: table))) { values, stack in
            let (value, index) = values
            return .tableSet(
                Instruction.TableSetOperand(
                    index: index,
                    value: value,
                    tableIndex: table
                )
            )
        }
    }
    mutating func visitTableGrow(table: UInt32) throws(WasmKitError) -> Output {
        let address = try module.addressType(tableIndex: table)
        let type = try module.tableType(table)
        try pop2PushEmit((address, .ref(type.elementType)), address) { values, result in
            let (delta, value) = values
            return .tableGrow(
                Instruction.TableGrowOperand(
                    tableIndex: table,
                    result: result,
                    delta: delta,
                    value: value
                )
            )
        }
    }
    mutating func visitTableSize(table: UInt32) throws(WasmKitError) -> Output {
        pushEmit(try module.addressType(tableIndex: table)) { result in
            return .tableSize(Instruction.TableSizeOperand(tableIndex: table, result: LVReg(result)))
        }
    }

    // MARK: - Atomic Operations Translation

    private mutating func visitRmw(
        _ memarg: MemArg,
        _ type: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.RmwOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let value = try popVRegOperand(type)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let value = value, let pointer = pointer else {
            throw WasmKitError("missing rmw operands")
        }
        let result = valueStack.push(type)
        let rmwOperand = Instruction.RmwOperand(
            offset: memarg.offset,
            pointer: pointer,
            value: value,
            result: result
        )
        emit(instruction(rmwOperand))
    }

    private mutating func visitRmw8(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.RmwOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let value = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let value = value, let pointer = pointer else {
            throw WasmKitError("missing rmw operands")
        }
        let result = valueStack.push(resultType)
        let rmwOperand = Instruction.RmwOperand(
            offset: memarg.offset,
            pointer: pointer,
            value: value,
            result: result
        )
        emit(instruction(rmwOperand))
    }

    private mutating func visitRmw16(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.RmwOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let value = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let value = value, let pointer = pointer else {
            throw WasmKitError("missing rmw operands")
        }
        let result = valueStack.push(resultType)
        let rmwOperand = Instruction.RmwOperand(
            offset: memarg.offset,
            pointer: pointer,
            value: value,
            result: result
        )
        emit(instruction(rmwOperand))
    }

    private mutating func visitRmw32(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.RmwOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let value = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let value = value, let pointer = pointer else {
            throw WasmKitError("missing rmw operands")
        }
        let result = valueStack.push(resultType)
        let rmwOperand = Instruction.RmwOperand(
            offset: memarg.offset,
            pointer: pointer,
            value: value,
            result: result
        )
        emit(instruction(rmwOperand))
    }

    mutating func visitI32AtomicRmwAdd(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwAdd($0) }
    }
    mutating func visitI64AtomicRmwAdd(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwAdd($0) }
    }
    mutating func visitI32AtomicRmw8AddU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8AddU($0) }
    }
    mutating func visitI32AtomicRmw16AddU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16AddU($0) }
    }
    mutating func visitI64AtomicRmw8AddU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8AddU($0) }
    }
    mutating func visitI64AtomicRmw16AddU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16AddU($0) }
    }
    mutating func visitI64AtomicRmw32AddU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32AddU($0) }
    }

    mutating func visitI32AtomicRmwSub(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwSub($0) }
    }
    mutating func visitI64AtomicRmwSub(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwSub($0) }
    }
    mutating func visitI32AtomicRmw8SubU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8SubU($0) }
    }
    mutating func visitI32AtomicRmw16SubU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16SubU($0) }
    }
    mutating func visitI64AtomicRmw8SubU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8SubU($0) }
    }
    mutating func visitI64AtomicRmw16SubU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16SubU($0) }
    }
    mutating func visitI64AtomicRmw32SubU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32SubU($0) }
    }

    mutating func visitI32AtomicRmwAnd(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwAnd($0) }
    }
    mutating func visitI64AtomicRmwAnd(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwAnd($0) }
    }
    mutating func visitI32AtomicRmw8AndU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8AndU($0) }
    }
    mutating func visitI32AtomicRmw16AndU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16AndU($0) }
    }
    mutating func visitI64AtomicRmw8AndU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8AndU($0) }
    }
    mutating func visitI64AtomicRmw16AndU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16AndU($0) }
    }
    mutating func visitI64AtomicRmw32AndU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32AndU($0) }
    }

    mutating func visitI32AtomicRmwOr(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwOr($0) }
    }
    mutating func visitI64AtomicRmwOr(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwOr($0) }
    }
    mutating func visitI32AtomicRmw8OrU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8OrU($0) }
    }
    mutating func visitI32AtomicRmw16OrU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16OrU($0) }
    }
    mutating func visitI64AtomicRmw8OrU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8OrU($0) }
    }
    mutating func visitI64AtomicRmw16OrU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16OrU($0) }
    }
    mutating func visitI64AtomicRmw32OrU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32OrU($0) }
    }

    mutating func visitI32AtomicRmwXor(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwXor($0) }
    }
    mutating func visitI64AtomicRmwXor(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwXor($0) }
    }
    mutating func visitI32AtomicRmw8XorU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8XorU($0) }
    }
    mutating func visitI32AtomicRmw16XorU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16XorU($0) }
    }
    mutating func visitI64AtomicRmw8XorU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8XorU($0) }
    }
    mutating func visitI64AtomicRmw16XorU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16XorU($0) }
    }
    mutating func visitI64AtomicRmw32XorU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32XorU($0) }
    }

    mutating func visitI32AtomicRmwXchg(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i32, 4) { .i32AtomicRmwXchg($0) }
    }
    mutating func visitI64AtomicRmwXchg(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw(memarg, .i64, 8) { .i64AtomicRmwXchg($0) }
    }
    mutating func visitI32AtomicRmw8XchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i32, 1) { .i32AtomicRmw8XchgU($0) }
    }
    mutating func visitI32AtomicRmw16XchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i32, 2) { .i32AtomicRmw16XchgU($0) }
    }
    mutating func visitI64AtomicRmw8XchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw8(memarg, .i64, 1) { .i64AtomicRmw8XchgU($0) }
    }
    mutating func visitI64AtomicRmw16XchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw16(memarg, .i64, 2) { .i64AtomicRmw16XchgU($0) }
    }
    mutating func visitI64AtomicRmw32XchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitRmw32(memarg, .i64, 4) { .i64AtomicRmw32XchgU($0) }
    }

    private mutating func visitCmpxchg(
        _ memarg: MemArg,
        _ type: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.CmpxchgOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let replacement = try popVRegOperand(type)
        let expected = try popVRegOperand(type)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let replacement = replacement, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing cmpxchg operands")
        }
        let result = valueStack.push(type)
        let cmpxchgOperand = Instruction.CmpxchgOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            replacement: replacement,
            result: result
        )
        emit(instruction(cmpxchgOperand))
    }

    private mutating func visitCmpxchg8(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.CmpxchgOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let replacement = try popVRegOperand(resultType)
        let expected = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let replacement = replacement, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing cmpxchg operands")
        }
        let result = valueStack.push(resultType)
        let cmpxchgOperand = Instruction.CmpxchgOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            replacement: replacement,
            result: result
        )
        emit(instruction(cmpxchgOperand))
    }

    private mutating func visitCmpxchg16(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.CmpxchgOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let replacement = try popVRegOperand(resultType)
        let expected = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let replacement = replacement, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing cmpxchg operands")
        }
        let result = valueStack.push(resultType)
        let cmpxchgOperand = Instruction.CmpxchgOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            replacement: replacement,
            result: result
        )
        emit(instruction(cmpxchgOperand))
    }

    private mutating func visitCmpxchg32(
        _ memarg: MemArg,
        _ resultType: ValueType,
        _ naturalAlignment: Int,
        _ instruction: @escaping (Instruction.CmpxchgOperand) -> Instruction
    ) throws(WasmKitError) {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: naturalAlignment)
        let replacement = try popVRegOperand(resultType)
        let expected = try popVRegOperand(resultType)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let replacement = replacement, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing cmpxchg operands")
        }
        let result = valueStack.push(resultType)
        let cmpxchgOperand = Instruction.CmpxchgOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            replacement: replacement,
            result: result
        )
        emit(instruction(cmpxchgOperand))
    }

    mutating func visitI32AtomicRmwCmpxchg(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg(memarg, .i32, 4) { .i32AtomicRmwCmpxchg($0) }
    }
    mutating func visitI64AtomicRmwCmpxchg(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg(memarg, .i64, 8) { .i64AtomicRmwCmpxchg($0) }
    }
    mutating func visitI32AtomicRmw8CmpxchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg8(memarg, .i32, 1) { .i32AtomicRmw8CmpxchgU($0) }
    }
    mutating func visitI32AtomicRmw16CmpxchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg16(memarg, .i32, 2) { .i32AtomicRmw16CmpxchgU($0) }
    }
    mutating func visitI64AtomicRmw8CmpxchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg8(memarg, .i64, 1) { .i64AtomicRmw8CmpxchgU($0) }
    }
    mutating func visitI64AtomicRmw16CmpxchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg16(memarg, .i64, 2) { .i64AtomicRmw16CmpxchgU($0) }
    }
    mutating func visitI64AtomicRmw32CmpxchgU(memarg: MemArg) throws(WasmKitError) -> Output {
        try visitCmpxchg32(memarg, .i64, 4) { .i64AtomicRmw32CmpxchgU($0) }
    }

    mutating func visitMemoryAtomicWait32(memarg: MemArg) throws(WasmKitError) -> Output {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: 4)
        let timeout = try popVRegOperand(.i64)
        let expected = try popVRegOperand(.i32)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let timeout = timeout, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing wait operands")
        }
        let result = valueStack.push(.i32)
        let waitOperand = Instruction.AtomicWaitOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            timeout: timeout,
            result: result
        )
        emit(.memoryAtomicWait32(waitOperand))
    }

    mutating func visitMemoryAtomicWait64(memarg: MemArg) throws(WasmKitError) -> Output {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: 8)
        let timeout = try popVRegOperand(.i64)
        let expected = try popVRegOperand(.i64)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let timeout = timeout, let expected = expected, let pointer = pointer else {
            throw WasmKitError("missing wait operands")
        }
        let result = valueStack.push(.i32)
        let waitOperand = Instruction.AtomicWaitOperand(
            offset: memarg.offset,
            pointer: pointer,
            expected: expected,
            timeout: timeout,
            result: result
        )
        emit(.memoryAtomicWait64(waitOperand))
    }

    mutating func visitMemoryAtomicNotify(memarg: MemArg) throws(WasmKitError) -> Output {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        try validator.validateMemArg(memarg, naturalAlignment: 4)
        let count = try popVRegOperand(.i32)
        let pointer = try popVRegOperand(.address(isMemory64: isMemory64))
        guard let count = count, let pointer = pointer else {
            throw WasmKitError("missing notify operands")
        }
        let result = valueStack.push(.i32)
        let notifyOperand = Instruction.AtomicNotifyOperand(
            offset: memarg.offset,
            pointer: pointer,
            count: count,
            result: result
        )
        emit(.memoryAtomicNotify(notifyOperand))
    }

    mutating func visitAtomicFence() throws(WasmKitError) -> Output {
        emit(.atomicFence(.init()))
    }
}

extension InstructionTranslator.MetaValue {
    fileprivate var concreteType: WasmTypes.ValueType? {
        switch self {
        case .some(let type): return type
        case .unknown: return nil
        }
    }
}

extension FunctionType {
    /// A branch out of a block copies the block's values, and
    /// ``ControlFrame/copySlotCount`` counts those slots in a `UInt16`.
    func checkFitsInterpreter() throws(WasmKitError) {
        let parameterSlots = parameters.reduce(into: 0) { $0 += $1.stackSlotCount }
        guard parameterSlots <= Int(UInt16.max) else {
            throw WasmKitError(message: .blockTypeTooLargeForInterpreter("parameters", slots: parameterSlots))
        }
        let resultSlots = results.reduce(into: 0) { $0 += $1.stackSlotCount }
        guard resultSlots <= Int(UInt16.max) else {
            throw WasmKitError(message: .blockTypeTooLargeForInterpreter("results", slots: resultSlots))
        }
    }

    fileprivate init(blockType: WasmParser.BlockType, typeSection: [FunctionType]) throws(WasmKitError) {
        switch blockType {
        case .type(let valueType):
            self.init(parameters: [], results: [valueType])
        case .empty:
            self.init(parameters: [], results: [])
        case .funcType(let typeIndex):
            let typeIndex = Int(typeIndex)
            guard typeIndex < typeSection.count else {
                throw WasmKitError(message: .indexOutOfBounds("type", typeIndex, max: typeSection.count))
            }
            let funcType = typeSection[typeIndex]
            self.init(
                parameters: funcType.parameters,
                results: funcType.results
            )
        }
        try checkFitsInterpreter()
    }
}

extension ValueType {
    fileprivate static func address(isMemory64: Bool) -> ValueType {
        return isMemory64 ? .i64 : .i32
    }
}
