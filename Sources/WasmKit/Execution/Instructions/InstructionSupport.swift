import WasmParser

typealias VReg = Int16
typealias LVReg = Int32
typealias LLVReg = Int64

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
        Self(bitPattern: pc.read())
    }
    static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
        emitSlot { UInt64(bitPattern: $0) }
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

enum PReg: Int, CaseIterable {
    case x0 = 0
    case d0 = 1
}

extension Instruction {
    /// size = 6, alignment = 2
    struct BinaryOperand: Equatable, InstructionImmediate {
        let result: LVReg
        let lhs: VReg
        let rhs: VReg
        @inline(__always) static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        @inline(__always) static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }
    
    /// size = 4, alignment = 2
    struct UnaryOperand: Equatable, InstructionImmediate {
        let result: LVReg
        let input: LVReg
        @inline(__always) static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        @inline(__always) static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }

    struct Const32Operand: Equatable, InstructionImmediate {
        let value: UInt32
        let result: LVReg
    }

    struct Const64Operand: Equatable, InstructionImmediate {
        let value: UntypedValue
        let result: LLVReg
        static func load(from pc: inout Pc) -> Self {
            let value = pc.read(UntypedValue.self)
            let result = LLVReg.load(from: &pc)
            return Self(value: value, result: result)
        }
        static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot { $0.value.storage }
            LLVReg.emit(to: emitSlot, \.result)
        }
    }

    /// size = 4, alignment = 8
    struct LoadOperandS: Equatable, InstructionImmediate {
        let offset: UInt64
        let pointer: LLVReg

        @inline(__always) static func load(from pc: inout Pc) -> Self {
            let offset = pc.read(UInt64.self)
            let pointer = pc.read(LLVReg.self)
            return Self(offset: offset, pointer: pointer)
        }
        @inline(__always) static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot { $0.offset }
            emitSlot { CodeSlot(bitPattern: $0.pointer) }
        }
    }

    struct LoadOperandR: Equatable, InstructionImmediate {
        let offset: UInt64

        @inline(__always) static func load(from pc: inout Pc) -> Self {
            let offset = pc.read(UInt64.self)
            return Self(offset: offset)
        }
        @inline(__always) static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot { $0.offset }
        }
    }

    struct StoreOperand: Equatable, InstructionImmediate {
        let offset: UInt64
        let pointer: VReg
        let value: VReg

        @inline(__always) static func load(from pc: inout Pc) -> Self {
            let offset = pc.read(UInt64.self)
            let (pointer, value) = VReg.load2(from: &pc)
            return Self(offset: offset, pointer: pointer, value: value)
        }
        @inline(__always) static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot { $0.offset }
            VReg.emit2 { emitVRegs in
                emitSlot { emitVRegs($0.pointer, $0.value) }
            }
        }
    }
    
    struct MemorySizeOperand: Equatable, InstructionImmediate {
        let memoryIndex: MemoryIndex
        let result: LVReg
    }
    
    struct MemoryGrowOperand: Equatable, InstructionImmediate {
        let result: VReg
        let delta: VReg
        let memory: MemoryIndex
    }
    
    struct MemoryInitOperand: Equatable, InstructionImmediate {
        let segmentIndex: UInt32
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg

        private typealias FirstSlot = (segmentIndex: UInt32, destOffset: VReg, sourceOffset: VReg)
        static func load(from pc: inout Pc) -> Self {
            let (segmentIndex, destOffset, sourceOffset) = pc.read(FirstSlot.self)
            let size = VReg.load(from: &pc)
            return Self(segmentIndex: segmentIndex, destOffset: destOffset, sourceOffset: sourceOffset, size: size)
        }
        static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: FirstSlot = ($0.segmentIndex, $0.destOffset, $0.sourceOffset)
                return unsafeBitCast(slot, to: UInt64.self)
            }
            VReg.emit(to: emitSlot, \.size)
        }
    }
    
    struct MemoryCopyOperand: Equatable, InstructionImmediate {
        let destOffset: VReg
        let sourceOffset: VReg
        let size: LVReg
    }
    
    struct MemoryFillOperand: Equatable, InstructionImmediate {
        let destOffset: VReg
        let value: VReg
        let size: LVReg
    }
    
    struct SelectOperand: Equatable, InstructionImmediate {
        let result: VReg
        let condition: VReg
        let onTrue: VReg
        let onFalse: VReg
    }
    
    struct RefNullOperand: Equatable, InstructionImmediate {
        let type: ReferenceType
        let result: VReg

        private typealias Slot = (ReferenceType, VReg, UInt32)
        static func load(from pc: inout Pc) -> Self {
            let (type, result, _) = pc.read(Slot.self)
            return Self(type: type, result: result)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot = ($0.type, $0.result, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }
    
    struct RefIsNullOperand: Equatable, InstructionImmediate {
        let value: LVReg
        let result: LVReg
    }
    
    struct RefFuncOperand: Equatable, InstructionImmediate {
        let index: FunctionIndex
        let result: LVReg
    }
    
    struct TableGetOperand: Equatable, InstructionImmediate {
        let index: VReg
        let result: VReg
        let tableIndex: UInt32
    }
    
    struct TableSetOperand: Equatable, InstructionImmediate {
        let index: VReg
        let value: VReg
        let tableIndex: UInt32
    }
    
    struct TableSizeOperand: Equatable, InstructionImmediate {
        let tableIndex: TableIndex
        let result: LVReg
    }
    
    struct TableGrowOperand: Equatable, InstructionImmediate {
        let tableIndex: UInt32
        let result: VReg
        let delta: VReg
        let value: VReg

        private typealias Slot1 = (UInt32, VReg, VReg)
        private typealias Slot2 = (VReg, pad1: UInt16, pad2: UInt32)

        static func load(from pc: inout Pc) -> Self {
            let (tableIndex, result, delta) = pc.read(Slot1.self)
            let (value, _, _) = pc.read(Slot2.self)
            return Self(tableIndex: tableIndex, result: result, delta: delta, value: value)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot1 = ($0.tableIndex, $0.result, $0.delta)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
            emitSlot {
                let slot: Slot2 = ($0.value, 0, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }

    struct TableFillOperand: Equatable, InstructionImmediate {
        let tableIndex: UInt32
        let destOffset: VReg
        let value: VReg
        let size: VReg

        private typealias Slot1 = (UInt32, VReg, VReg)
        private typealias Slot2 = (VReg, pad1: UInt16, pad2: UInt32)

        static func load(from pc: inout Pc) -> Self {
            let (tableIndex, destOffset, value) = pc.read(Slot1.self)
            let (size, _, _) = pc.read(Slot2.self)
            return Self(tableIndex: tableIndex, destOffset: destOffset, value: value, size: size)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot1 = ($0.tableIndex, $0.destOffset, $0.value)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
            emitSlot {
                let slot: Slot2 = ($0.size, 0, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }
    
    struct TableCopyOperand: Equatable, InstructionImmediate {
        let sourceIndex: UInt32
        let destIndex: UInt32
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg
        
        private typealias Slot1 = (UInt32, UInt32)
        private typealias Slot2 = (VReg, VReg, VReg, pad: UInt16)

        static func load(from pc: inout Pc) -> Self {
            let (sourceIndex, destIndex) = pc.read(Slot1.self)
            let (destOffset, sourceOffset, size, _) = pc.read(Slot2.self)
            return Self(sourceIndex: sourceIndex, destIndex: destIndex, destOffset: destOffset, sourceOffset: sourceOffset, size: size)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot1 = ($0.sourceIndex, $0.destIndex)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
            emitSlot {
                let slot: Slot2 = ($0.destOffset, $0.sourceOffset, $0.size, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }
    
    struct TableInitOperand: Equatable, InstructionImmediate {
        let tableIndex: UInt32
        let segmentIndex: UInt32
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg

        private typealias Slot1 = (UInt32, UInt32)
        private typealias Slot2 = (VReg, VReg, VReg, pad: UInt16)

        static func load(from pc: inout Pc) -> Self {
            let (tableIndex, segmentIndex) = pc.read(Slot1.self)
            let (destOffset, sourceOffset, size, _) = pc.read(Slot2.self)
            return Self(tableIndex: tableIndex, segmentIndex: segmentIndex, destOffset: destOffset, sourceOffset: sourceOffset, size: size)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot1 = ($0.tableIndex, $0.segmentIndex)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
            emitSlot {
                let slot: Slot2 = ($0.destOffset, $0.sourceOffset, $0.size, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }

    struct GlobalAndVRegOperand: Equatable, InstructionImmediate {
        let reg: LLVReg
        let global: InternalGlobal

        static func load(from pc: inout Pc) -> Self {
            let reg = pc.read(LLVReg.self)
            let global = InternalGlobal(unsafe: UnsafeMutablePointer(bitPattern: UInt(pc.read(UInt64.self))).unsafelyUnwrapped)
            return Self(reg: reg, global: global)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { CodeSlot(bitPattern: $0.reg) }
            emitSlot { UInt64(UInt(bitPattern: $0.global.bitPattern)) }
        }
    }
    typealias GlobalGetOperand = GlobalAndVRegOperand
    typealias GlobalSetOperand = GlobalAndVRegOperand

    struct CopyStackOperand: Equatable, InstructionImmediate {
        let source: Int32
        let dest: Int32

        static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }
    
    struct BrIfOperand: Equatable, InstructionImmediate {
        let offset: Int32
        let condition: LVReg
        static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }
    
    struct BrTable: Equatable, InstructionImmediate {
        struct Entry {
            var offset: Int32
        }
        let baseAddress: UnsafePointer<Entry>
        let count: UInt16
        let index: VReg

        private typealias MiscSlot = (count: UInt16, index: VReg, pad: UInt32)

        static func load(from pc: inout Pc) -> Self {
            let brTable = UnsafePointer<Entry>(bitPattern: UInt(pc.read(UInt64.self))).unsafelyUnwrapped
            let (count, index, _) = pc.read(MiscSlot.self)
            return Self(baseAddress: brTable, count: count, index: index)
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { UInt64(UInt(bitPattern: $0.baseAddress)) }
            emitSlot {
                let slot: MiscSlot = ($0.count, $0.index, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }

    struct CallLikeOperand: Equatable, InstructionImmediate {
        let spAddend: VReg
        static func load(from pc: inout Pc) -> Self {
            return Self(spAddend: VReg.load(from: &pc))
        }
        static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            VReg.emit(to: emitSlot, \.spAddend)
        }
    }

    struct CallOperand: Equatable, InstructionImmediate {
        let callee: InternalFunction
        let callLike: CallLikeOperand

        static func load(from pc: inout Pc) -> Self {
            let callee = InternalFunction(bitPattern: Int(pc.read(UInt64.self)))
            let callLike = CallLikeOperand.load(from: &pc)
            return Self(callee: callee, callLike: callLike)
        }
        static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot { UInt64($0.callee.bitPattern) }
            CallLikeOperand.emit(to: emitSlot, \.callLike)
        }
    }

    typealias InternalCallOperand = CallOperand
    typealias CompilingCallOperand = CallOperand
    
    struct CallIndirectOperand: Equatable, InstructionImmediate {
        let tableIndex: UInt32
        let type: InternedFuncType
        let index: VReg
        let callLike: CallLikeOperand

        private typealias Slot1 = (UInt32, InternedFuncType)
        private typealias Slot2 = (VReg, VReg, pad: UInt32)
        static func load(from pc: inout Pc) -> Self {
            let (tableIndex, type) = pc.read(Slot1.self)
            let (index, spAddend, _) = pc.read(Slot2.self)
            return Self(
                tableIndex: tableIndex, type: type,
                index: index, callLike: Instruction.CallLikeOperand(spAddend: spAddend)
            )
        }
        static func emit(to emitSlot: @escaping ((Self) -> CodeSlot) -> Void) {
            emitSlot {
                let slot: Slot1 = ($0.tableIndex, $0.type)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
            emitSlot {
                let slot: Slot2 = ($0.index, $0.callLike.spAddend, 0)
                return unsafeBitCast(slot, to: CodeSlot.self)
            }
        }
    }

    typealias OnEnterOperand = FunctionIndex
    typealias OnExitOperand = FunctionIndex
    
    struct BinaryOperandSS: Equatable, InstructionImmediate {
        let lhs: LVReg
        let rhs: LVReg
    }
    struct BinaryOperandSR: Equatable, InstructionImmediate {
        let lhs: LLVReg
        init(_ lhs: VReg) {
            self.lhs = LLVReg(lhs)
        }
    }
    struct BinaryOperandRS: Equatable, InstructionImmediate {
        let rhs: LLVReg
        init(_ rhs: VReg) {
            self.rhs = LLVReg(rhs)
        }
    }
    struct NonCommutative {
        let ss: (BinaryOperandSS) -> Instruction
        let sr: (BinaryOperandSR) -> Instruction
        let rs: (BinaryOperandRS) -> Instruction
    }

    struct Commutative {
        let ss: (BinaryOperandSS) -> Instruction
        let sr: (BinaryOperandSR) -> Instruction
    }

    struct LoadInfo {
        let s: (LoadOperandS) -> Instruction
        let r: (LoadOperandR) -> Instruction
    }
}

struct InstructionPrintingContext {
    let shouldColor: Bool
    let function: Function
    var nameRegistry: NameRegistry

    func reg<R: FixedWidthInteger>(_ reg: R) -> String {
        let adjusted = R(StackLayout.frameHeaderSize(type: function.type)) + reg
        if shouldColor {
            let regColor = adjusted < 15 ? "\u{001B}[3\(adjusted + 1)m" : ""
            return "\(regColor)reg:\(reg)\u{001B}[0m"
        } else {
            return "reg:\(reg)"
        }
    }

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
//        case .globalGet(let op):
//            target.write("\(reg(op.result)) = global.get \(global(op.global))")
//        case .globalSet(let op):
//            target.write("global.set \(global(op.global)), \(reg(op.value))")
//        case .numericConst(let op):
//            target.write("\(reg(op.result)) = \(value(op.value))")
//        case .call(let op):
//            target.write("call \(callee(op.callee)), sp: +\(op.callLike.spAddend)")
//        case .callIndirect(let op):
//            target.write("call_indirect \(reg(op.index)), \(op.tableIndex), (func_ty id:\(op.type.id)), sp: +\(op.callLike.spAddend)")
//        case .compilingCall(let op):
//            target.write("compiling_call \(callee(op.callee)), sp: +\(op.callLike.spAddend)")
//        case .i32Load(let op):
//            target.write("\(reg(op.result)) = i32.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .i64Load(let op):
//            target.write("\(reg(op.result)) = i64.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .f32Load(let op):
//            target.write("\(reg(op.result)) = f32.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .f64Load(let op):
//            target.write("\(reg(op.result)) = f64.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .copyStack(let op):
//            target.write("\(reg(op.dest)) = copy \(reg(op.source))")
//        case .i32Add(let op):
//            target.write("\(reg(op.result)) = i32.add \(reg(op.lhs)), \(reg(op.rhs))")
//        case .i32Sub(let op):
//            target.write("\(reg(op.result)) = i32.sub \(reg(op.lhs)), \(reg(op.rhs))")
//        case .i32LtU(let op):
//            target.write("\(reg(op.result)) = i32.lt_u \(reg(op.lhs)), \(reg(op.rhs))")
//        case .i32Eq(let op):
//            target.write("\(reg(op.result)) = i32.eq \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eqz(let op):
            target.write("\(reg(op.result)) = i32.eqz \(reg(op.input))")
//        case .i32Store(let op):
//            target.write("i32.store \(reg(op.pointer)), \(reg(op.value)), \(memarg(op.memarg))")
        case .brIfNot(let op):
            target.write("br_if_not \(reg(op.condition)), +\(op.offset)")
        case .brIf(let op):
            target.write("br_if \(reg(op.condition)), +\(op.offset)")
        case .br(let offset):
            target.write("br \(offset > 0 ? "+" : "")\(offset)")
        case ._return:
            target.write("return")
        default:
            target.write(String(describing: instruction))
        }
    }
}
