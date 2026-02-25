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
            emit("call_indirect \(tbl == 0 ? "" : "\(tbl) ")(type \(ti))")
        case .returnCall(let fi):
            emit("return_call \(funcRef(fi))")
        case .returnCallIndirect(let ti, let tbl):
            emit("return_call_indirect \(tbl == 0 ? "" : "\(tbl) ")(type \(ti))")
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
            emit("\(generatedMnemonic(for: kind))\(memargText(m, defaultAlign: generatedDefaultAlign(for: kind)))")
        case .store(let kind, let m):
            emit("\(generatedMnemonic(for: kind))\(memargText(m, defaultAlign: generatedDefaultAlign(for: kind)))")
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
        case .cmp(let op): emit(generatedMnemonic(for: op))

        // ── Numeric ──────────────────────────────────────────────────────────
        case .unary(let op): emit(generatedMnemonic(for: op))
        case .binary(let op): emit(generatedMnemonic(for: op))
        case .conversion(let op): emit(generatedMnemonic(for: op))

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

        // ── SIMD ─────────────────────────────────────────────────────────────
        case .v128Const(let v):
            let bytes = v.bytes.map { String($0) }.joined(separator: " ")
            emit("v128.const i8x16 \(bytes)")
        case .i8x16Shuffle(let mask):
            let lanes = mask.lanes.map { String($0) }.joined(separator: " ")
            emit("i8x16.shuffle \(lanes)")
        case .simd(let op): emit(generatedMnemonic(for: op))
        case .simdLane(let op, let lane): emit("\(generatedMnemonic(for: op)) \(lane)")
        case .simdMemLane(let op, let m, let lane):
            emit("\(generatedMnemonic(for: op))\(memargText(m, defaultAlign: generatedDefaultAlign(for: op))) \(lane)")

        // ── Non-categorized memarg instructions ──────────────
        default:
            if let (mnemonic, m, align) = generatedMemargInstruction(instruction) {
                emit("\(mnemonic)\(memargText(m, defaultAlign: align))")
            }
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
        let payload = v.bitPattern & 0x7FFFFF
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
    // f32 mantissa is 23 bits; shift left by 1 to fill 24 bits (6 hex digits).
    let mantHex = String(format: "%06x", mantissa << 1)
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
    // Use Swift's native radix formatting to avoid %x truncating UInt64 to 32 bits.
    let rawHex = String(mantissa, radix: 16)
    let mantHex = String(repeating: "0", count: max(0, 13 - rawHex.count)) + rawHex
    let trimmed = String(mantHex.reversed().drop(while: { $0 == "0" }).reversed())
    let mant = trimmed.isEmpty ? "" : ".\(trimmed)"
    let eSign = e >= 0 ? "+" : ""
    return "\(sign)0x1\(mant)p\(eSign)\(e)"
}
