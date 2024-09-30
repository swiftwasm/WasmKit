import WasmParser

/// A register that is used to store a value in the stack.
typealias VReg = Int16

/// A register value that is pre-shifted to avoid runtime shift operation.
protocol ShiftedVReg {
    associatedtype Storage: FixedWidthInteger

    /// The value of the shifted register.
    /// Must be a multiple of `MemoryLayout<StackSlot>.size`.
    var value: Storage { get }
}

/// A larger (32-bit) version of `VReg`
/// Used to utilize halfword loads instructions.
struct LVReg: Equatable, ShiftedVReg {
    let value: Int32

    init(_ value: VReg) {
        // Pre-shift to avoid runtime shift operation by using
        // unused high bits.
        self.value = Int32(value) * Int32(MemoryLayout<StackSlot>.size)
    }

    init(storage: Int32) {
        self.value = storage
    }
}

/// A larger (64-bit) version of `VReg`
/// Used to utilize word loads instructions.
struct LLVReg: Equatable, ShiftedVReg {
    let value: Int64

    init(_ value: VReg) {
        // Pre-shift to avoid runtime shift operation by using
        // unused high bits.
        self.value = Int64(value) * Int64(MemoryLayout<StackSlot>.size)
    }

    init(storage: Int64) {
        self.value = storage
    }
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

protocol InstructionImmediate {
    static func load(from pc: inout Pc) -> Self
    static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void)
}

extension InstructionImmediate {
    func emit(to emitSlot: @escaping (CodeSlot) -> Void) {
        Self.emit { buildCodeSlot in
            emitSlot(buildCodeSlot(self))
        }
    }
    static func emit<Parent>(to emitParent: @escaping ((Parent) -> CodeSlot) -> Void, _ child: KeyPath<Parent, Self>) {
        Self.emit { emitChild in
            emitParent { emitChild($0[keyPath: child]) }
        }
    }
}

extension InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        pc.read()
    }
    static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
        assert(MemoryLayout<Self>.size == 8)
        emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
    }
}

extension VReg: InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        VReg(bitPattern: UInt16(pc.read(UInt64.self)))
    }
    static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
        emitSlot { CodeSlot(UInt16(bitPattern: $0)) }
    }

    typealias Slot2 = (VReg, VReg, pad: UInt32)
    static func load2(from pc: inout Pc) -> (Self, Self) {
        let (x, y, _) = pc.read(Slot2.self)
        return (x, y)
    }
    static func emit2(to emitSlot: @escaping ((Self, Self) -> CodeSlot) -> Void) {
        emitSlot { x, y in
            let slot: Slot2 = (x, y, 0)
            return unsafeBitCast(slot, to: CodeSlot.self)
        }
    }
}

extension LLVReg: InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        Self(storage: Int64(bitPattern: pc.read()))
    }
    static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
        emitSlot { UInt64(bitPattern: $0.value) }
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

extension Instruction.RefNullOperand {
    init(result: VReg, type: ReferenceType) {
        self.init(result: result, rawType: type.rawValue)
    }

    var type: ReferenceType {
        ReferenceType(rawValue: rawType).unsafelyUnwrapped
    }
}

extension Instruction.GlobalAndVRegOperand {
    init(reg: LLVReg, global: InternalGlobal) {
        self.init(reg: reg, rawGlobal: UInt64(UInt(bitPattern: global.bitPattern)))
    }
    var global: InternalGlobal {
        InternalGlobal(bitPattern: UInt(rawGlobal)).unsafelyUnwrapped
    }
}

extension Instruction.BrTableOperand {
    struct Entry {
        var offset: Int32
    }

    init(baseAddress: UnsafePointer<Entry>, count: UInt16, index: VReg) {
        self.init(rawBaseAddress: UInt64(UInt(bitPattern: baseAddress)), count: count, index: index)
    }

    var baseAddress: UnsafePointer<Entry> {
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

extension Instruction {
    typealias BrOperand = Int32
    typealias OnEnterOperand = FunctionIndex
    typealias OnExitOperand = FunctionIndex
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
    func reg(_ x: LVReg) -> String { reg(x.value) }
    func reg(_ x: LLVReg) -> String { reg(x.value) }

    func offset(_ offset: UInt64) -> String {
        "offset: \(offset)"
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

    mutating func print<Target>(
        instruction: Instruction,
        to target: inout Target
    ) where Target : TextOutputStream {
        switch instruction {
        case .unreachable:
            target.write("unreachable")
        case .nop:
            target.write("nop")
        case .globalGet(let op):
            target.write("\(reg(op.reg)) = global.get \(global(op.global))")
        case .globalSet(let op):
            target.write("global.set \(global(op.global)), \(reg(op.reg))")
        case .const32(let op):
            target.write("\(reg(op.result)) = \(hex(op.value))")
        case .call(let op):
            target.write("call \(callee(op.callee)), sp: +\(op.spAddend)")
        case .callIndirect(let op):
            target.write("call_indirect \(reg(op.index)), \(op.tableIndex), (func_ty id:\(op.type.id)), sp: +\(op.spAddend)")
        case .compilingCall(let op):
            target.write("compiling_call \(callee(op.callee)), sp: +\(op.spAddend)")
        case .i32Load(let op):
            target.write("\(reg(op.result)) = i32.load \(reg(op.pointer)), \(offset(op.offset))")
        case .i64Load(let op):
            target.write("\(reg(op.result)) = i64.load \(reg(op.pointer)), \(offset(op.offset))")
        case .f32Load(let op):
            target.write("\(reg(op.result)) = f32.load \(reg(op.pointer)), \(offset(op.offset))")
        case .f64Load(let op):
            target.write("\(reg(op.result)) = f64.load \(reg(op.pointer)), \(offset(op.offset))")
        case .copyStack(let op):
            target.write("\(reg(op.dest)) = copy \(reg(op.source))")
        case .i32Add(let op):
            target.write("\(reg(op.result)) = i32.add \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Sub(let op):
            target.write("\(reg(op.result)) = i32.sub \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32LtU(let op):
            target.write("\(reg(op.result)) = i32.lt_u \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eq(let op):
            target.write("\(reg(op.result)) = i32.eq \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eqz(let op):
            target.write("\(reg(op.result)) = i32.eqz \(reg(op.input))")
        case .i32Store(let op):
            target.write("i32.store \(reg(op.pointer)), \(reg(op.value)), \(offset(op.offset))")
        case .brIfNot(let op):
            target.write("br_if_not \(reg(op.condition)), +\(op.offset)")
        case .brIf(let op):
            target.write("br_if \(reg(op.condition)), +\(op.offset)")
        case .br(let offset):
            target.write("br \(offset > 0 ? "+" : "")\(offset)")
        case .brTable(let table):
            target.write("br_table \(reg(table.index)), \(table.count) cases")
            for i in 0..<table.count {
                target.write("\n  \(i): +\(table.baseAddress[Int(i)].offset)")
            }
        case ._return:
            target.write("return")
        default:
            target.write(String(describing: instruction))
        }
    }
}
