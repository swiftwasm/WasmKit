import Foundation
import WasmParser
import WasmTypes

/// A visitor that emits WAT text for each WebAssembly instruction.
/// Conforms to `AnyInstructionVisitor` to handle all instructions via a single switch.
struct TextInstructionVisitor: AnyInstructionVisitor {
    typealias VisitorError = Never

    var binaryOffset: Int = 0

    // MARK: - Context

    /// Module-wide function names (function index → name).
    let functionNames: [UInt32: String]
    /// Module-wide global names (global index → name).
    let globalNames: [UInt32: String]
    /// Local variable names for the current function (local index → name).
    let localNames: [UInt32: String]

    // MARK: - Output

    private var indentLevel: Int
    private let append: (String) -> Void

    // MARK: - Label stack

    /// Stack of labels pushed by block/loop/if. Empty at function body start.
    private var labelStack: [String] = []

    init(
        functionNames: [UInt32: String],
        globalNames: [UInt32: String],
        localNames: [UInt32: String],
        indentLevel: Int,
        append: @escaping (String) -> Void
    ) {
        self.functionNames = functionNames
        self.globalNames = globalNames
        self.localNames = localNames
        self.indentLevel = indentLevel
        self.append = append
    }

    // MARK: - AnyInstructionVisitor

    mutating func visit(_ instruction: Instruction) {
        switch instruction {
        // ── Control ──────────────────────────────────────────────────────────
        case .unreachable:
            emit("unreachable")
        case .nop:
            emit("nop")
        case .block(let blockType):
            let blockLabel = "block_\(labelStack.count)"
            labelStack.append(blockLabel)
            emit("block $\(blockLabel)\(blockTypeSuffix(blockType))")
            indentLevel += 1
        case .loop(let blockType):
            let loopLabel = "loop_\(labelStack.count)"
            labelStack.append(loopLabel)
            emit("loop $\(loopLabel)\(blockTypeSuffix(blockType))")
            indentLevel += 1
        case .if(let blockType):
            let ifLabel = "if_\(labelStack.count)"
            labelStack.append(ifLabel)
            emit("if $\(ifLabel)\(blockTypeSuffix(blockType))")
            indentLevel += 1
        case .else:
            indentLevel -= 1
            emit("else")
            indentLevel += 1
        case .end:
            if labelStack.isEmpty {
                // Function body end – represented by closing ')' in (func ...), skip.
                return
            }
            labelStack.removeLast()
            indentLevel -= 1
            emit("end")
        case .br(let d):
            emit("br \(labelText(d))")
        case .brIf(let d):
            emit("br_if \(labelText(d))")
        case .brTable(let tbl):
            var parts = tbl.labelIndices.map { labelText($0) }
            parts.append(labelText(tbl.defaultIndex))
            emit("br_table \(parts.joined(separator: " "))")
        case .return:
            emit("return")
        case .call(let fi):
            emit("call \(funcRef(fi))")
        case .callIndirect(let ti, let tbl):
            emit("call_indirect \(tbl == 0 ? "" : "(table \(tbl)) ")(type \(ti))")
        case .returnCall(let fi):
            emit("return_call \(funcRef(fi))")
        case .returnCallIndirect(let ti, let tbl):
            emit("return_call_indirect \(tbl == 0 ? "" : "(table \(tbl)) ")(type \(ti))")
        case .callRef(let ti):
            emit("call_ref (type \(ti))")
        case .returnCallRef(let ti):
            emit("return_call_ref (type \(ti))")
        case .drop:
            emit("drop")
        case .select:
            emit("select")
        case .typedSelect(let t):
            emit("select (result \(valueTypeName(t)))")

        // ── Variables ────────────────────────────────────────────────────────
        case .localGet(let i):
            emit("local.get \(localRef(i))")
        case .localSet(let i):
            emit("local.set \(localRef(i))")
        case .localTee(let i):
            emit("local.tee \(localRef(i))")
        case .globalGet(let i):
            emit("global.get \(globalRef(i))")
        case .globalSet(let i):
            emit("global.set \(globalRef(i))")

        // ── Memory ───────────────────────────────────────────────────────────
        case .load(let kind, let m):
            emit("\(loadMnemonic(kind))\(memargText(m, defaultAlign: defaultLoadAlign(kind)))")
        case .store(let kind, let m):
            emit("\(storeMnemonic(kind))\(memargText(m, defaultAlign: defaultStoreAlign(kind)))")
        case .memorySize(let mem):
            emit(mem == 0 ? "memory.size" : "memory.size \(mem)")
        case .memoryGrow(let mem):
            emit(mem == 0 ? "memory.grow" : "memory.grow \(mem)")

        // ── Constants ────────────────────────────────────────────────────────
        case .i32Const(let v):
            emit("i32.const \(v)")
        case .i64Const(let v):
            emit("i64.const \(v)")
        case .f32Const(let v):
            emit("f32.const \(formatF32(v))")
        case .f64Const(let v):
            emit("f64.const \(formatF64(v))")

        // ── References ───────────────────────────────────────────────────────
        case .refNull(let ht):
            emit("ref.null \(heapTypeName(ht))")
        case .refIsNull:
            emit("ref.is_null")
        case .refFunc(let fi):
            emit("ref.func \(funcRef(fi))")
        case .refAsNonNull:
            emit("ref.as_non_null")
        case .brOnNull(let d):
            emit("br_on_null \(labelText(d))")
        case .brOnNonNull(let d):
            emit("br_on_non_null \(labelText(d))")

        // ── Comparison ───────────────────────────────────────────────────────
        case .i32Eqz: emit("i32.eqz")
        case .i64Eqz: emit("i64.eqz")
        case .cmp(let op): emit(cmpMnemonic(op))

        // ── Numeric ──────────────────────────────────────────────────────────
        case .unary(let op): emit(unaryMnemonic(op))
        case .binary(let op): emit(binaryMnemonic(op))
        case .conversion(let op): emit(conversionMnemonic(op))

        // ── Bulk memory / table ──────────────────────────────────────────────
        case .memoryInit(let di):
            emit("memory.init \(di)")
        case .dataDrop(let di):
            emit("data.drop \(di)")
        case .memoryCopy(let dst, let src):
            if dst == 0 && src == 0 { emit("memory.copy") } else { emit("memory.copy \(dst) \(src)") }
        case .memoryFill(let mem):
            emit(mem == 0 ? "memory.fill" : "memory.fill \(mem)")
        case .tableInit(let ei, let tbl):
            emit("table.init \(tbl) \(ei)")
        case .elemDrop(let ei):
            emit("elem.drop \(ei)")
        case .tableCopy(let dst, let src):
            if dst == 0 && src == 0 { emit("table.copy") } else { emit("table.copy \(dst) \(src)") }
        case .tableFill(let tbl):
            emit(tbl == 0 ? "table.fill" : "table.fill \(tbl)")
        case .tableGet(let tbl):
            emit(tbl == 0 ? "table.get" : "table.get \(tbl)")
        case .tableSet(let tbl):
            emit(tbl == 0 ? "table.set" : "table.set \(tbl)")
        case .tableGrow(let tbl):
            emit(tbl == 0 ? "table.grow" : "table.grow \(tbl)")
        case .tableSize(let tbl):
            emit(tbl == 0 ? "table.size" : "table.size \(tbl)")

        // ── Atomics ──────────────────────────────────────────────────────────
        case .atomicFence:
            emit("atomic.fence")
        case .memoryAtomicNotify(let m): emit("memory.atomic.notify\(memargText(m, defaultAlign: 2))")
        case .memoryAtomicWait32(let m): emit("memory.atomic.wait32\(memargText(m, defaultAlign: 2))")
        case .memoryAtomicWait64(let m): emit("memory.atomic.wait64\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmwAdd(let m): emit("i32.atomic.rmw.add\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwAdd(let m): emit("i64.atomic.rmw.add\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8AddU(let m): emit("i32.atomic.rmw8.add_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16AddU(let m): emit("i32.atomic.rmw16.add_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8AddU(let m): emit("i64.atomic.rmw8.add_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16AddU(let m): emit("i64.atomic.rmw16.add_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32AddU(let m): emit("i64.atomic.rmw32.add_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwSub(let m): emit("i32.atomic.rmw.sub\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwSub(let m): emit("i64.atomic.rmw.sub\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8SubU(let m): emit("i32.atomic.rmw8.sub_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16SubU(let m): emit("i32.atomic.rmw16.sub_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8SubU(let m): emit("i64.atomic.rmw8.sub_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16SubU(let m): emit("i64.atomic.rmw16.sub_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32SubU(let m): emit("i64.atomic.rmw32.sub_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwAnd(let m): emit("i32.atomic.rmw.and\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwAnd(let m): emit("i64.atomic.rmw.and\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8AndU(let m): emit("i32.atomic.rmw8.and_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16AndU(let m): emit("i32.atomic.rmw16.and_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8AndU(let m): emit("i64.atomic.rmw8.and_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16AndU(let m): emit("i64.atomic.rmw16.and_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32AndU(let m): emit("i64.atomic.rmw32.and_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwOr(let m): emit("i32.atomic.rmw.or\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwOr(let m): emit("i64.atomic.rmw.or\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8OrU(let m): emit("i32.atomic.rmw8.or_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16OrU(let m): emit("i32.atomic.rmw16.or_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8OrU(let m): emit("i64.atomic.rmw8.or_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16OrU(let m): emit("i64.atomic.rmw16.or_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32OrU(let m): emit("i64.atomic.rmw32.or_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwXor(let m): emit("i32.atomic.rmw.xor\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwXor(let m): emit("i64.atomic.rmw.xor\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8XorU(let m): emit("i32.atomic.rmw8.xor_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16XorU(let m): emit("i32.atomic.rmw16.xor_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8XorU(let m): emit("i64.atomic.rmw8.xor_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16XorU(let m): emit("i64.atomic.rmw16.xor_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32XorU(let m): emit("i64.atomic.rmw32.xor_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwXchg(let m): emit("i32.atomic.rmw.xchg\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwXchg(let m): emit("i64.atomic.rmw.xchg\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8XchgU(let m): emit("i32.atomic.rmw8.xchg_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16XchgU(let m): emit("i32.atomic.rmw16.xchg_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8XchgU(let m): emit("i64.atomic.rmw8.xchg_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16XchgU(let m): emit("i64.atomic.rmw16.xchg_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32XchgU(let m): emit("i64.atomic.rmw32.xchg_u\(memargText(m, defaultAlign: 2))")
        case .i32AtomicRmwCmpxchg(let m): emit("i32.atomic.rmw.cmpxchg\(memargText(m, defaultAlign: 2))")
        case .i64AtomicRmwCmpxchg(let m): emit("i64.atomic.rmw.cmpxchg\(memargText(m, defaultAlign: 3))")
        case .i32AtomicRmw8CmpxchgU(let m): emit("i32.atomic.rmw8.cmpxchg_u\(memargText(m, defaultAlign: 0))")
        case .i32AtomicRmw16CmpxchgU(let m): emit("i32.atomic.rmw16.cmpxchg_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw8CmpxchgU(let m): emit("i64.atomic.rmw8.cmpxchg_u\(memargText(m, defaultAlign: 0))")
        case .i64AtomicRmw16CmpxchgU(let m): emit("i64.atomic.rmw16.cmpxchg_u\(memargText(m, defaultAlign: 1))")
        case .i64AtomicRmw32CmpxchgU(let m): emit("i64.atomic.rmw32.cmpxchg_u\(memargText(m, defaultAlign: 2))")

        // ── SIMD ─────────────────────────────────────────────────────────────
        case .v128Const(let v):
            let bytes = v.bytes.map { String($0) }.joined(separator: " ")
            emit("v128.const i8x16 \(bytes)")
        case .i8x16Shuffle(let mask):
            let lanes = mask.lanes.map { String($0) }.joined(separator: " ")
            emit("i8x16.shuffle \(lanes)")
        case .simd(let op): emit(simdMnemonic(op))
        case .simdLane(let op, let lane): emit("\(simdLaneMnemonic(op)) \(lane)")
        case .simdMemLane(let op, let m, let lane):
            emit("\(simdMemLaneMnemonic(op))\(memargText(m, defaultAlign: simdMemLaneDefaultAlign(op))) \(lane)")
        }
    }

    // MARK: - Emit helper

    private func emit(_ text: String) {
        let indent = String(repeating: "  ", count: indentLevel)
        append(indent + text + "\n")
    }

    // MARK: - Label helpers

    private func labelText(_ relativeDepth: UInt32) -> String {
        let idx = Int(relativeDepth)
        let stackIdx = labelStack.count - 1 - idx
        if stackIdx >= 0 {
            return "$\(labelStack[stackIdx])"
        }
        return "\(relativeDepth)"
    }

    // MARK: - Name helpers

    private func funcRef(_ idx: UInt32) -> String {
        if let name = functionNames[idx] { return "$\(name)" }
        return "\(idx)"
    }

    private func globalRef(_ idx: UInt32) -> String {
        if let name = globalNames[idx] { return "$\(name)" }
        return "\(idx)"
    }

    private func localRef(_ idx: UInt32) -> String {
        if let name = localNames[idx] { return "$\(name)" }
        return "\(idx)"
    }

    // MARK: - BlockType suffix

    private func blockTypeSuffix(_ bt: BlockType) -> String {
        switch bt {
        case .empty: return ""
        case .type(let vt): return " (result \(valueTypeName(vt)))"
        case .funcType(let ti): return " (type \(ti))"
        }
    }

    // MARK: - MemArg

    private func memargText(_ m: MemArg, defaultAlign: UInt32) -> String {
        var parts: [String] = []
        if m.offset != 0 { parts.append("offset=\(m.offset)") }
        if m.align != defaultAlign { parts.append("align=\(1 << m.align)") }
        if parts.isEmpty { return "" }
        return " " + parts.joined(separator: " ")
    }

    // MARK: - Default alignments for load/store

    private func defaultLoadAlign(_ k: Instruction.Load) -> UInt32 {
        switch k {
        case .i32Load8S, .i32Load8U, .i64Load8S, .i64Load8U,
            .i32AtomicLoad8U, .i64AtomicLoad8U:
            return 0
        case .i32Load16S, .i32Load16U, .i64Load16S, .i64Load16U,
            .i32AtomicLoad16U, .i64AtomicLoad16U:
            return 1
        case .i32Load, .f32Load,
            .i64Load32S, .i64Load32U,
            .i32AtomicLoad, .i64AtomicLoad32U:
            return 2
        case .i64Load, .f64Load, .i64AtomicLoad: return 3
        case .v128Load, .v128Load8X8S, .v128Load8X8U,
            .v128Load16X4S, .v128Load16X4U,
            .v128Load32X2S, .v128Load32X2U,
            .v128Load32Zero, .v128Load64Zero:
            return 4
        case .v128Load8Splat: return 0
        case .v128Load16Splat: return 1
        case .v128Load32Splat: return 2
        case .v128Load64Splat: return 3
        }
    }

    private func defaultStoreAlign(_ k: Instruction.Store) -> UInt32 {
        switch k {
        case .i32Store8, .i64Store8, .i32AtomicStore8, .i64AtomicStore8: return 0
        case .i32Store16, .i64Store16, .i32AtomicStore16, .i64AtomicStore16: return 1
        case .i32Store, .f32Store, .i64Store32, .i32AtomicStore, .i64AtomicStore32: return 2
        case .i64Store, .f64Store, .i64AtomicStore: return 3
        case .v128Store: return 4
        }
    }

    // MARK: - Load/store mnemonics

    private func loadMnemonic(_ k: Instruction.Load) -> String {
        switch k {
        case .i32Load: return "i32.load"
        case .i64Load: return "i64.load"
        case .f32Load: return "f32.load"
        case .f64Load: return "f64.load"
        case .i32Load8S: return "i32.load8_s"
        case .i32Load8U: return "i32.load8_u"
        case .i32Load16S: return "i32.load16_s"
        case .i32Load16U: return "i32.load16_u"
        case .i64Load8S: return "i64.load8_s"
        case .i64Load8U: return "i64.load8_u"
        case .i64Load16S: return "i64.load16_s"
        case .i64Load16U: return "i64.load16_u"
        case .i64Load32S: return "i64.load32_s"
        case .i64Load32U: return "i64.load32_u"
        case .i32AtomicLoad: return "i32.atomic.load"
        case .i64AtomicLoad: return "i64.atomic.load"
        case .i32AtomicLoad8U: return "i32.atomic.load8_u"
        case .i32AtomicLoad16U: return "i32.atomic.load16_u"
        case .i64AtomicLoad8U: return "i64.atomic.load8_u"
        case .i64AtomicLoad16U: return "i64.atomic.load16_u"
        case .i64AtomicLoad32U: return "i64.atomic.load32_u"
        case .v128Load: return "v128.load"
        case .v128Load8X8S: return "v128.load8x8_s"
        case .v128Load8X8U: return "v128.load8x8_u"
        case .v128Load16X4S: return "v128.load16x4_s"
        case .v128Load16X4U: return "v128.load16x4_u"
        case .v128Load32X2S: return "v128.load32x2_s"
        case .v128Load32X2U: return "v128.load32x2_u"
        case .v128Load8Splat: return "v128.load8_splat"
        case .v128Load16Splat: return "v128.load16_splat"
        case .v128Load32Splat: return "v128.load32_splat"
        case .v128Load64Splat: return "v128.load64_splat"
        case .v128Load32Zero: return "v128.load32_zero"
        case .v128Load64Zero: return "v128.load64_zero"
        }
    }

    private func storeMnemonic(_ k: Instruction.Store) -> String {
        switch k {
        case .i32Store: return "i32.store"
        case .i64Store: return "i64.store"
        case .f32Store: return "f32.store"
        case .f64Store: return "f64.store"
        case .i32Store8: return "i32.store8"
        case .i32Store16: return "i32.store16"
        case .i64Store8: return "i64.store8"
        case .i64Store16: return "i64.store16"
        case .i64Store32: return "i64.store32"
        case .i32AtomicStore: return "i32.atomic.store"
        case .i64AtomicStore: return "i64.atomic.store"
        case .i32AtomicStore8: return "i32.atomic.store8"
        case .i32AtomicStore16: return "i32.atomic.store16"
        case .i64AtomicStore8: return "i64.atomic.store8"
        case .i64AtomicStore16: return "i64.atomic.store16"
        case .i64AtomicStore32: return "i64.atomic.store32"
        case .v128Store: return "v128.store"
        }
    }

    // MARK: - Cmp/unary/binary/conversion mnemonics

    private func cmpMnemonic(_ op: Instruction.Cmp) -> String {
        switch op {
        case .i32Eq: return "i32.eq"
        case .i32Ne: return "i32.ne"
        case .i32LtS: return "i32.lt_s"
        case .i32LtU: return "i32.lt_u"
        case .i32GtS: return "i32.gt_s"
        case .i32GtU: return "i32.gt_u"
        case .i32LeS: return "i32.le_s"
        case .i32LeU: return "i32.le_u"
        case .i32GeS: return "i32.ge_s"
        case .i32GeU: return "i32.ge_u"
        case .i64Eq: return "i64.eq"
        case .i64Ne: return "i64.ne"
        case .i64LtS: return "i64.lt_s"
        case .i64LtU: return "i64.lt_u"
        case .i64GtS: return "i64.gt_s"
        case .i64GtU: return "i64.gt_u"
        case .i64LeS: return "i64.le_s"
        case .i64LeU: return "i64.le_u"
        case .i64GeS: return "i64.ge_s"
        case .i64GeU: return "i64.ge_u"
        case .f32Eq: return "f32.eq"
        case .f32Ne: return "f32.ne"
        case .f32Lt: return "f32.lt"
        case .f32Gt: return "f32.gt"
        case .f32Le: return "f32.le"
        case .f32Ge: return "f32.ge"
        case .f64Eq: return "f64.eq"
        case .f64Ne: return "f64.ne"
        case .f64Lt: return "f64.lt"
        case .f64Gt: return "f64.gt"
        case .f64Le: return "f64.le"
        case .f64Ge: return "f64.ge"
        }
    }

    private func unaryMnemonic(_ op: Instruction.Unary) -> String {
        switch op {
        case .i32Clz: return "i32.clz"
        case .i32Ctz: return "i32.ctz"
        case .i32Popcnt: return "i32.popcnt"
        case .i64Clz: return "i64.clz"
        case .i64Ctz: return "i64.ctz"
        case .i64Popcnt: return "i64.popcnt"
        case .f32Abs: return "f32.abs"
        case .f32Neg: return "f32.neg"
        case .f32Ceil: return "f32.ceil"
        case .f32Floor: return "f32.floor"
        case .f32Trunc: return "f32.trunc"
        case .f32Nearest: return "f32.nearest"
        case .f32Sqrt: return "f32.sqrt"
        case .f64Abs: return "f64.abs"
        case .f64Neg: return "f64.neg"
        case .f64Ceil: return "f64.ceil"
        case .f64Floor: return "f64.floor"
        case .f64Trunc: return "f64.trunc"
        case .f64Nearest: return "f64.nearest"
        case .f64Sqrt: return "f64.sqrt"
        case .i32Extend8S: return "i32.extend8_s"
        case .i32Extend16S: return "i32.extend16_s"
        case .i64Extend8S: return "i64.extend8_s"
        case .i64Extend16S: return "i64.extend16_s"
        case .i64Extend32S: return "i64.extend32_s"
        }
    }

    private func binaryMnemonic(_ op: Instruction.Binary) -> String {
        switch op {
        case .i32Add: return "i32.add"
        case .i32Sub: return "i32.sub"
        case .i32Mul: return "i32.mul"
        case .i32DivS: return "i32.div_s"
        case .i32DivU: return "i32.div_u"
        case .i32RemS: return "i32.rem_s"
        case .i32RemU: return "i32.rem_u"
        case .i32And: return "i32.and"
        case .i32Or: return "i32.or"
        case .i32Xor: return "i32.xor"
        case .i32Shl: return "i32.shl"
        case .i32ShrS: return "i32.shr_s"
        case .i32ShrU: return "i32.shr_u"
        case .i32Rotl: return "i32.rotl"
        case .i32Rotr: return "i32.rotr"
        case .i64Add: return "i64.add"
        case .i64Sub: return "i64.sub"
        case .i64Mul: return "i64.mul"
        case .i64DivS: return "i64.div_s"
        case .i64DivU: return "i64.div_u"
        case .i64RemS: return "i64.rem_s"
        case .i64RemU: return "i64.rem_u"
        case .i64And: return "i64.and"
        case .i64Or: return "i64.or"
        case .i64Xor: return "i64.xor"
        case .i64Shl: return "i64.shl"
        case .i64ShrS: return "i64.shr_s"
        case .i64ShrU: return "i64.shr_u"
        case .i64Rotl: return "i64.rotl"
        case .i64Rotr: return "i64.rotr"
        case .f32Add: return "f32.add"
        case .f32Sub: return "f32.sub"
        case .f32Mul: return "f32.mul"
        case .f32Div: return "f32.div"
        case .f32Min: return "f32.min"
        case .f32Max: return "f32.max"
        case .f32Copysign: return "f32.copysign"
        case .f64Add: return "f64.add"
        case .f64Sub: return "f64.sub"
        case .f64Mul: return "f64.mul"
        case .f64Div: return "f64.div"
        case .f64Min: return "f64.min"
        case .f64Max: return "f64.max"
        case .f64Copysign: return "f64.copysign"
        }
    }

    private func conversionMnemonic(_ op: Instruction.Conversion) -> String {
        switch op {
        case .i32WrapI64: return "i32.wrap_i64"
        case .i32TruncF32S: return "i32.trunc_f32_s"
        case .i32TruncF32U: return "i32.trunc_f32_u"
        case .i32TruncF64S: return "i32.trunc_f64_s"
        case .i32TruncF64U: return "i32.trunc_f64_u"
        case .i64ExtendI32S: return "i64.extend_i32_s"
        case .i64ExtendI32U: return "i64.extend_i32_u"
        case .i64TruncF32S: return "i64.trunc_f32_s"
        case .i64TruncF32U: return "i64.trunc_f32_u"
        case .i64TruncF64S: return "i64.trunc_f64_s"
        case .i64TruncF64U: return "i64.trunc_f64_u"
        case .f32ConvertI32S: return "f32.convert_i32_s"
        case .f32ConvertI32U: return "f32.convert_i32_u"
        case .f32ConvertI64S: return "f32.convert_i64_s"
        case .f32ConvertI64U: return "f32.convert_i64_u"
        case .f32DemoteF64: return "f32.demote_f64"
        case .f64ConvertI32S: return "f64.convert_i32_s"
        case .f64ConvertI32U: return "f64.convert_i32_u"
        case .f64ConvertI64S: return "f64.convert_i64_s"
        case .f64ConvertI64U: return "f64.convert_i64_u"
        case .f64PromoteF32: return "f64.promote_f32"
        case .i32ReinterpretF32: return "i32.reinterpret_f32"
        case .i64ReinterpretF64: return "i64.reinterpret_f64"
        case .f32ReinterpretI32: return "f32.reinterpret_i32"
        case .f64ReinterpretI64: return "f64.reinterpret_i64"
        case .i32TruncSatF32S: return "i32.trunc_sat_f32_s"
        case .i32TruncSatF32U: return "i32.trunc_sat_f32_u"
        case .i32TruncSatF64S: return "i32.trunc_sat_f64_s"
        case .i32TruncSatF64U: return "i32.trunc_sat_f64_u"
        case .i64TruncSatF32S: return "i64.trunc_sat_f32_s"
        case .i64TruncSatF32U: return "i64.trunc_sat_f32_u"
        case .i64TruncSatF64S: return "i64.trunc_sat_f64_s"
        case .i64TruncSatF64U: return "i64.trunc_sat_f64_u"
        }
    }

    // MARK: - SIMD mnemonics

    private func simdMnemonic(_ op: Instruction.Simd) -> String {
        switch op {
        case .i8x16Eq: return "i8x16.eq"
        case .i8x16Ne: return "i8x16.ne"
        case .i8x16LtS: return "i8x16.lt_s"
        case .i8x16LtU: return "i8x16.lt_u"
        case .i8x16GtS: return "i8x16.gt_s"
        case .i8x16GtU: return "i8x16.gt_u"
        case .i8x16LeS: return "i8x16.le_s"
        case .i8x16LeU: return "i8x16.le_u"
        case .i8x16GeS: return "i8x16.ge_s"
        case .i8x16GeU: return "i8x16.ge_u"
        case .i16x8Eq: return "i16x8.eq"
        case .i16x8Ne: return "i16x8.ne"
        case .i16x8LtS: return "i16x8.lt_s"
        case .i16x8LtU: return "i16x8.lt_u"
        case .i16x8GtS: return "i16x8.gt_s"
        case .i16x8GtU: return "i16x8.gt_u"
        case .i16x8LeS: return "i16x8.le_s"
        case .i16x8LeU: return "i16x8.le_u"
        case .i16x8GeS: return "i16x8.ge_s"
        case .i16x8GeU: return "i16x8.ge_u"
        case .i32x4Eq: return "i32x4.eq"
        case .i32x4Ne: return "i32x4.ne"
        case .i32x4LtS: return "i32x4.lt_s"
        case .i32x4LtU: return "i32x4.lt_u"
        case .i32x4GtS: return "i32x4.gt_s"
        case .i32x4GtU: return "i32x4.gt_u"
        case .i32x4LeS: return "i32x4.le_s"
        case .i32x4LeU: return "i32x4.le_u"
        case .i32x4GeS: return "i32x4.ge_s"
        case .i32x4GeU: return "i32x4.ge_u"
        case .f32x4Eq: return "f32x4.eq"
        case .f32x4Ne: return "f32x4.ne"
        case .f32x4Lt: return "f32x4.lt"
        case .f32x4Gt: return "f32x4.gt"
        case .f32x4Le: return "f32x4.le"
        case .f32x4Ge: return "f32x4.ge"
        case .f64x2Eq: return "f64x2.eq"
        case .f64x2Ne: return "f64x2.ne"
        case .f64x2Lt: return "f64x2.lt"
        case .f64x2Gt: return "f64x2.gt"
        case .f64x2Le: return "f64x2.le"
        case .f64x2Ge: return "f64x2.ge"
        case .v128Not: return "v128.not"
        case .v128And: return "v128.and"
        case .v128Andnot: return "v128.andnot"
        case .v128Or: return "v128.or"
        case .v128Xor: return "v128.xor"
        case .v128Bitselect: return "v128.bitselect"
        case .v128AnyTrue: return "v128.any_true"
        case .i8x16Abs: return "i8x16.abs"
        case .i8x16Neg: return "i8x16.neg"
        case .i8x16AllTrue: return "i8x16.all_true"
        case .i8x16Bitmask: return "i8x16.bitmask"
        case .i8x16NarrowI16X8S: return "i8x16.narrow_i16x8_s"
        case .i8x16NarrowI16X8U: return "i8x16.narrow_i16x8_u"
        case .i8x16Shl: return "i8x16.shl"
        case .i8x16ShrS: return "i8x16.shr_s"
        case .i8x16ShrU: return "i8x16.shr_u"
        case .i8x16Add: return "i8x16.add"
        case .i8x16AddSatS: return "i8x16.add_sat_s"
        case .i8x16AddSatU: return "i8x16.add_sat_u"
        case .i8x16Sub: return "i8x16.sub"
        case .i8x16SubSatS: return "i8x16.sub_sat_s"
        case .i8x16SubSatU: return "i8x16.sub_sat_u"
        case .i8x16MinS: return "i8x16.min_s"
        case .i8x16MinU: return "i8x16.min_u"
        case .i8x16MaxS: return "i8x16.max_s"
        case .i8x16MaxU: return "i8x16.max_u"
        case .i8x16AvgrU: return "i8x16.avgr_u"
        case .i16x8Abs: return "i16x8.abs"
        case .i16x8Neg: return "i16x8.neg"
        case .i16x8AllTrue: return "i16x8.all_true"
        case .i16x8Bitmask: return "i16x8.bitmask"
        case .i16x8NarrowI32X4S: return "i16x8.narrow_i32x4_s"
        case .i16x8NarrowI32X4U: return "i16x8.narrow_i32x4_u"
        case .i16x8ExtendLowI8X16S: return "i16x8.extend_low_i8x16_s"
        case .i16x8ExtendHighI8X16S: return "i16x8.extend_high_i8x16_s"
        case .i16x8ExtendLowI8X16U: return "i16x8.extend_low_i8x16_u"
        case .i16x8ExtendHighI8X16U: return "i16x8.extend_high_i8x16_u"
        case .i16x8Shl: return "i16x8.shl"
        case .i16x8ShrS: return "i16x8.shr_s"
        case .i16x8ShrU: return "i16x8.shr_u"
        case .i16x8Add: return "i16x8.add"
        case .i16x8AddSatS: return "i16x8.add_sat_s"
        case .i16x8AddSatU: return "i16x8.add_sat_u"
        case .i16x8Sub: return "i16x8.sub"
        case .i16x8SubSatS: return "i16x8.sub_sat_s"
        case .i16x8SubSatU: return "i16x8.sub_sat_u"
        case .i16x8Mul: return "i16x8.mul"
        case .i16x8MinS: return "i16x8.min_s"
        case .i16x8MinU: return "i16x8.min_u"
        case .i16x8MaxS: return "i16x8.max_s"
        case .i16x8MaxU: return "i16x8.max_u"
        case .i16x8AvgrU: return "i16x8.avgr_u"
        case .i32x4Abs: return "i32x4.abs"
        case .i32x4Neg: return "i32x4.neg"
        case .i32x4AllTrue: return "i32x4.all_true"
        case .i32x4Bitmask: return "i32x4.bitmask"
        case .i32x4ExtendLowI16X8S: return "i32x4.extend_low_i16x8_s"
        case .i32x4ExtendHighI16X8S: return "i32x4.extend_high_i16x8_s"
        case .i32x4ExtendLowI16X8U: return "i32x4.extend_low_i16x8_u"
        case .i32x4ExtendHighI16X8U: return "i32x4.extend_high_i16x8_u"
        case .i32x4Shl: return "i32x4.shl"
        case .i32x4ShrS: return "i32x4.shr_s"
        case .i32x4ShrU: return "i32x4.shr_u"
        case .i32x4Add: return "i32x4.add"
        case .i32x4Sub: return "i32x4.sub"
        case .i32x4Mul: return "i32x4.mul"
        case .i32x4MinS: return "i32x4.min_s"
        case .i32x4MinU: return "i32x4.min_u"
        case .i32x4MaxS: return "i32x4.max_s"
        case .i32x4MaxU: return "i32x4.max_u"
        case .i32x4DotI16X8S: return "i32x4.dot_i16x8_s"
        case .i64x2Abs: return "i64x2.abs"
        case .i64x2Neg: return "i64x2.neg"
        case .i64x2Bitmask: return "i64x2.bitmask"
        case .i64x2ExtendLowI32X4S: return "i64x2.extend_low_i32x4_s"
        case .i64x2ExtendHighI32X4S: return "i64x2.extend_high_i32x4_s"
        case .i64x2ExtendLowI32X4U: return "i64x2.extend_low_i32x4_u"
        case .i64x2ExtendHighI32X4U: return "i64x2.extend_high_i32x4_u"
        case .i64x2Shl: return "i64x2.shl"
        case .i64x2ShrS: return "i64x2.shr_s"
        case .i64x2ShrU: return "i64x2.shr_u"
        case .i64x2Add: return "i64x2.add"
        case .i64x2Sub: return "i64x2.sub"
        case .i64x2Mul: return "i64x2.mul"
        case .f32x4Ceil: return "f32x4.ceil"
        case .f32x4Floor: return "f32x4.floor"
        case .f32x4Trunc: return "f32x4.trunc"
        case .f32x4Nearest: return "f32x4.nearest"
        case .f64x2Ceil: return "f64x2.ceil"
        case .f64x2Floor: return "f64x2.floor"
        case .f64x2Trunc: return "f64x2.trunc"
        case .f64x2Nearest: return "f64x2.nearest"
        case .f32x4Abs: return "f32x4.abs"
        case .f32x4Neg: return "f32x4.neg"
        case .f32x4Sqrt: return "f32x4.sqrt"
        case .f32x4Add: return "f32x4.add"
        case .f32x4Sub: return "f32x4.sub"
        case .f32x4Mul: return "f32x4.mul"
        case .f32x4Div: return "f32x4.div"
        case .f32x4Min: return "f32x4.min"
        case .f32x4Max: return "f32x4.max"
        case .f32x4Pmin: return "f32x4.pmin"
        case .f32x4Pmax: return "f32x4.pmax"
        case .f64x2Abs: return "f64x2.abs"
        case .f64x2Neg: return "f64x2.neg"
        case .f64x2Sqrt: return "f64x2.sqrt"
        case .f64x2Add: return "f64x2.add"
        case .f64x2Sub: return "f64x2.sub"
        case .f64x2Mul: return "f64x2.mul"
        case .f64x2Div: return "f64x2.div"
        case .f64x2Min: return "f64x2.min"
        case .f64x2Max: return "f64x2.max"
        case .f64x2Pmin: return "f64x2.pmin"
        case .f64x2Pmax: return "f64x2.pmax"
        case .i32x4TruncSatF32X4S: return "i32x4.trunc_sat_f32x4_s"
        case .i32x4TruncSatF32X4U: return "i32x4.trunc_sat_f32x4_u"
        case .f32x4ConvertI32X4S: return "f32x4.convert_i32x4_s"
        case .f32x4ConvertI32X4U: return "f32x4.convert_i32x4_u"
        case .i16x8ExtmulLowI8X16S: return "i16x8.extmul_low_i8x16_s"
        case .i16x8ExtmulHighI8X16S: return "i16x8.extmul_high_i8x16_s"
        case .i16x8ExtmulLowI8X16U: return "i16x8.extmul_low_i8x16_u"
        case .i16x8ExtmulHighI8X16U: return "i16x8.extmul_high_i8x16_u"
        case .i32x4ExtmulLowI16X8S: return "i32x4.extmul_low_i16x8_s"
        case .i32x4ExtmulHighI16X8S: return "i32x4.extmul_high_i16x8_s"
        case .i32x4ExtmulLowI16X8U: return "i32x4.extmul_low_i16x8_u"
        case .i32x4ExtmulHighI16X8U: return "i32x4.extmul_high_i16x8_u"
        case .i64x2ExtmulLowI32X4S: return "i64x2.extmul_low_i32x4_s"
        case .i64x2ExtmulHighI32X4S: return "i64x2.extmul_high_i32x4_s"
        case .i64x2ExtmulLowI32X4U: return "i64x2.extmul_low_i32x4_u"
        case .i64x2ExtmulHighI32X4U: return "i64x2.extmul_high_i32x4_u"
        case .i16x8Q15MulrSatS: return "i16x8.q15mulr_sat_s"
        case .i64x2Eq: return "i64x2.eq"
        case .i64x2Ne: return "i64x2.ne"
        case .i64x2LtS: return "i64x2.lt_s"
        case .i64x2GtS: return "i64x2.gt_s"
        case .i64x2LeS: return "i64x2.le_s"
        case .i64x2GeS: return "i64x2.ge_s"
        case .i64x2AllTrue: return "i64x2.all_true"
        case .f64x2ConvertLowI32X4S: return "f64x2.convert_low_i32x4_s"
        case .f64x2ConvertLowI32X4U: return "f64x2.convert_low_i32x4_u"
        case .i32x4TruncSatF64X2SZero: return "i32x4.trunc_sat_f64x2_s_zero"
        case .i32x4TruncSatF64X2UZero: return "i32x4.trunc_sat_f64x2_u_zero"
        case .f32x4DemoteF64X2Zero: return "f32x4.demote_f64x2_zero"
        case .f64x2PromoteLowF32X4: return "f64x2.promote_low_f32x4"
        case .i8x16Popcnt: return "i8x16.popcnt"
        case .i16x8ExtaddPairwiseI8X16S: return "i16x8.extadd_pairwise_i8x16_s"
        case .i16x8ExtaddPairwiseI8X16U: return "i16x8.extadd_pairwise_i8x16_u"
        case .i32x4ExtaddPairwiseI16X8S: return "i32x4.extadd_pairwise_i16x8_s"
        case .i32x4ExtaddPairwiseI16X8U: return "i32x4.extadd_pairwise_i16x8_u"
        case .i8x16Swizzle: return "i8x16.swizzle"
        case .i8x16Splat: return "i8x16.splat"
        case .i16x8Splat: return "i16x8.splat"
        case .i32x4Splat: return "i32x4.splat"
        case .i64x2Splat: return "i64x2.splat"
        case .f32x4Splat: return "f32x4.splat"
        case .f64x2Splat: return "f64x2.splat"
        }
    }

    private func simdLaneMnemonic(_ op: Instruction.SimdLane) -> String {
        switch op {
        case .i8x16ExtractLaneS: return "i8x16.extract_lane_s"
        case .i8x16ExtractLaneU: return "i8x16.extract_lane_u"
        case .i8x16ReplaceLane: return "i8x16.replace_lane"
        case .i16x8ExtractLaneS: return "i16x8.extract_lane_s"
        case .i16x8ExtractLaneU: return "i16x8.extract_lane_u"
        case .i16x8ReplaceLane: return "i16x8.replace_lane"
        case .i32x4ExtractLane: return "i32x4.extract_lane"
        case .i32x4ReplaceLane: return "i32x4.replace_lane"
        case .i64x2ExtractLane: return "i64x2.extract_lane"
        case .i64x2ReplaceLane: return "i64x2.replace_lane"
        case .f32x4ExtractLane: return "f32x4.extract_lane"
        case .f32x4ReplaceLane: return "f32x4.replace_lane"
        case .f64x2ExtractLane: return "f64x2.extract_lane"
        case .f64x2ReplaceLane: return "f64x2.replace_lane"
        }
    }

    private func simdMemLaneMnemonic(_ op: Instruction.SimdMemLane) -> String {
        switch op {
        case .v128Load8Lane: return "v128.load8_lane"
        case .v128Load16Lane: return "v128.load16_lane"
        case .v128Load32Lane: return "v128.load32_lane"
        case .v128Load64Lane: return "v128.load64_lane"
        case .v128Store8Lane: return "v128.store8_lane"
        case .v128Store16Lane: return "v128.store16_lane"
        case .v128Store32Lane: return "v128.store32_lane"
        case .v128Store64Lane: return "v128.store64_lane"
        }
    }

    private func simdMemLaneDefaultAlign(_ op: Instruction.SimdMemLane) -> UInt32 {
        switch op {
        case .v128Load8Lane, .v128Store8Lane: return 0
        case .v128Load16Lane, .v128Store16Lane: return 1
        case .v128Load32Lane, .v128Store32Lane: return 2
        case .v128Load64Lane, .v128Store64Lane: return 3
        }
    }
}

// MARK: - Module-level formatting helpers (used by both WatPrinter and TextInstructionVisitor)

func valueTypeName(_ vt: ValueType) -> String {
    switch vt {
    case .i32: return "i32"
    case .i64: return "i64"
    case .f32: return "f32"
    case .f64: return "f64"
    case .v128: return "v128"
    case .ref(let rt):
        return refTypeName(rt)
    }
}

func refTypeName(_ rt: ReferenceType) -> String {
    let base = heapTypeName(rt.heapType)
    if rt.isNullable {
        // funcref and externref are canonical shorthands
        if rt.heapType == .funcRef { return "funcref" }
        if rt.heapType == .externRef { return "externref" }
        return "(ref null \(base))"
    }
    return "(ref \(base))"
}

func heapTypeName(_ ht: HeapType) -> String {
    switch ht {
    case .abstract(let abs):
        switch abs {
        case .funcRef: return "func"
        case .externRef: return "extern"
        }
    case .concrete(let ti):
        return "\(ti)"
    }
}

func formatF32(_ v: IEEE754.Float32) -> String {
    let f = Float32(bitPattern: v.bitPattern)
    if f.isNaN {
        // Preserve NaN payload for exact round-trip.
        let payload = v.bitPattern & 0x3FFFFF
        let signStr = (v.bitPattern & 0x8000_0000) != 0 ? "-" : ""
        if payload == 0x400000 {
            return "\(signStr)nan"  // canonical NaN
        }
        return "\(signStr)nan:0x\(String(payload, radix: 16))"
    }
    if f.isInfinite { return f > 0 ? "inf" : "-inf" }
    // Use hex float for exact round-trip.
    return hexFloat32(v.bitPattern)
}

func formatF64(_ v: IEEE754.Float64) -> String {
    let f = Double(bitPattern: v.bitPattern)
    if f.isNaN {
        let payload = v.bitPattern & 0x000F_FFFF_FFFF_FFFF
        let signStr = (v.bitPattern & 0x8000_0000_0000_0000) != 0 ? "-" : ""
        if payload == 0x0008_0000_0000_0000 {
            return "\(signStr)nan"  // canonical NaN
        }
        return "\(signStr)nan:0x\(String(payload, radix: 16))"
    }
    if f.isInfinite { return f > 0 ? "inf" : "-inf" }
    return hexFloat64(v.bitPattern)
}

/// Formats a 32-bit float bit pattern as a WAT hex float string.
private func hexFloat32(_ bits: UInt32) -> String {
    let sign = (bits >> 31) != 0 ? "-" : ""
    let exp = Int((bits >> 23) & 0xFF)
    let mantissa = bits & 0x7FFFFF

    if exp == 0 {
        // Subnormal or zero
        if mantissa == 0 { return "\(sign)0x0p+0" }
        // Subnormal: no implicit leading 1
        return "\(sign)0x\(String(mantissa, radix: 16))p-149"
    }
    // Normal: exponent biased by 127, implicit leading 1
    let e = exp - 127
    let mantHex = String(format: "%06x", mantissa)
    // Trim trailing zeros
    let trimmed =
        mantHex.hasSuffix("000000")
        ? String(mantHex.dropLast(6))
        : mantHex.hasSuffix("0000") ? String(mantHex.dropLast(4)) : mantHex.hasSuffix("00") ? String(mantHex.dropLast(2)) : mantHex.hasSuffix("0") ? String(mantHex.dropLast(1)) : mantHex
    let mant = trimmed.isEmpty ? "" : ".\(trimmed)"
    let eSign = e >= 0 ? "+" : ""
    return "\(sign)0x1\(mant)p\(eSign)\(e)"
}

/// Formats a 64-bit float bit pattern as a WAT hex float string.
private func hexFloat64(_ bits: UInt64) -> String {
    let sign = (bits >> 63) != 0 ? "-" : ""
    let exp = Int((bits >> 52) & 0x7FF)
    let mantissa = bits & 0x000F_FFFF_FFFF_FFFF

    if exp == 0 {
        if mantissa == 0 { return "\(sign)0x0p+0" }
        return "\(sign)0x\(String(mantissa, radix: 16))p-1074"
    }
    let e = exp - 1023
    let mantHex = String(format: "%013x", mantissa)
    let trimmed = String(mantHex.reversed().drop(while: { $0 == "0" }).reversed())
    let mant = trimmed.isEmpty ? "" : ".\(trimmed)"
    let eSign = e >= 0 ? "+" : ""
    return "\(sign)0x1\(mant)p\(eSign)\(e)"
}
