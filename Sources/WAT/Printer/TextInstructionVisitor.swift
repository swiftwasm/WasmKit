import WasmParser
import WasmTypes

/// A visitor that emits WAT text for each WebAssembly instruction.
struct TextInstructionVisitor: AnyInstructionVisitor {
    typealias VisitorError = WasmParserError

    var binaryOffset: Int = 0

    // MARK: - Context

    let names: ModuleNames
    let locals: IdentifierTable
    /// Label ids by name-section label index, which numbers block, loop, if and
    /// try_table in order of appearance.
    let labelIds: [UInt32: String]

    // MARK: - Output

    private var indent: String
    private let append: (String) -> Void

    // MARK: - Label stack

    private struct OpenLabel {
        let id: String?
        /// Whether this is an `if` that has not had its `else` yet.
        var acceptsElse: Bool
    }

    /// The labels in scope, innermost last.
    private var labelStack: [OpenLabel] = []
    private var nextLabelIndex: UInt32 = 0

    init(
        names: ModuleNames,
        locals: IdentifierTable,
        labelIds: [UInt32: String],
        indentLevel: Int,
        append: @escaping (String) -> Void
    ) {
        self.names = names
        self.locals = locals
        self.labelIds = labelIds
        self.indent = String(repeating: "  ", count: indentLevel)
        self.append = append
    }

    // MARK: - AnyInstructionVisitor

    mutating func visit(_ instruction: Instruction) throws(WasmParserError) {
        switch instruction {
        case .unreachable:
            emit("unreachable")
        case .nop:
            emit("nop")
        case .block(let blockType):
            let label = pushLabel()
            emit("block\(label)\(blockTypeSuffix(blockType))")
            indent += "  "
        case .loop(let blockType):
            let label = pushLabel()
            emit("loop\(label)\(blockTypeSuffix(blockType))")
            indent += "  "
        case .if(let blockType):
            let label = pushLabel(acceptsElse: true)
            emit("if\(label)\(blockTypeSuffix(blockType))")
            indent += "  "
        case .else:
            guard labelStack.last?.acceptsElse == true else {
                throw WasmParserError("else outside an if", offset: binaryOffset)
            }
            labelStack[labelStack.count - 1].acceptsElse = false
            indent.removeLast(2)
            emit("else")
            indent += "  "
        case .end:
            if labelStack.isEmpty {
                // The function's own `end` is the closing paren of `(func ...)`.
                return
            }
            labelStack.removeLast()
            indent.removeLast(2)
            emit("end")
        case .br(let d):
            emit("br \(labelReference(d))")
        case .brIf(let d):
            emit("br_if \(labelReference(d))")
        case .brTable(let tbl):
            var parts = tbl.labelIndices.map { labelReference($0) }
            parts.append(labelReference(tbl.defaultIndex))
            emit("br_table \(parts.joined(separator: " "))")
        case .return:
            emit("return")
        case .call(let fi):
            emit("call \(names.functions.reference(fi))")
        case .callIndirect(let ti, let tbl):
            emit("call_indirect\(tableSuffix(tbl)) (type \(names.types.reference(ti)))")
        case .returnCall(let fi):
            emit("return_call \(names.functions.reference(fi))")
        case .returnCallIndirect(let ti, let tbl):
            emit("return_call_indirect\(tableSuffix(tbl)) (type \(names.types.reference(ti)))")
        case .callRef(let ti):
            emit("call_ref \(names.types.reference(ti))")
        case .returnCallRef(let ti):
            emit("return_call_ref \(names.types.reference(ti))")
        case .drop:
            emit("drop")
        case .select:
            emit("select")
        case .typedSelect(let t):
            emit("select (result \(names.valueType(t)))")

        case .throw(let tagIndex):
            emit("throw \(names.tags.reference(tagIndex))")
        case .throwRef:
            emit("throw_ref")
        case .tryTable(let blockType, let tryCatch):
            // Catch labels resolve outside the try_table's own label, so format
            // them before pushing it.
            let clauses = tryCatch.catches.map { " " + catchClauseText($0) }.joined()
            let label = pushLabel()
            emit("try_table\(label)\(blockTypeSuffix(blockType))\(clauses)")
            indent += "  "

        case .localGet(let i):
            emit("local.get \(locals.reference(i))")
        case .localSet(let i):
            emit("local.set \(locals.reference(i))")
        case .localTee(let i):
            emit("local.tee \(locals.reference(i))")
        case .globalGet(let i):
            emit("global.get \(names.globals.reference(i))")
        case .globalSet(let i):
            emit("global.set \(names.globals.reference(i))")

        case .load(let kind, let m):
            let memarg = try memargText(m, defaultAlign: generatedDefaultAlign(for: kind))
            emit("\(generatedMnemonic(for: kind))\(memarg)")
        case .store(let kind, let m):
            let memarg = try memargText(m, defaultAlign: generatedDefaultAlign(for: kind))
            emit("\(generatedMnemonic(for: kind))\(memarg)")
        case .memorySize(let mem):
            emit("memory.size\(memorySuffix(mem))")
        case .memoryGrow(let mem):
            emit("memory.grow\(memorySuffix(mem))")

        case .i32Const(let v):
            emit("i32.const \(v)")
        case .i64Const(let v):
            emit("i64.const \(v)")
        case .f32Const(let v):
            emit("f32.const \(formatF32(v))")
        case .f64Const(let v):
            emit("f64.const \(formatF64(v))")

        case .refNull(let ht):
            emit("ref.null \(names.heapType(ht))")
        case .refIsNull:
            emit("ref.is_null")
        case .refFunc(let fi):
            emit("ref.func \(names.functions.reference(fi))")
        case .refAsNonNull:
            emit("ref.as_non_null")
        case .brOnNull(let d):
            emit("br_on_null \(labelReference(d))")
        case .brOnNonNull(let d):
            emit("br_on_non_null \(labelReference(d))")

        case .i32Eqz: emit("i32.eqz")
        case .i64Eqz: emit("i64.eqz")
        case .cmp(let op): emit(generatedMnemonic(for: op))

        case .unary(let op): emit(generatedMnemonic(for: op))
        case .binary(let op): emit(generatedMnemonic(for: op))
        case .conversion(let op): emit(generatedMnemonic(for: op))

        case .memoryInit(let di, let mem):
            emit("memory.init\(memorySuffix(mem)) \(names.data.reference(di))")
        case .dataDrop(let di):
            emit("data.drop \(names.data.reference(di))")
        case .memoryCopy(let dst, let src):
            if dst == 0 && src == 0 {
                emit("memory.copy")
            } else {
                emit("memory.copy \(names.memories.reference(dst)) \(names.memories.reference(src))")
            }
        case .memoryFill(let mem):
            emit("memory.fill\(memorySuffix(mem))")
        case .tableInit(let ei, let tbl):
            emit("table.init \(names.tables.reference(tbl)) \(names.elements.reference(ei))")
        case .elemDrop(let ei):
            emit("elem.drop \(names.elements.reference(ei))")
        case .tableCopy(let dst, let src):
            if dst == 0 && src == 0 {
                emit("table.copy")
            } else {
                emit("table.copy \(names.tables.reference(dst)) \(names.tables.reference(src))")
            }
        case .tableFill(let tbl):
            emit("table.fill\(tableSuffix(tbl))")
        case .tableGet(let tbl):
            emit("table.get\(tableSuffix(tbl))")
        case .tableSet(let tbl):
            emit("table.set\(tableSuffix(tbl))")
        case .tableGrow(let tbl):
            emit("table.grow\(tableSuffix(tbl))")
        case .tableSize(let tbl):
            emit("table.size\(tableSuffix(tbl))")

        case .atomicFence:
            emit("atomic.fence")

        case .v128Const(let v):
            let bytes = v.bytes.map { String($0) }.joined(separator: " ")
            emit("v128.const i8x16 \(bytes)")
        case .i8x16Shuffle(let mask):
            let lanes = mask.lanes.map { String($0) }.joined(separator: " ")
            emit("i8x16.shuffle \(lanes)")
        case .simd(let op): emit(generatedMnemonic(for: op))
        case .simdLane(let op, let lane): emit("\(generatedMnemonic(for: op)) \(lane)")
        case .simdMemLane(let op, let m, let lane):
            let memarg = try memargText(m, defaultAlign: generatedDefaultAlign(for: op))
            emit("\(generatedMnemonic(for: op))\(memarg) \(lane)")

        // Atomic memory instructions; GC instructions have no printer.
        default:
            guard let (mnemonic, m, align) = generatedMemargInstruction(instruction) else {
                throw WasmParserError("instruction not supported by wasm2wat", offset: binaryOffset)
            }
            let memarg = try memargText(m, defaultAlign: align)
            emit("\(mnemonic)\(memarg)")
        }
    }

    // MARK: - Emit helper

    private func emit(_ text: String) {
        append(indent)
        append(text)
        append("\n")
    }

    // MARK: - Label helpers

    private mutating func pushLabel(acceptsElse: Bool = false) -> String {
        let id = labelIds[nextLabelIndex]
        nextLabelIndex += 1
        labelStack.append(OpenLabel(id: id, acceptsElse: acceptsElse))
        return id.map { " " + $0 } ?? ""
    }

    /// Uses the depth when the target has no id or an inner label shadows it.
    private func labelReference(_ relativeDepth: UInt32) -> String {
        guard relativeDepth < labelStack.count else { return String(relativeDepth) }
        let position = labelStack.count - 1 - Int(relativeDepth)
        guard let id = labelStack[position].id, !labelStack[(position + 1)...].contains(where: { $0.id == id }) else {
            return String(relativeDepth)
        }
        return id
    }

    private func catchClauseText(_ clause: CatchClause) -> String {
        switch clause {
        case .catch(let tagIndex, let labelIndex):
            return "(catch \(names.tags.reference(tagIndex)) \(labelReference(labelIndex)))"
        case .catchRef(let tagIndex, let labelIndex):
            return "(catch_ref \(names.tags.reference(tagIndex)) \(labelReference(labelIndex)))"
        case .catchAll(let labelIndex):
            return "(catch_all \(labelReference(labelIndex)))"
        case .catchAllRef(let labelIndex):
            return "(catch_all_ref \(labelReference(labelIndex)))"
        }
    }

    // MARK: - Operand helpers

    private func memorySuffix(_ index: UInt32) -> String {
        index == 0 ? "" : " " + names.memories.reference(index)
    }

    private func tableSuffix(_ index: UInt32) -> String {
        index == 0 ? "" : " " + names.tables.reference(index)
    }

    private func blockTypeSuffix(_ bt: BlockType) -> String {
        switch bt {
        case .empty: return ""
        case .type(let vt): return " (result \(names.valueType(vt)))"
        case .funcType(let ti): return " (type \(names.types.reference(ti)))"
        }
    }

    private func memargText(_ m: MemArg, defaultAlign: UInt32) throws(WasmParserError) -> String {
        // `align=` takes a u32.
        guard m.align < 32 else {
            throw WasmParserError("alignment 2^\(m.align) has no text form", offset: binaryOffset)
        }
        var parts: [String] = []
        if m.memory != 0 { parts.append(names.memories.reference(m.memory)) }
        if m.offset != 0 { parts.append("offset=\(m.offset)") }
        if m.align != defaultAlign { parts.append("align=\(UInt32(1) << m.align)") }
        if parts.isEmpty { return "" }
        return " " + parts.joined(separator: " ")
    }
}
