import WasmParser

/// A register value that is pre-shifted to avoid runtime shift operation.
protocol ShiftedVReg {
    associatedtype Storage: FixedWidthInteger

    /// The value of the shifted register.
    /// Must be a multiple of `MemoryLayout<StackSlot>.size`.
    var value: Storage { get }
}

/// A register that is used to store a value in the stack.
///
/// The stored representation is the **byte** offset of the slot from `sp`
/// (`slotIndex * MemoryLayout<StackSlot>.size`), not the raw slot index, so a
/// handler can address a 32-bit operand with a plain register offset. On arm64
/// a 32-bit load cannot scale its index by 8, so a slot index would need an
/// `lsl #3` before every such `ldr w`. ``LVReg`` and ``LLVReg`` use the same
/// convention with a wider storage.
///
/// Pre-shifting costs three bits of range: an `Int16` byte offset addresses
/// slots ``minSlotIndex``...``maxSlotIndex`` (-4096...4095). The translator
/// rejects a function whose frame does not fit (see
/// `InstructionTranslator.checkFrameFitsVRegRange`).
struct VReg: Equatable, Hashable, ShiftedVReg, CustomStringConvertible {
    /// The pre-shifted byte offset from `sp`. Always a multiple of
    /// `MemoryLayout<StackSlot>.size`.
    let value: Int16

    /// The size, in bytes, of a single stack slot.
    @inline(__always)
    static var slotSize: Int16 { Int16(MemoryLayout<StackSlot>.size) }

    /// The lowest slot index representable as a pre-shifted `Int16` byte offset.
    static var minSlotIndex: Int { Int(Int16.min) / Int(MemoryLayout<StackSlot>.size) }
    /// The highest slot index representable as a pre-shifted `Int16` byte offset.
    static var maxSlotIndex: Int { Int(Int16.max) / Int(MemoryLayout<StackSlot>.size) }

    /// Whether `slotIndex` can be represented without truncation.
    @inline(__always)
    static func canRepresent(slotIndex: Int) -> Bool {
        minSlotIndex <= slotIndex && slotIndex <= maxSlotIndex
    }

    /// Creates a register from a slot index relative to `sp`.
    ///
    /// - Note: Out-of-range indices wrap rather than trap. The translator
    ///   validates the whole frame extent once, before the instruction sequence
    ///   it built can be executed (`InstructionTranslator.checkFrameFitsVRegRange`), so a
    ///   function with an unrepresentable frame is rejected as a whole instead of
    ///   crashing part-way through translation.
    @inline(__always)
    init(slotIndex: Int) {
        self.value = Int16(truncatingIfNeeded: slotIndex) &* Self.slotSize
    }

    /// Creates a register from an already pre-shifted byte offset.
    @inline(__always)
    init(byteOffset: Int16) {
        self.value = byteOffset
    }

    /// The slot index this register addresses.
    @inline(__always)
    var slotIndex: Int16 { value / Self.slotSize }

    /// The byte offset from `sp` this register addresses.
    @inline(__always)
    var byteOffset: Int16 { value }

    /// The register of the slot right after this one, used by `v128` operands,
    /// which occupy two consecutive slots.
    @inline(__always)
    var nextSlot: VReg { VReg(byteOffset: value &+ Self.slotSize) }

    /// The register at slot index zero, i.e. `sp` itself.
    static let zero = VReg(byteOffset: 0)

    /// Slot-index arithmetic. Byte offsets scale linearly with slot indices, so
    /// these are the same operations on either representation.
    @inline(__always)
    static func + (lhs: VReg, rhs: VReg) -> VReg { VReg(byteOffset: lhs.value &+ rhs.value) }
    @inline(__always)
    static func - (lhs: VReg, rhs: VReg) -> VReg { VReg(byteOffset: lhs.value &- rhs.value) }
    @inline(__always)
    static func += (lhs: inout VReg, rhs: VReg) { lhs = lhs + rhs }
    @inline(__always)
    static prefix func - (operand: VReg) -> VReg { VReg(byteOffset: 0 &- operand.value) }

    var description: String { "\(slotIndex)" }
}

/// A larger (32-bit) version of `VReg`
/// Used to utilize halfword loads instructions.
struct LVReg: Equatable, ShiftedVReg, CustomStringConvertible {
    let value: Int32

    init(_ reg: VReg) {
        // `VReg` is already pre-shifted; just widen it.
        self.value = Int32(reg.byteOffset)
    }

    init(storage: Int32) {
        self.value = storage
    }

    /// The register at slot index zero, i.e. `sp` itself.
    static let zero = LVReg(storage: 0)

    var description: String {
        "\(value / Int32(MemoryLayout<StackSlot>.size))"
    }
}

/// A larger (64-bit) version of `VReg`
/// Used to utilize word loads instructions.
struct LLVReg: Equatable, ShiftedVReg, CustomStringConvertible {
    let value: Int64

    init(_ reg: VReg) {
        // `VReg` is already pre-shifted; just widen it.
        self.value = Int64(reg.byteOffset)
    }

    init(storage: Int64) {
        self.value = storage
    }

    /// The register at slot index zero, i.e. `sp` itself.
    static let zero = LLVReg(storage: 0)

    var description: String {
        "\(value / Int64(MemoryLayout<StackSlot>.size))"
    }
}

// MARK: - Immediate load/emit support

/// A protocol that represents an immediate associated with an instruction.
protocol InstructionImmediate {
    /// Loads an immediate from the instruction sequence.
    ///
    /// - Parameter pc: The program counter to read from.
    /// - Returns: The loaded immediate.
    static func load(from pc: inout Pc) -> Self

    /// Emits the layout of the immediate to be emitted.
    ///
    /// - Parameter emitSlot: The closure to schedule a slot emission.
    ///             This closure receives a builder closure that builds the slot.
    ///
    /// - Note: This method is intended to work at meta-level to allow
    ///         knowing the size of slots without actual immediate values.
    static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void)
}

extension InstructionImmediate {
    /// Emits the immediate value
    ///
    /// - Parameter emitSlot: The closure to emit a slot.
    func emit(to emitSlot: @escaping (CodeSlot) -> Void) {
        Self.emit { buildCodeSlot in
            emitSlot(buildCodeSlot(self))
        }
    }
}

extension UInt32: InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        UInt32(pc.read(UInt64.self))
    }
    static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
        emitSlot { CodeSlot($0) }
    }
}

extension Int32: InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        Int32(bitPattern: UInt32(pc.read(UInt64.self)))
    }
    static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
        emitSlot { CodeSlot(UInt32(bitPattern: $0)) }
    }
}

// MARK: - Immediate type extensions

extension Instruction.RefNullOperand {
    init(result: VReg, type: AbstractHeapType) {
        self.init(result: result, rawType: type.rawValue)  // need to figure out rawType here
    }

    var type: AbstractHeapType {
        AbstractHeapType(rawValue: rawType).unsafelyUnwrapped
    }
}

extension Instruction.GlobalOperand {
    init(global: InternalGlobal) {
        self.init(rawGlobal: UInt64(UInt(bitPattern: global.bitPattern)))
    }
    var global: InternalGlobal {
        InternalGlobal(bitPattern: UInt(rawGlobal)).unsafelyUnwrapped
    }
}

extension Instruction.GlobalAndVRegOperand {
    init(reg: LLVReg, global: InternalGlobal) {
        self.init(reg: reg, rawGlobal: UInt64(UInt(bitPattern: global.bitPattern)))
    }
    var global: InternalGlobal {
        InternalGlobal(bitPattern: UInt(rawGlobal)).unsafelyUnwrapped
    }
    /// The second slot of a `v128` operand, which occupies two stack slots.
    var regHi: LLVReg {
        LLVReg(storage: reg.value &+ Int64(MemoryLayout<StackSlot>.size))
    }
}

extension Instruction.BrTableOperand {
    struct Entry {
        var offset: Int32
    }

    /// `count` includes the default entry, so it is never zero.
    init(baseAddress: UnsafePointer<Entry>, count: UInt16, index: VReg) {
        self.init(index: index, lastIndex: count - 1, rawBaseAddress: UInt64(UInt(bitPattern: baseAddress)))
    }

    var count: Int { Int(lastIndex) + 1 }

    var baseAddress: UnsafePointer<Entry> {
        UnsafePointer(bitPattern: UInt(rawBaseAddress)).unsafelyUnwrapped
    }
}

/// An entry in the catch table for a `try_table` block.
///
/// A Wasm `try_table` instruction declares inline catch clauses (`catch`, `catch_ref`,
/// `catch_all`, `catch_all_ref`). During translation, the translator compiles these clauses
/// into an array of `CatchTableEntry` values — the "catch table" — which is the runtime
/// representation used for exception dispatch.
///
/// The pipeline:
/// 1. **Parse**: `try_table` is decoded into a `TryCatch` with an array of `CatchClause` values.
/// 2. **Translate** (`visitTryTable`): Allocates a `CatchTableEntry` array, resolves tags to
///    `InternalTag` handles, computes `payloadRegBase`, and schedules `pcOffset` fixups for
///    when target labels are pinned. Catch clause label depths are resolved relative to the
///    *enclosing* scope (the `try_table`'s own label is not yet in scope), so clauses are
///    processed before pushing the `try_table` control frame.
/// 3. **Execute**: The `catchHandlers` instruction registers entries as `ExceptionHandler`
///    values on a handler stack. On `throw`, `handleException` walks the stack top-down to
///    find a matching handler (by tag identity, or `catch_all`), unwinds `sp`, writes the
///    exception payload into the target registers, and jumps to the handler `pc`.
///    `catchHandlersEnd` pops handlers when control exits the `try_table` normally or via branch.
struct CatchTableEntry {
    /// The tag to match, as a raw `InternalTag` bit pattern. `0` for `catch_all`/`catch_all_ref`.
    var rawTag: UInt64
    /// Non-zero if this is a `catch_all` or `catch_all_ref` clause.
    var isCatchAll: UInt8
    /// Non-zero if this is a `catch_ref` or `catch_all_ref` clause (pushes `exnref`).
    var isRef: UInt8
    /// `pc` offset from the `catchHandlers` instruction to the handler's target.
    var pcOffset: Int32
    /// Register offset where payload values should be written (relative to `sp`).
    var payloadRegBase: VReg

    init(tag: InternalTag?, isRef: Bool, pcOffset: Int32, payloadRegBase: VReg) {
        self.rawTag = tag.map { UInt64(UInt(bitPattern: $0.bitPattern)) } ?? 0
        self.isCatchAll = tag == nil ? 1 : 0
        self.isRef = isRef ? 1 : 0
        self.pcOffset = pcOffset
        self.payloadRegBase = payloadRegBase
    }

    var tag: InternalTag? {
        isCatchAll != 0 ? nil : InternalTag(bitPattern: UInt(rawTag))
    }
}

extension Instruction.CatchHandlersOperand {
    init(baseAddress: UnsafePointer<CatchTableEntry>, count: UInt16) {
        self.init(rawBaseAddress: UInt64(UInt(bitPattern: baseAddress)), count: count)
    }

    var baseAddress: UnsafePointer<CatchTableEntry> {
        UnsafePointer(bitPattern: UInt(rawBaseAddress)).unsafelyUnwrapped
    }
}

extension Instruction.CallOperand {
    init(callee: InternalFunction, spAddend: VReg) {
        self.init(rawCallee: UInt64(UInt(bitPattern: callee.bitPattern)), spAddend: spAddend)
    }

    var callee: InternalFunction {
        InternalFunction(bitPattern: Int(bitPattern: UInt(rawCallee)))
    }
}

extension Instruction.CallIndirectOperand {

    init(tableIndex: UInt32, type: InternedFuncType, index: VReg, spAddend: VReg) {
        self.init(tableIndex: tableIndex, rawType: type.id, index: index, spAddend: spAddend)
    }

    var type: InternedFuncType {
        InternedFuncType(id: rawType)
    }
}

extension Instruction.ReturnCallOperand {
    init(callee: InternalFunction) {
        self.init(rawCallee: UInt64(UInt(bitPattern: callee.bitPattern)))
    }

    var callee: InternalFunction {
        InternalFunction(bitPattern: Int(bitPattern: UInt(rawCallee)))
    }
}

extension Instruction.ReturnCallIndirectOperand {

    init(tableIndex: UInt32, type: InternedFuncType, index: VReg) {
        self.init(tableIndex: tableIndex, rawType: type.id, index: index)
    }

    var type: InternedFuncType {
        InternedFuncType(id: rawType)
    }
}

extension Instruction {
    typealias BrOperand = Int32
    typealias OnEnterOperand = FunctionIndex
    typealias OnExitOperand = FunctionIndex
}

extension RawUnsignedInteger {
    init(_ slot: CodeSlot, shiftWidth: Int) {
        let mask = CodeSlot(Self.max)
        let bitPattern = (slot >> shiftWidth) & mask
        self = Self(bitPattern)
    }

    func bits(shiftWidth: Int) -> CodeSlot {
        CodeSlot(self) << shiftWidth
    }
}

extension RawSignedInteger {
    init(_ slot: CodeSlot, shiftWidth: Int) {
        self.init(bitPattern: Unsigned(slot, shiftWidth: shiftWidth))
    }

    func bits(shiftWidth: Int) -> CodeSlot {
        Unsigned(bitPattern: self).bits(shiftWidth: shiftWidth)
    }
}

extension UntypedValue {
    init(_ slot: CodeSlot, shiftWidth: Int) {
        self.init(storage: slot)
    }

    func bits(shiftWidth: Int) -> CodeSlot { storage }
}

/// The type of an opcode identifier.
typealias OpcodeID = UInt64

extension Instruction {
    /// The code slot an emitted instruction starts with: the handler address
    /// under direct threading, the opcode ID under token threading.
    ///
    /// Outlined because the translator emits from many sites and each inlined
    /// copy would carry the opcode switch.
    @inline(never)
    func headSlot(threadingModel: EngineConfiguration.ThreadingModel) -> CodeSlot {
        headSlotInline(threadingModel: threadingModel)
    }

    /// ``headSlot(threadingModel:)`` for sites where the instruction is a known
    /// case and the result folds to a constant.
    @inline(__always)
    func headSlotInline(threadingModel: EngineConfiguration.ThreadingModel) -> CodeSlot {
        let opcodeID = self.opcodeID
        switch threadingModel {
        case .direct:
            return CodeSlot(Instruction.handler(opcodeID: opcodeID))
        case .token:
            return opcodeID
        }
    }

    /// The opcode whose handler `slot`, the first slot of an emitted instruction, dispatches to.
    ///
    /// Takes the slot's value rather than its address, so that a caller can pass the head slot a
    /// breakpoint replaced. Opcodes sharing a direct-threaded handler (see `handlerIdentity` in
    /// VMSpec) come back as the first of them, which runs the same body.
    static func opcode(ofHeadSlot slot: CodeSlot, threadingModel: EngineConfiguration.ThreadingModel) -> OpcodeID {
        switch threadingModel {
        case .direct:
            guard let opcode = directHeadSlotOpcodes[slot] else {
                preconditionFailure("Not a direct-threaded head slot: \(slot)")
            }
            return opcode
        case .token:
            return slot
        }
    }

    /// Reverse of ``handler(opcodeID:)``, built on first use.
    private static let directHeadSlotOpcodes: [CodeSlot: OpcodeID] = {
        var opcodes = [CodeSlot: OpcodeID]()
        // Downward, so that the first opcode sharing a handler is the one left in the map.
        for opcode in (0..<OpcodeID(opcodeCount)).reversed() {
            opcodes[CodeSlot(handler(opcodeID: opcode))] = opcode
        }
        return opcodes
    }()
}

// MARK: - Instruction printing support

#if Disassembler
    extension InstructionSequence {
        func write<Target>(to target: inout Target, context: inout InstructionPrintingContext) where Target: TextOutputStream {
            var hexOffsetWidth = String(instructions.count - 1, radix: 16).count
            hexOffsetWidth = (hexOffsetWidth + 1) & ~1

            guard let cursorStart = instructions.baseAddress else { return }
            let cursorEnd = cursorStart.advanced(by: instructions.count)
            let threadingModel = context.function.store.engine.configuration.threadingModel

            var cursor = cursorStart
            while cursor < cursorEnd {
                let index = cursor - cursorStart
                var hexOffset = String(index, radix: 16)
                while hexOffset.count < hexOffsetWidth {
                    hexOffset = "0" + hexOffset
                }
                target.write("0x\(hexOffset): ")
                let instruction = Instruction.load(from: &cursor, threadingModel: threadingModel)
                context.print(
                    instruction: instruction,
                    instructionOffset: cursor - cursorStart,
                    to: &target
                )
                target.write("\n")
            }
        }
    }

    struct InstructionPrintingContext {
        let shouldColor: Bool
        let function: Function
        var nameRegistry: NameRegistry

        func reg<R: FixedWidthInteger>(_ reg: R) -> String {
            let adjusted = R(FrameHeaderLayout.size(of: function.type)) + reg
            if shouldColor {
                let regColor = adjusted < 15 ? "\u{001B}[3\(adjusted + 1)m" : ""
                return "\(regColor)reg:\(reg)\u{001B}[0m"
            } else {
                return "reg:\(reg)"
            }
        }
        func reg<R: ShiftedVReg>(_ x: R) -> String { reg(Int(x.value) / MemoryLayout<StackSlot>.size) }

        func offset(_ offset: UInt64) -> String {
            "offset: \(offset)"
        }

        func branchTarget(_ instructionOffset: Int, _ offset: Int) -> String {
            let iseqOffset = instructionOffset + offset
            return "\(offset > 0 ? "+" : "")\(offset) ; 0x\(String(iseqOffset, radix: 16))"
        }

        mutating func callee(_ callee: InternalFunction) -> String {
            return "'" + nameRegistry.symbolicate(callee) + "'"
        }

        func hex<T: BinaryInteger>(_ value: T) -> String {
            let hex = String(value, radix: 16)
            return "0x\(String(repeating: "0", count: 16 - hex.count) + hex)"
        }

        func global(_ global: InternalGlobal) -> String {
            "global:\(hex(global.bitPattern))"
        }

        func value(_ value: UntypedValue) -> String {
            "untyped:\(hex(value.storage))"
        }

        /// Compiled for size: one arm per opcode, used only for disassembly.
        @_optimize(size)
        mutating func print<Target>(
            instruction: Instruction,
            instructionOffset: Int,
            to target: inout Target
        ) where Target: TextOutputStream {
            // Local helpers capture only what they need, so rendering a
            // register does not retain the whole context.
            let frameHeaderSize = FrameHeaderLayout.size(of: function.type)
            let shouldColor = self.shouldColor
            func regCore(_ reg: Int) -> String {
                let adjusted = frameHeaderSize + reg
                if shouldColor {
                    let regColor = adjusted < 15 ? "\u{001B}[3\(adjusted + 1)m" : ""
                    return "\(regColor)reg:\(reg)\u{001B}[0m"
                } else {
                    return "reg:\(reg)"
                }
            }
            @inline(__always) func reg<R: FixedWidthInteger>(_ reg: R) -> String { regCore(Int(reg)) }
            @inline(__always) func reg<R: ShiftedVReg>(_ x: R) -> String { reg(Int(x.value) / MemoryLayout<StackSlot>.size) }

            func binop(_ name: String, _ op: Instruction.BinaryOperand) {
                target.write("\(reg(op.result)) = \(name) \(reg(op.lhs)), \(reg(op.rhs))")
            }
            func unop(_ name: String, _ op: Instruction.UnaryOperand) {
                target.write("\(reg(op.result)) = \(name) \(reg(op.input))")
            }
            func load(_ name: String, _ op: Instruction.LoadOperand) {
                target.write("\(reg(op.result)) = \(name) \(reg(op.pointer)), \(offset(op.offset))")
            }
            func store(_ name: String, _ op: Instruction.StoreOperand) {
                target.write("\(name) \(reg(op.pointer)) + \(offset(op.offset)), \(reg(op.value))")
            }
            func binBin(_ name: String, _ op: Instruction.BinBinOperand) {
                target.write("\(reg(op.result)) = \(name) \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            }
            func loadToAcc(_ name: String, _ op: Instruction.AccMemoryPointerOperand) {
                target.write("acc = \(name) \(reg(op.pointer)), \(offset(UInt64(op.offset)))")
            }
            func loadFromAcc(_ name: String, _ op: Instruction.AccMemoryResultOperand) {
                target.write("\(reg(op.result)) = \(name) acc, \(offset(UInt64(op.offset)))")
            }
            func loadInAcc(_ name: String, _ op: Instruction.AccMemoryOffsetOperand) {
                target.write("acc = \(name) acc, \(offset(UInt64(op.offset)))")
            }
            func storeFromAcc(_ name: String, _ op: Instruction.AccMemoryPointerOperand) {
                target.write("\(name) \(reg(op.pointer)) + \(offset(UInt64(op.offset))), acc")
            }
            func storeAddrFromAcc(_ name: String, _ op: Instruction.AccMemoryValueOperand) {
                target.write("\(name) acc + \(offset(UInt64(op.offset))), \(reg(op.value))")
            }
            func toAccAndSlot(_ name: String, _ op: Instruction.BinaryOperand) {
                target.write("\(reg(op.result)) = acc = \(name) \(reg(op.lhs)), \(reg(op.rhs))")
            }
            func immToAccAndSlot(_ name: String, _ op: Instruction.BinaryImmOperand) {
                target.write("\(reg(op.result)) = acc = \(name) \(reg(op.lhs)), #\(op.imm)")
            }
            func loadToAccAndSlot(_ name: String, _ op: Instruction.AccMemoryPointerResultOperand) {
                target.write("\(reg(op.result)) = acc = \(name) \(reg(op.pointer)), \(offset(UInt64(op.offset)))")
            }
            func toAcc(_ name: String, _ op: Instruction.AccBinaryOperand) {
                target.write("acc = \(name) \(reg(op.lhs)), \(reg(op.rhs))")
            }
            func fromAcc(_ name: String, _ op: Instruction.AccUnaryOperand) {
                target.write("\(reg(op.result)) = \(name) acc, \(reg(op.operand))")
            }
            func inAcc(_ name: String, _ op: Instruction.AccOperand) {
                target.write("acc = \(name) acc, \(reg(op.operand))")
            }
            func brIfAccCmp(_ name: String, _ op: Instruction.BrIfAccCmpOperand) {
                target.write("br_if.\(name) acc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            }
            func binBinRev(_ name: String, _ op: Instruction.BinBinOperand) {
                target.write("\(reg(op.result)) = \(name) \(reg(op.z)), (\(reg(op.x)), \(reg(op.y)))")
            }
            func brIfCmp(_ name: String, _ op: Instruction.BrIfCmpOperand) {
                target.write("br_if.\(name) \(reg(op.lhs)), \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            }
            func loadWithCopy(_ name: String, _ op: Instruction.LoadWithCopyOperand) {
                target.write("\(reg(op.copyDest)) = copy \(reg(op.pointer)); \(reg(op.result)) = \(name) \(reg(op.pointer)), offset: \(op.offset)")
            }
            switch instruction {
            case .unreachable:
                target.write("unreachable")
            case .nop:
                target.write("nop")
            case .copyStack(let op):
                target.write("\(reg(op.dest)) = copy \(reg(op.source))")
            case .copyStack2(let op):
                target.write("\(reg(op.dest0)) = copy \(reg(op.source0)); \(reg(op.dest1)) = copy \(reg(op.source1))")
            case .i32LoadWithCopy(let op): loadWithCopy("i32.load", op)
            case .i64LoadWithCopy(let op): loadWithCopy("i64.load", op)
            case .f32LoadWithCopy(let op): loadWithCopy("f32.load", op)
            case .f64LoadWithCopy(let op): loadWithCopy("f64.load", op)
            case .i32Load8SWithCopy(let op): loadWithCopy("i32.load8_s", op)
            case .i32Load8UWithCopy(let op): loadWithCopy("i32.load8_u", op)
            case .i32Load16SWithCopy(let op): loadWithCopy("i32.load16_s", op)
            case .i32Load16UWithCopy(let op): loadWithCopy("i32.load16_u", op)
            case .i64Load8SWithCopy(let op): loadWithCopy("i64.load8_s", op)
            case .i64Load8UWithCopy(let op): loadWithCopy("i64.load8_u", op)
            case .i64Load16SWithCopy(let op): loadWithCopy("i64.load16_s", op)
            case .i64Load16UWithCopy(let op): loadWithCopy("i64.load16_u", op)
            case .i64Load32SWithCopy(let op): loadWithCopy("i64.load32_s", op)
            case .i64Load32UWithCopy(let op): loadWithCopy("i64.load32_u", op)
            case .selectAcc(let op):
                target.write("\(reg(op.result)) = select acc, \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32Eq(let op):
                target.write("\(reg(op.result)) = select.i32.eq \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32LtS(let op):
                target.write("\(reg(op.result)) = select.i32.lt_s \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32LtU(let op):
                target.write("\(reg(op.result)) = select.i32.lt_u \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32EqImm(let op):
                target.write("\(reg(op.result)) = select.i32.eq \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32LtSImm(let op):
                target.write("\(reg(op.result)) = select.i32.lt_s \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32LtUImm(let op):
                target.write("\(reg(op.result)) = select.i32.lt_u \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32GtSImm(let op):
                target.write("\(reg(op.result)) = select.i32.gt_s \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI32GtUImm(let op):
                target.write("\(reg(op.result)) = select.i32.gt_u \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64Eq(let op):
                target.write("\(reg(op.result)) = select.i64.eq \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64LtS(let op):
                target.write("\(reg(op.result)) = select.i64.lt_s \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64LtU(let op):
                target.write("\(reg(op.result)) = select.i64.lt_u \(reg(op.lhs)), \(reg(op.rhs)), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64EqImm(let op):
                target.write("\(reg(op.result)) = select.i64.eq \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64LtSImm(let op):
                target.write("\(reg(op.result)) = select.i64.lt_s \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64LtUImm(let op):
                target.write("\(reg(op.result)) = select.i64.lt_u \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64GtSImm(let op):
                target.write("\(reg(op.result)) = select.i64.gt_s \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .selectI64GtUImm(let op):
                target.write("\(reg(op.result)) = select.i64.gt_u \(reg(op.lhs)), #\(op.imm), \(reg(op.onTrue)), \(reg(op.onFalse))")
            case .copyStackAccToSlot(let op):
                target.write("\(reg(op.dest)) = copy \(reg(op.source)); \(reg(op.result)) = acc")
            case .globalGet(let op):
                target.write("\(reg(op.reg)) = global.get \(global(op.global))")
            case .globalSet(let op):
                target.write("global.set \(global(op.global)), \(reg(op.reg))")
            case .globalGetV128(let op):
                target.write("\(reg(op.reg)) = global.get.v128 \(global(op.global))")
            case .globalSetV128(let op):
                target.write("global.set.v128 \(global(op.global)), \(reg(op.reg))")
            case .const32(let op):
                target.write("\(reg(op.result)) = \(hex(op.value))")
            case .v128Const(let op):
                target.write("\(reg(op.result)) = v128.const lo:\(hex(op.lo)) hi:\(hex(op.hi))")
            case .call(let op):
                target.write("call \(callee(op.callee)), sp: +\(op.spAddend)")
            case .callIndirect(let op):
                target.write("call_indirect \(reg(op.index)), \(op.tableIndex), (func_ty id:\(op.type.id)), sp: +\(op.spAddend)")
            case .compilingCall(let op):
                target.write("compiling_call \(callee(op.callee)), sp: +\(op.spAddend)")
            case .returnCall(let op):
                target.write("return_call \(callee(op.callee))")
            case .i32Load(let op): load("i32.load", op)
            case .i64Load(let op): load("i64.load", op)
            case .f32Load(let op): load("f32.load", op)
            case .f64Load(let op): load("f64.load", op)
            case .i8x16Shuffle(let op):
                let lanes = [
                    op.lane0, op.lane1, op.lane2, op.lane3,
                    op.lane4, op.lane5, op.lane6, op.lane7,
                    op.lane8, op.lane9, op.lane10, op.lane11,
                    op.lane12, op.lane13, op.lane14, op.lane15,
                ]
                target.write("\(reg(op.result)) = i8x16.shuffle \(reg(op.lhs)), \(reg(op.rhs)), \(lanes)")
            case .simd(let op):
                let name = SIMDOpcode(rawValue: op.opcode).map { "\($0)" } ?? "unknown(\(op.opcode))"
                target.write("\(reg(op.result)) = simd.\(name) lane:\(op.lane) \(reg(op.input0)), \(reg(op.input1)), \(reg(op.input2)) offset:\(offset(op.offset))")
            case .i32Add(let op): binop("i32.add", op)
            case .i32Sub(let op): binop("i32.sub", op)
            case .i32Mul(let op): binop("i32.mul", op)
            case .i32DivS(let op): binop("i32.div_s", op)
            case .i32RemS(let op): binop("i32.rem_s", op)
            case .i32And(let op): binop("i32.and", op)
            case .i32Or(let op): binop("i32.or", op)
            case .i32Xor(let op): binop("i32.xor", op)
            case .i32Shl(let op): binop("i32.shl", op)
            case .i32ShrS(let op): binop("i32.shr_s", op)
            case .i32ShrU(let op): binop("i32.shr_u", op)
            case .i32Rotl(let op): binop("i32.rotl", op)
            case .i32Rotr(let op): binop("i32.rotr", op)
            case .i32LtU(let op): binop("i32.lt_u", op)
            case .i32GeU(let op): binop("i32.ge_u", op)
            case .i32Eq(let op): binop("i32.eq", op)
            case .i32Eqz(let op): unop("i32.eqz", op)
            case .i64Add(let op): binop("i64.add", op)
            case .i64Sub(let op): binop("i64.sub", op)
            case .i64Mul(let op): binop("i64.mul", op)
            case .i64DivS(let op): binop("i64.div_s", op)
            case .i64RemS(let op): binop("i64.rem_s", op)
            case .i64And(let op): binop("i64.and", op)
            case .i64Or(let op): binop("i64.or", op)
            case .i64Xor(let op): binop("i64.xor", op)
            case .i64Shl(let op): binop("i64.shl", op)
            case .i64ShrS(let op): binop("i64.shr_s", op)
            case .i64ShrU(let op): binop("i64.shr_u", op)
            case .i64Eq(let op): binop("i64.eq", op)
            case .i64Eqz(let op): unop("i64.eqz", op)
            case .i32Store(let op): store("i32.store", op)
            case .brIfNot(let op):
                target.write("br_if_not \(reg(op.condition)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIf(let op):
                target.write("br_if \(reg(op.condition)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32Eq(let op): brIfCmp("i32.eq", op)
            case .brIfI32Ne(let op): brIfCmp("i32.ne", op)
            case .brIfI32LtS(let op): brIfCmp("i32.lt_s", op)
            case .brIfI32LtU(let op): brIfCmp("i32.lt_u", op)
            case .brIfI32GtS(let op): brIfCmp("i32.gt_s", op)
            case .brIfI32GtU(let op): brIfCmp("i32.gt_u", op)
            case .brIfI32LeS(let op): brIfCmp("i32.le_s", op)
            case .brIfI32LeU(let op): brIfCmp("i32.le_u", op)
            case .brIfI32GeS(let op): brIfCmp("i32.ge_s", op)
            case .brIfI32GeU(let op): brIfCmp("i32.ge_u", op)
            case .brIfI64Eq(let op): brIfCmp("i64.eq", op)
            case .brIfI64Ne(let op): brIfCmp("i64.ne", op)
            case .brIfI64LtS(let op): brIfCmp("i64.lt_s", op)
            case .brIfI64LtU(let op): brIfCmp("i64.lt_u", op)
            case .brIfI64GtS(let op): brIfCmp("i64.gt_s", op)
            case .brIfI64GtU(let op): brIfCmp("i64.gt_u", op)
            case .brIfI64LeS(let op): brIfCmp("i64.le_s", op)
            case .brIfI64LeU(let op): brIfCmp("i64.le_u", op)
            case .brIfI64GeS(let op): brIfCmp("i64.ge_s", op)
            case .brIfI64GeU(let op): brIfCmp("i64.ge_u", op)
            case .brIfF32Eq(let op): brIfCmp("f32.eq", op)
            case .brIfF32Ne(let op): brIfCmp("f32.ne", op)
            case .brIfF32Lt(let op): brIfCmp("f32.lt", op)
            case .brIfF32Le(let op): brIfCmp("f32.le", op)
            case .brIfNotF32Lt(let op): brIfCmp("not.f32.lt", op)
            case .brIfNotF32Le(let op): brIfCmp("not.f32.le", op)
            case .brIfF64Eq(let op): brIfCmp("f64.eq", op)
            case .brIfF64Ne(let op): brIfCmp("f64.ne", op)
            case .brIfF64Lt(let op): brIfCmp("f64.lt", op)
            case .brIfF64Le(let op): brIfCmp("f64.le", op)
            case .brIfNotF64Lt(let op): brIfCmp("not.f64.lt", op)
            case .brIfNotF64Le(let op): brIfCmp("not.f64.le", op)
            case .brIfI32And(let op): brIfCmp("i32.and", op)
            case .brIfNotI32And(let op): brIfCmp("not.i32.and", op)
            case .brIfI64And(let op): brIfCmp("i64.and", op)
            case .brIfNotI64And(let op): brIfCmp("not.i64.and", op)
            case .f32AddAdd(let op): binBin("f32.add.add", op)
            case .f32AddSub(let op): binBin("f32.add.sub", op)
            case .f32AddMul(let op): binBin("f32.add.mul", op)
            case .f32SubAdd(let op): binBin("f32.sub.add", op)
            case .f32SubSub(let op): binBin("f32.sub.sub", op)
            case .f32SubMul(let op): binBin("f32.sub.mul", op)
            case .f32MulAdd(let op): binBin("f32.mul.add", op)
            case .f32MulSub(let op): binBin("f32.mul.sub", op)
            case .f32MulMul(let op): binBin("f32.mul.mul", op)
            case .f64AddAdd(let op): binBin("f64.add.add", op)
            case .f64AddSub(let op): binBin("f64.add.sub", op)
            case .f64AddMul(let op): binBin("f64.add.mul", op)
            case .f64SubAdd(let op): binBin("f64.sub.add", op)
            case .f64SubSub(let op): binBin("f64.sub.sub", op)
            case .f64SubMul(let op): binBin("f64.sub.mul", op)
            case .f64MulAdd(let op): binBin("f64.mul.add", op)
            case .f64MulSub(let op): binBin("f64.mul.sub", op)
            case .f64MulMul(let op): binBin("f64.mul.mul", op)
            case .i32ShlAdd(let op): binBin("i32.shl.add", op)
            case .i32MulAdd(let op): binBin("i32.mul.add", op)
            case .i32AddAdd(let op): binBin("i32.add.add", op)
            case .i32AndAdd(let op): binBin("i32.and.add", op)
            case .i32ShrUAnd(let op): binBin("i32.shr_u.and", op)
            case .i32OrAnd(let op): binBin("i32.or.and", op)
            case .i32ShrUAdd(let op): binBin("i32.shr_u.add", op)
            case .i32SubAnd(let op): binBin("i32.sub.and", op)
            case .i32ShlOr(let op): binBin("i32.shl.or", op)
            case .i32AddAnd(let op): binBin("i32.add.and", op)
            case .i32ShrUOr(let op): binBin("i32.shr_u.or", op)
            case .i32XorShrU(let op): binBin("i32.xor.shr_u", op)
            case .i32AddSub(let op): binBin("i32.add.sub", op)
            case .i32XorShl(let op): binBin("i32.xor.shl", op)
            case .i32SubAdd(let op): binBin("i32.sub.add", op)
            case .i32AndShl(let op): binBin("i32.and.shl", op)
            case .i64XorRotl(let op): binBin("i64.xor.rotl", op)
            case .i64MulAdd(let op): binBin("i64.mul.add", op)
            case .i64ShlAnd(let op): binBin("i64.shl.and", op)
            case .i64AndMul(let op): binBin("i64.and.mul", op)
            case .i64ShlOr(let op): binBin("i64.shl.or", op)
            case .i64XorAnd(let op): binBin("i64.xor.and", op)
            case .i64MulXor(let op): binBin("i64.mul.xor", op)
            case .i64AndXor(let op): binBin("i64.and.xor", op)
            case .i64RotlXor(let op): binBin("i64.rotl.xor", op)
            case .i64SubAnd(let op): binBin("i64.sub.and", op)
            case .i64XorXor(let op): binBin("i64.xor.xor", op)
            case .i64OrOr(let op): binBin("i64.or.or", op)
            case .i64ShrUAnd(let op): binBin("i64.shr_u.and", op)
            case .i64AndAnd(let op): binBin("i64.and.and", op)
            case .i64XorMul(let op): binBin("i64.xor.mul", op)
            case .i64XorShrU(let op): binBin("i64.xor.shr_u", op)
            case .i32MulSubRev(let op): binBinRev("i32.sub.mul", op)
            case .i32AddToAccAndSlot(let op): toAccAndSlot("i32.add", op)
            case .i32AddImmToAccAndSlot(let op): immToAccAndSlot("i32.add", op)
            case .i32SubToAccAndSlot(let op): toAccAndSlot("i32.sub", op)
            case .i32MulToAccAndSlot(let op): toAccAndSlot("i32.mul", op)
            case .i32MulImmToAccAndSlot(let op): immToAccAndSlot("i32.mul", op)
            case .i32AndToAccAndSlot(let op): toAccAndSlot("i32.and", op)
            case .i32AndImmToAccAndSlot(let op): immToAccAndSlot("i32.and", op)
            case .i32OrToAccAndSlot(let op): toAccAndSlot("i32.or", op)
            case .i32OrImmToAccAndSlot(let op): immToAccAndSlot("i32.or", op)
            case .i32XorToAccAndSlot(let op): toAccAndSlot("i32.xor", op)
            case .i32XorImmToAccAndSlot(let op): immToAccAndSlot("i32.xor", op)
            case .i32ShlToAccAndSlot(let op): toAccAndSlot("i32.shl", op)
            case .i32ShlImmToAccAndSlot(let op): immToAccAndSlot("i32.shl", op)
            case .i32ShrSToAccAndSlot(let op): toAccAndSlot("i32.shr_s", op)
            case .i32ShrSImmToAccAndSlot(let op): immToAccAndSlot("i32.shr_s", op)
            case .i32ShrUToAccAndSlot(let op): toAccAndSlot("i32.shr_u", op)
            case .i32ShrUImmToAccAndSlot(let op): immToAccAndSlot("i32.shr_u", op)
            case .i32RotlToAccAndSlot(let op): toAccAndSlot("i32.rotl", op)
            case .i32RotlImmToAccAndSlot(let op): immToAccAndSlot("i32.rotl", op)
            case .i32RotrToAccAndSlot(let op): toAccAndSlot("i32.rotr", op)
            case .i32RotrImmToAccAndSlot(let op): immToAccAndSlot("i32.rotr", op)
            case .i64AddToAccAndSlot(let op): toAccAndSlot("i64.add", op)
            case .i64AddImmToAccAndSlot(let op): immToAccAndSlot("i64.add", op)
            case .i64SubToAccAndSlot(let op): toAccAndSlot("i64.sub", op)
            case .i64MulToAccAndSlot(let op): toAccAndSlot("i64.mul", op)
            case .i64MulImmToAccAndSlot(let op): immToAccAndSlot("i64.mul", op)
            case .i64AndToAccAndSlot(let op): toAccAndSlot("i64.and", op)
            case .i64AndImmToAccAndSlot(let op): immToAccAndSlot("i64.and", op)
            case .i64OrToAccAndSlot(let op): toAccAndSlot("i64.or", op)
            case .i64OrImmToAccAndSlot(let op): immToAccAndSlot("i64.or", op)
            case .i64XorToAccAndSlot(let op): toAccAndSlot("i64.xor", op)
            case .i64XorImmToAccAndSlot(let op): immToAccAndSlot("i64.xor", op)
            case .i64ShlToAccAndSlot(let op): toAccAndSlot("i64.shl", op)
            case .i64ShlImmToAccAndSlot(let op): immToAccAndSlot("i64.shl", op)
            case .i64ShrSToAccAndSlot(let op): toAccAndSlot("i64.shr_s", op)
            case .i64ShrSImmToAccAndSlot(let op): immToAccAndSlot("i64.shr_s", op)
            case .i64ShrUToAccAndSlot(let op): toAccAndSlot("i64.shr_u", op)
            case .i64ShrUImmToAccAndSlot(let op): immToAccAndSlot("i64.shr_u", op)
            case .i64RotlToAccAndSlot(let op): toAccAndSlot("i64.rotl", op)
            case .i64RotlImmToAccAndSlot(let op): immToAccAndSlot("i64.rotl", op)
            case .i64RotrToAccAndSlot(let op): toAccAndSlot("i64.rotr", op)
            case .i64RotrImmToAccAndSlot(let op): immToAccAndSlot("i64.rotr", op)
            case .i32LoadToAccAndSlot(let op): loadToAccAndSlot("i32.load", op)
            case .i64LoadToAccAndSlot(let op): loadToAccAndSlot("i64.load", op)
            case .f32LoadToAccAndSlot(let op): loadToAccAndSlot("f32.load", op)
            case .f64LoadToAccAndSlot(let op): loadToAccAndSlot("f64.load", op)
            case .i32Load8SToAccAndSlot(let op): loadToAccAndSlot("i32.load8_s", op)
            case .i32Load8UToAccAndSlot(let op): loadToAccAndSlot("i32.load8_u", op)
            case .i32Load16SToAccAndSlot(let op): loadToAccAndSlot("i32.load16_s", op)
            case .i32Load16UToAccAndSlot(let op): loadToAccAndSlot("i32.load16_u", op)
            case .i64Load8SToAccAndSlot(let op): loadToAccAndSlot("i64.load8_s", op)
            case .i64Load8UToAccAndSlot(let op): loadToAccAndSlot("i64.load8_u", op)
            case .i64Load16SToAccAndSlot(let op): loadToAccAndSlot("i64.load16_s", op)
            case .i64Load16UToAccAndSlot(let op): loadToAccAndSlot("i64.load16_u", op)
            case .i64Load32SToAccAndSlot(let op): loadToAccAndSlot("i64.load32_s", op)
            case .i64Load32UToAccAndSlot(let op): loadToAccAndSlot("i64.load32_u", op)
            case .i32AddToAcc(let op): toAcc("i32.add", op)
            case .i32AddFromAcc(let op): fromAcc("i32.add", op)
            case .i32AddInAcc(let op): inAcc("i32.add", op)
            case .i32SubToAcc(let op): toAcc("i32.sub", op)
            case .i32SubFromAcc(let op): fromAcc("i32.sub", op)
            case .i32SubInAcc(let op): inAcc("i32.sub", op)
            case .i32MulToAcc(let op): toAcc("i32.mul", op)
            case .i32MulFromAcc(let op): fromAcc("i32.mul", op)
            case .i32MulInAcc(let op): inAcc("i32.mul", op)
            case .i32AndToAcc(let op): toAcc("i32.and", op)
            case .i32AndFromAcc(let op): fromAcc("i32.and", op)
            case .i32AndInAcc(let op): inAcc("i32.and", op)
            case .i32OrToAcc(let op): toAcc("i32.or", op)
            case .i32OrFromAcc(let op): fromAcc("i32.or", op)
            case .i32OrInAcc(let op): inAcc("i32.or", op)
            case .i32XorToAcc(let op): toAcc("i32.xor", op)
            case .i32XorFromAcc(let op): fromAcc("i32.xor", op)
            case .i32XorInAcc(let op): inAcc("i32.xor", op)
            case .i32ShlToAcc(let op): toAcc("i32.shl", op)
            case .i32ShlFromAcc(let op): fromAcc("i32.shl", op)
            case .i32ShlInAcc(let op): inAcc("i32.shl", op)
            case .i32ShrSToAcc(let op): toAcc("i32.shr_s", op)
            case .i32ShrSFromAcc(let op): fromAcc("i32.shr_s", op)
            case .i32ShrSInAcc(let op): inAcc("i32.shr_s", op)
            case .i32ShrUToAcc(let op): toAcc("i32.shr_u", op)
            case .i32ShrUFromAcc(let op): fromAcc("i32.shr_u", op)
            case .i32ShrUInAcc(let op): inAcc("i32.shr_u", op)
            case .i32RotlToAcc(let op): toAcc("i32.rotl", op)
            case .i32RotlFromAcc(let op): fromAcc("i32.rotl", op)
            case .i32RotlInAcc(let op): inAcc("i32.rotl", op)
            case .i32RotrToAcc(let op): toAcc("i32.rotr", op)
            case .i32RotrFromAcc(let op): fromAcc("i32.rotr", op)
            case .i32RotrInAcc(let op): inAcc("i32.rotr", op)
            case .i64AddToAcc(let op): toAcc("i64.add", op)
            case .i64AddFromAcc(let op): fromAcc("i64.add", op)
            case .i64AddInAcc(let op): inAcc("i64.add", op)
            case .i64SubToAcc(let op): toAcc("i64.sub", op)
            case .i64SubFromAcc(let op): fromAcc("i64.sub", op)
            case .i64SubInAcc(let op): inAcc("i64.sub", op)
            case .i64MulToAcc(let op): toAcc("i64.mul", op)
            case .i64MulFromAcc(let op): fromAcc("i64.mul", op)
            case .i64MulInAcc(let op): inAcc("i64.mul", op)
            case .i64AndToAcc(let op): toAcc("i64.and", op)
            case .i64AndFromAcc(let op): fromAcc("i64.and", op)
            case .i64AndInAcc(let op): inAcc("i64.and", op)
            case .i64OrToAcc(let op): toAcc("i64.or", op)
            case .i64OrFromAcc(let op): fromAcc("i64.or", op)
            case .i64OrInAcc(let op): inAcc("i64.or", op)
            case .i64XorToAcc(let op): toAcc("i64.xor", op)
            case .i64XorFromAcc(let op): fromAcc("i64.xor", op)
            case .i64XorInAcc(let op): inAcc("i64.xor", op)
            case .i64ShlToAcc(let op): toAcc("i64.shl", op)
            case .i64ShlFromAcc(let op): fromAcc("i64.shl", op)
            case .i64ShlInAcc(let op): inAcc("i64.shl", op)
            case .i64ShrSToAcc(let op): toAcc("i64.shr_s", op)
            case .i64ShrSFromAcc(let op): fromAcc("i64.shr_s", op)
            case .i64ShrSInAcc(let op): inAcc("i64.shr_s", op)
            case .i64ShrUToAcc(let op): toAcc("i64.shr_u", op)
            case .i64ShrUFromAcc(let op): fromAcc("i64.shr_u", op)
            case .i64ShrUInAcc(let op): inAcc("i64.shr_u", op)
            case .i64RotlToAcc(let op): toAcc("i64.rotl", op)
            case .i64RotlFromAcc(let op): fromAcc("i64.rotl", op)
            case .i64RotlInAcc(let op): inAcc("i64.rotl", op)
            case .i64RotrToAcc(let op): toAcc("i64.rotr", op)
            case .i64RotrFromAcc(let op): fromAcc("i64.rotr", op)
            case .i64RotrInAcc(let op): inAcc("i64.rotr", op)
            case .brIfI32EqAcc(let op): brIfAccCmp("i32.eq", op)
            case .brIfI32NeAcc(let op): brIfAccCmp("i32.ne", op)
            case .brIfI32LtSAcc(let op): brIfAccCmp("i32.lt_s", op)
            case .brIfI32LtUAcc(let op): brIfAccCmp("i32.lt_u", op)
            case .brIfI32GtSAcc(let op): brIfAccCmp("i32.gt_s", op)
            case .brIfI32GtUAcc(let op): brIfAccCmp("i32.gt_u", op)
            case .brIfI32LeSAcc(let op): brIfAccCmp("i32.le_s", op)
            case .brIfI32LeUAcc(let op): brIfAccCmp("i32.le_u", op)
            case .brIfI32GeSAcc(let op): brIfAccCmp("i32.ge_s", op)
            case .brIfI32GeUAcc(let op): brIfAccCmp("i32.ge_u", op)
            case .brIfI64EqAcc(let op): brIfAccCmp("i64.eq", op)
            case .brIfI64NeAcc(let op): brIfAccCmp("i64.ne", op)
            case .brIfI64LtSAcc(let op): brIfAccCmp("i64.lt_s", op)
            case .brIfI64LtUAcc(let op): brIfAccCmp("i64.lt_u", op)
            case .brIfI64GtSAcc(let op): brIfAccCmp("i64.gt_s", op)
            case .brIfI64GtUAcc(let op): brIfAccCmp("i64.gt_u", op)
            case .brIfI64LeSAcc(let op): brIfAccCmp("i64.le_s", op)
            case .brIfI64LeUAcc(let op): brIfAccCmp("i64.le_u", op)
            case .brIfI64GeSAcc(let op): brIfAccCmp("i64.ge_s", op)
            case .brIfI64GeUAcc(let op): brIfAccCmp("i64.ge_u", op)
            case .brIfAcc(let op): target.write("br_if acc, \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotAcc(let op): target.write("br_if_not acc, \(branchTarget(instructionOffset, Int(op.offset)))")
            case .i32LoadToAcc(let op): loadToAcc("i32.load", op)
            case .i32LoadFromAcc(let op): loadFromAcc("i32.load", op)
            case .i32LoadInAcc(let op): loadInAcc("i32.load", op)
            case .i64LoadToAcc(let op): loadToAcc("i64.load", op)
            case .i64LoadFromAcc(let op): loadFromAcc("i64.load", op)
            case .i64LoadInAcc(let op): loadInAcc("i64.load", op)
            case .f32LoadToAcc(let op): loadToAcc("f32.load", op)
            case .f32LoadFromAcc(let op): loadFromAcc("f32.load", op)
            case .f32LoadInAcc(let op): loadInAcc("f32.load", op)
            case .f64LoadToAcc(let op): loadToAcc("f64.load", op)
            case .f64LoadFromAcc(let op): loadFromAcc("f64.load", op)
            case .f64LoadInAcc(let op): loadInAcc("f64.load", op)
            case .i32Load8SToAcc(let op): loadToAcc("i32.load8_s", op)
            case .i32Load8SFromAcc(let op): loadFromAcc("i32.load8_s", op)
            case .i32Load8SInAcc(let op): loadInAcc("i32.load8_s", op)
            case .i32Load8UToAcc(let op): loadToAcc("i32.load8_u", op)
            case .i32Load8UFromAcc(let op): loadFromAcc("i32.load8_u", op)
            case .i32Load8UInAcc(let op): loadInAcc("i32.load8_u", op)
            case .i32Load16SToAcc(let op): loadToAcc("i32.load16_s", op)
            case .i32Load16SFromAcc(let op): loadFromAcc("i32.load16_s", op)
            case .i32Load16SInAcc(let op): loadInAcc("i32.load16_s", op)
            case .i32Load16UToAcc(let op): loadToAcc("i32.load16_u", op)
            case .i32Load16UFromAcc(let op): loadFromAcc("i32.load16_u", op)
            case .i32Load16UInAcc(let op): loadInAcc("i32.load16_u", op)
            case .i64Load8SToAcc(let op): loadToAcc("i64.load8_s", op)
            case .i64Load8SFromAcc(let op): loadFromAcc("i64.load8_s", op)
            case .i64Load8SInAcc(let op): loadInAcc("i64.load8_s", op)
            case .i64Load8UToAcc(let op): loadToAcc("i64.load8_u", op)
            case .i64Load8UFromAcc(let op): loadFromAcc("i64.load8_u", op)
            case .i64Load8UInAcc(let op): loadInAcc("i64.load8_u", op)
            case .i64Load16SToAcc(let op): loadToAcc("i64.load16_s", op)
            case .i64Load16SFromAcc(let op): loadFromAcc("i64.load16_s", op)
            case .i64Load16SInAcc(let op): loadInAcc("i64.load16_s", op)
            case .i64Load16UToAcc(let op): loadToAcc("i64.load16_u", op)
            case .i64Load16UFromAcc(let op): loadFromAcc("i64.load16_u", op)
            case .i64Load16UInAcc(let op): loadInAcc("i64.load16_u", op)
            case .i64Load32SToAcc(let op): loadToAcc("i64.load32_s", op)
            case .i64Load32SFromAcc(let op): loadFromAcc("i64.load32_s", op)
            case .i64Load32SInAcc(let op): loadInAcc("i64.load32_s", op)
            case .i64Load32UToAcc(let op): loadToAcc("i64.load32_u", op)
            case .i64Load32UFromAcc(let op): loadFromAcc("i64.load32_u", op)
            case .i64Load32UInAcc(let op): loadInAcc("i64.load32_u", op)
            case .i32StoreFromAcc(let op): storeFromAcc("i32.store", op)
            case .i32StoreAddrFromAcc(let op): storeAddrFromAcc("i32.store", op)
            case .i64StoreFromAcc(let op): storeFromAcc("i64.store", op)
            case .i64StoreAddrFromAcc(let op): storeAddrFromAcc("i64.store", op)
            case .f32StoreFromAcc(let op): storeFromAcc("f32.store", op)
            case .f32StoreAddrFromAcc(let op): storeAddrFromAcc("f32.store", op)
            case .f64StoreFromAcc(let op): storeFromAcc("f64.store", op)
            case .f64StoreAddrFromAcc(let op): storeAddrFromAcc("f64.store", op)
            case .i32Store8FromAcc(let op): storeFromAcc("i32.store8", op)
            case .i32Store8AddrFromAcc(let op): storeAddrFromAcc("i32.store8", op)
            case .i32Store16FromAcc(let op): storeFromAcc("i32.store16", op)
            case .i32Store16AddrFromAcc(let op): storeAddrFromAcc("i32.store16", op)
            case .i64Store8FromAcc(let op): storeFromAcc("i64.store8", op)
            case .i64Store8AddrFromAcc(let op): storeAddrFromAcc("i64.store8", op)
            case .i64Store16FromAcc(let op): storeFromAcc("i64.store16", op)
            case .i64Store16AddrFromAcc(let op): storeAddrFromAcc("i64.store16", op)
            case .i64Store32FromAcc(let op): storeFromAcc("i64.store32", op)
            case .i64Store32AddrFromAcc(let op): storeAddrFromAcc("i64.store32", op)
            case .f64AddToAcc(let op): target.write("facc = f64.add \(reg(op.lhs)), \(reg(op.rhs))")
            case .f64AddFromAcc(let op): target.write("\(reg(op.result)) = f64.add facc, \(reg(op.operand))")
            case .f64AddInAcc(let op): target.write("facc = f64.add facc, \(reg(op.operand))")
            case .f64SubToAcc(let op): target.write("facc = f64.sub \(reg(op.lhs)), \(reg(op.rhs))")
            case .f64SubFromAcc(let op): target.write("\(reg(op.result)) = f64.sub facc, \(reg(op.operand))")
            case .f64SubInAcc(let op): target.write("facc = f64.sub facc, \(reg(op.operand))")
            case .f64SubFromAccRev(let op): target.write("\(reg(op.result)) = f64.sub \(reg(op.operand)), facc")
            case .f64SubInAccRev(let op): target.write("facc = f64.sub \(reg(op.operand)), facc")
            case .f64MulToAcc(let op): target.write("facc = f64.mul \(reg(op.lhs)), \(reg(op.rhs))")
            case .f64MulFromAcc(let op): target.write("\(reg(op.result)) = f64.mul facc, \(reg(op.operand))")
            case .f64MulInAcc(let op): target.write("facc = f64.mul facc, \(reg(op.operand))")
            case .f64DivToAcc(let op): target.write("facc = f64.div \(reg(op.lhs)), \(reg(op.rhs))")
            case .f64DivFromAcc(let op): target.write("\(reg(op.result)) = f64.div facc, \(reg(op.operand))")
            case .f64DivInAcc(let op): target.write("facc = f64.div facc, \(reg(op.operand))")
            case .f64DivFromAccRev(let op): target.write("\(reg(op.result)) = f64.div \(reg(op.operand)), facc")
            case .f64DivInAccRev(let op): target.write("facc = f64.div \(reg(op.operand)), facc")
            case .f64AddAddToAcc(let op): target.write("facc = f64.add.add \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64AddSubToAcc(let op): target.write("facc = f64.add.sub \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64AddMulToAcc(let op): target.write("facc = f64.add.mul \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64SubAddToAcc(let op): target.write("facc = f64.sub.add \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64SubSubToAcc(let op): target.write("facc = f64.sub.sub \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64SubMulToAcc(let op): target.write("facc = f64.sub.mul \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64MulAddToAcc(let op): target.write("facc = f64.mul.add \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64MulSubToAcc(let op): target.write("facc = f64.mul.sub \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .f64MulMulToAcc(let op): target.write("facc = f64.mul.mul \(reg(op.x)), \(reg(op.y)), \(reg(op.z))")
            case .brIfF64EqAcc(let op): target.write("br_if.f64.eq facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfF64NeAcc(let op): target.write("br_if.f64.ne facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfF64LtAcc(let op): target.write("br_if.f64.lt facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfF64LeAcc(let op): target.write("br_if.f64.le facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfF64GtAcc(let op): target.write("br_if.f64.gt facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfF64GeAcc(let op): target.write("br_if.f64.ge facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotF64LtAcc(let op): target.write("br_if.not.f64.lt facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotF64LeAcc(let op): target.write("br_if.not.f64.le facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotF64GtAcc(let op): target.write("br_if.not.f64.gt facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotF64GeAcc(let op): target.write("br_if.not.f64.ge facc, \(reg(op.rhs)), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .f64SqrtToAcc(let op): target.write("facc = f64.sqrt \(reg(op.operand))")
            case .f64LoadToFAcc(let op): target.write("facc = f64.load \(reg(op.pointer)), \(offset(UInt64(op.offset)))")
            case .f64LoadFromAccToFAcc(let op): target.write("facc = f64.load acc, \(offset(UInt64(op.offset)))")
            case .f64StoreFromFAcc(let op): target.write("f64.store \(reg(op.pointer)) + \(offset(UInt64(op.offset))), facc")
            case .i32AddImm(let op): target.write("\(reg(op.result)) = i32.add \(reg(op.lhs)), #\(op.imm)")
            case .i32MulImm(let op): target.write("\(reg(op.result)) = i32.mul \(reg(op.lhs)), #\(op.imm)")
            case .i32AndImm(let op): target.write("\(reg(op.result)) = i32.and \(reg(op.lhs)), #\(op.imm)")
            case .i32OrImm(let op): target.write("\(reg(op.result)) = i32.or \(reg(op.lhs)), #\(op.imm)")
            case .i32XorImm(let op): target.write("\(reg(op.result)) = i32.xor \(reg(op.lhs)), #\(op.imm)")
            case .i32ShlImm(let op): target.write("\(reg(op.result)) = i32.shl \(reg(op.lhs)), #\(op.imm)")
            case .i32ShrSImm(let op): target.write("\(reg(op.result)) = i32.shr_s \(reg(op.lhs)), #\(op.imm)")
            case .i32ShrUImm(let op): target.write("\(reg(op.result)) = i32.shr_u \(reg(op.lhs)), #\(op.imm)")
            case .i32RotlImm(let op): target.write("\(reg(op.result)) = i32.rotl \(reg(op.lhs)), #\(op.imm)")
            case .i32RotrImm(let op): target.write("\(reg(op.result)) = i32.rotr \(reg(op.lhs)), #\(op.imm)")
            case .i32EqImm(let op): target.write("\(reg(op.result)) = i32.eq \(reg(op.lhs)), #\(op.imm)")
            case .i32NeImm(let op): target.write("\(reg(op.result)) = i32.ne \(reg(op.lhs)), #\(op.imm)")
            case .i32LtSImm(let op): target.write("\(reg(op.result)) = i32.lt_s \(reg(op.lhs)), #\(op.imm)")
            case .i32LtUImm(let op): target.write("\(reg(op.result)) = i32.lt_u \(reg(op.lhs)), #\(op.imm)")
            case .i32GtSImm(let op): target.write("\(reg(op.result)) = i32.gt_s \(reg(op.lhs)), #\(op.imm)")
            case .i32GtUImm(let op): target.write("\(reg(op.result)) = i32.gt_u \(reg(op.lhs)), #\(op.imm)")
            case .i32LeSImm(let op): target.write("\(reg(op.result)) = i32.le_s \(reg(op.lhs)), #\(op.imm)")
            case .i32LeUImm(let op): target.write("\(reg(op.result)) = i32.le_u \(reg(op.lhs)), #\(op.imm)")
            case .i32GeSImm(let op): target.write("\(reg(op.result)) = i32.ge_s \(reg(op.lhs)), #\(op.imm)")
            case .i32GeUImm(let op): target.write("\(reg(op.result)) = i32.ge_u \(reg(op.lhs)), #\(op.imm)")
            case .i32AddImmToAcc(let op): target.write("acc = i32.add \(reg(op.lhs)), #\(op.imm)")
            case .i32MulImmToAcc(let op): target.write("acc = i32.mul \(reg(op.lhs)), #\(op.imm)")
            case .i32AndImmToAcc(let op): target.write("acc = i32.and \(reg(op.lhs)), #\(op.imm)")
            case .i32OrImmToAcc(let op): target.write("acc = i32.or \(reg(op.lhs)), #\(op.imm)")
            case .i32XorImmToAcc(let op): target.write("acc = i32.xor \(reg(op.lhs)), #\(op.imm)")
            case .i32ShlImmToAcc(let op): target.write("acc = i32.shl \(reg(op.lhs)), #\(op.imm)")
            case .i32ShrSImmToAcc(let op): target.write("acc = i32.shr_s \(reg(op.lhs)), #\(op.imm)")
            case .i32ShrUImmToAcc(let op): target.write("acc = i32.shr_u \(reg(op.lhs)), #\(op.imm)")
            case .i32RotlImmToAcc(let op): target.write("acc = i32.rotl \(reg(op.lhs)), #\(op.imm)")
            case .i32RotrImmToAcc(let op): target.write("acc = i32.rotr \(reg(op.lhs)), #\(op.imm)")
            case .brIfI32EqImm(let op): target.write("br_if.i32.eq \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32NeImm(let op): target.write("br_if.i32.ne \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32LtSImm(let op): target.write("br_if.i32.lt_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32LtUImm(let op): target.write("br_if.i32.lt_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32GtSImm(let op): target.write("br_if.i32.gt_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32GtUImm(let op): target.write("br_if.i32.gt_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32LeSImm(let op): target.write("br_if.i32.le_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32LeUImm(let op): target.write("br_if.i32.le_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32GeSImm(let op): target.write("br_if.i32.ge_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32GeUImm(let op): target.write("br_if.i32.ge_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI32AndImm(let op): target.write("br_if.i32.and \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotI32AndImm(let op): target.write("br_if.not.i32.and \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .i64AddImm(let op): target.write("\(reg(op.result)) = i64.add \(reg(op.lhs)), #\(op.imm)")
            case .i64MulImm(let op): target.write("\(reg(op.result)) = i64.mul \(reg(op.lhs)), #\(op.imm)")
            case .i64AndImm(let op): target.write("\(reg(op.result)) = i64.and \(reg(op.lhs)), #\(op.imm)")
            case .i64OrImm(let op): target.write("\(reg(op.result)) = i64.or \(reg(op.lhs)), #\(op.imm)")
            case .i64XorImm(let op): target.write("\(reg(op.result)) = i64.xor \(reg(op.lhs)), #\(op.imm)")
            case .i64ShlImm(let op): target.write("\(reg(op.result)) = i64.shl \(reg(op.lhs)), #\(op.imm)")
            case .i64ShrSImm(let op): target.write("\(reg(op.result)) = i64.shr_s \(reg(op.lhs)), #\(op.imm)")
            case .i64ShrUImm(let op): target.write("\(reg(op.result)) = i64.shr_u \(reg(op.lhs)), #\(op.imm)")
            case .i64RotlImm(let op): target.write("\(reg(op.result)) = i64.rotl \(reg(op.lhs)), #\(op.imm)")
            case .i64RotrImm(let op): target.write("\(reg(op.result)) = i64.rotr \(reg(op.lhs)), #\(op.imm)")
            case .i64EqImm(let op): target.write("\(reg(op.result)) = i64.eq \(reg(op.lhs)), #\(op.imm)")
            case .i64NeImm(let op): target.write("\(reg(op.result)) = i64.ne \(reg(op.lhs)), #\(op.imm)")
            case .i64LtSImm(let op): target.write("\(reg(op.result)) = i64.lt_s \(reg(op.lhs)), #\(op.imm)")
            case .i64LtUImm(let op): target.write("\(reg(op.result)) = i64.lt_u \(reg(op.lhs)), #\(op.imm)")
            case .i64GtSImm(let op): target.write("\(reg(op.result)) = i64.gt_s \(reg(op.lhs)), #\(op.imm)")
            case .i64GtUImm(let op): target.write("\(reg(op.result)) = i64.gt_u \(reg(op.lhs)), #\(op.imm)")
            case .i64LeSImm(let op): target.write("\(reg(op.result)) = i64.le_s \(reg(op.lhs)), #\(op.imm)")
            case .i64LeUImm(let op): target.write("\(reg(op.result)) = i64.le_u \(reg(op.lhs)), #\(op.imm)")
            case .i64GeSImm(let op): target.write("\(reg(op.result)) = i64.ge_s \(reg(op.lhs)), #\(op.imm)")
            case .i64GeUImm(let op): target.write("\(reg(op.result)) = i64.ge_u \(reg(op.lhs)), #\(op.imm)")
            case .i64AddImmToAcc(let op): target.write("acc = i64.add \(reg(op.lhs)), #\(op.imm)")
            case .i64MulImmToAcc(let op): target.write("acc = i64.mul \(reg(op.lhs)), #\(op.imm)")
            case .i64AndImmToAcc(let op): target.write("acc = i64.and \(reg(op.lhs)), #\(op.imm)")
            case .i64OrImmToAcc(let op): target.write("acc = i64.or \(reg(op.lhs)), #\(op.imm)")
            case .i64XorImmToAcc(let op): target.write("acc = i64.xor \(reg(op.lhs)), #\(op.imm)")
            case .i64ShlImmToAcc(let op): target.write("acc = i64.shl \(reg(op.lhs)), #\(op.imm)")
            case .i64ShrSImmToAcc(let op): target.write("acc = i64.shr_s \(reg(op.lhs)), #\(op.imm)")
            case .i64ShrUImmToAcc(let op): target.write("acc = i64.shr_u \(reg(op.lhs)), #\(op.imm)")
            case .i64RotlImmToAcc(let op): target.write("acc = i64.rotl \(reg(op.lhs)), #\(op.imm)")
            case .i64RotrImmToAcc(let op): target.write("acc = i64.rotr \(reg(op.lhs)), #\(op.imm)")
            case .brIfI64EqImm(let op): target.write("br_if.i64.eq \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64NeImm(let op): target.write("br_if.i64.ne \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64LtSImm(let op): target.write("br_if.i64.lt_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64LtUImm(let op): target.write("br_if.i64.lt_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64GtSImm(let op): target.write("br_if.i64.gt_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64GtUImm(let op): target.write("br_if.i64.gt_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64LeSImm(let op): target.write("br_if.i64.le_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64LeUImm(let op): target.write("br_if.i64.le_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64GeSImm(let op): target.write("br_if.i64.ge_s \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64GeUImm(let op): target.write("br_if.i64.ge_u \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfI64AndImm(let op): target.write("br_if.i64.and \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .brIfNotI64AndImm(let op): target.write("br_if.not.i64.and \(reg(op.lhs)), #\(op.imm), \(branchTarget(instructionOffset, Int(op.offset)))")
            case .globalGetToAcc(let op): target.write("acc = global.get \(global(op.global))")
            case .br(let offset):
                target.write("br \(branchTarget(instructionOffset, Int(offset)))")
            case .brTable(let table):
                target.write("br_table \(reg(table.index)), \(table.count) cases")
                for i in 0..<table.count {
                    target.write("\n  \(i): \(branchTarget(instructionOffset, Int(table.baseAddress[Int(i)].offset)) )")
                }
            case ._return:
                target.write("return")
            default:
                target.write(String(describing: instruction))
            }
        }
    }
#endif  // Disassembler
