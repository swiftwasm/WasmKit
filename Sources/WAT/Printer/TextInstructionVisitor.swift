import WasmParser
import WasmTypes

/// A visitor that emits WAT text for each WebAssembly instruction.
///
/// The generated ``TextInstructionPrinter`` prints most instructions from their mnemonic and
/// immediates. This type supplies the immediates' text, and implements the instructions that
/// open or close a block or have no text name of their own.
struct TextInstructionVisitor: TextInstructionPrinter {
    typealias VisitorError = WasmParserError

    var binaryOffset: Int = 0

    // MARK: - Context

    let info: ModuleInfo
    let locals: IndexToNameResolver
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
    private var reachedFinalEnd = false

    init(
        info: ModuleInfo,
        locals: IndexToNameResolver,
        labelIds: [UInt32: String],
        indentLevel: Int,
        append: @escaping (String) -> Void
    ) {
        self.info = info
        self.locals = locals
        self.labelIds = labelIds
        self.indent = String(repeating: "  ", count: indentLevel)
        self.append = append
    }

    /// Throws if the expression ended before its final `end`.
    func finishExpression() throws(WasmParserError) {
        guard reachedFinalEnd else {
            throw WasmParserError("expression ends inside a block", offset: binaryOffset)
        }
    }

    // MARK: - TextInstructionPrinter

    mutating func printInstruction(_ mnemonic: String, _ immediates: [String]) throws(WasmParserError) {
        try checkBeforeFinalEnd()
        append(indent)
        append(([mnemonic] + immediates).joined(separator: " "))
        append("\n")
    }

    // MARK: - Blocks

    mutating func visitBlock(blockType: BlockType) throws(WasmParserError) {
        try printBlockStart("block", immediates(blockType: blockType))
    }

    mutating func visitLoop(blockType: BlockType) throws(WasmParserError) {
        try printBlockStart("loop", immediates(blockType: blockType))
    }

    mutating func visitIf(blockType: BlockType) throws(WasmParserError) {
        try printBlockStart("if", immediates(blockType: blockType), acceptsElse: true)
    }

    mutating func visitTryTable(blockType: BlockType, tryCatch: TryCatch) throws(WasmParserError) {
        // Catch labels resolve outside the try_table's own label, so print them before pushing it.
        try printBlockStart("try_table", immediates(blockType: blockType, tryCatch: tryCatch))
    }

    mutating func visitElse() throws(WasmParserError) {
        try checkBeforeFinalEnd()
        guard labelStack.last?.acceptsElse == true else {
            throw WasmParserError("else outside an if", offset: binaryOffset)
        }
        labelStack[labelStack.count - 1].acceptsElse = false
        indent.removeLast(2)
        try printInstruction("else")
        indent += "  "
    }

    mutating func visitEnd() throws(WasmParserError) {
        try checkBeforeFinalEnd()
        guard !labelStack.isEmpty else {
            // The final `end` has no text: the closing paren of the enclosing form stands for it.
            reachedFinalEnd = true
            return
        }
        labelStack.removeLast()
        indent.removeLast(2)
        try printInstruction("end")
    }

    private mutating func printBlockStart(
        _ mnemonic: String, _ immediates: [String], acceptsElse: Bool = false
    ) throws(WasmParserError) {
        let id = labelIds[nextLabelIndex]
        nextLabelIndex += 1
        try printInstruction(mnemonic, (id.map { [$0] } ?? []) + immediates)
        labelStack.append(OpenLabel(id: id, acceptsElse: acceptsElse))
        indent += "  "
    }

    private func checkBeforeFinalEnd() throws(WasmParserError) {
        guard !reachedFinalEnd else {
            throw WasmParserError("instruction after the final end of the expression", offset: binaryOffset)
        }
    }

    // MARK: - Instructions without a text name

    mutating func visitTypedSelect(type: ValueType) throws(WasmParserError) {
        try printInstruction("select", ["(result \(info.text(of: type)))"])
    }

    mutating func visitRefTest(_ refTest: Instruction.RefTest, type: HeapType) throws(WasmParserError) {
        let referenceType = ReferenceType(isNullable: refTest == .refTestNull, heapType: type)
        try printInstruction("ref.test", [info.text(of: referenceType)])
    }

    mutating func visitRefCast(_ refCast: Instruction.RefCast, type: HeapType) throws(WasmParserError) {
        let referenceType = ReferenceType(isNullable: refCast == .refCastNull, heapType: type)
        try printInstruction("ref.cast", [info.text(of: referenceType)])
    }

    mutating func visitUnknown(_ opcode: [UInt8]) throws(WasmParserError) -> Bool {
        false
    }

    // MARK: - Immediates

    // Each returns the immediates' tokens, leaving out defaults such as memory 0 and table 0.

    func immediates(blockType: BlockType) -> [String] {
        switch blockType {
        case .empty: return []
        case .type(let type): return ["(result \(info.text(of: type)))"]
        case .funcType(let typeIndex): return ["(type \(info.typeNames.reference(typeIndex)))"]
        }
    }

    func immediates(blockType: BlockType, tryCatch: TryCatch) -> [String] {
        immediates(blockType: blockType)
            + tryCatch.catches.map { clause in
                switch clause {
                case .catch(let tagIndex, let labelIndex):
                    return "(catch \(info.tagNames.reference(tagIndex)) \(labelReference(labelIndex)))"
                case .catchRef(let tagIndex, let labelIndex):
                    return "(catch_ref \(info.tagNames.reference(tagIndex)) \(labelReference(labelIndex)))"
                case .catchAll(let labelIndex):
                    return "(catch_all \(labelReference(labelIndex)))"
                case .catchAllRef(let labelIndex):
                    return "(catch_all_ref \(labelReference(labelIndex)))"
                }
            }
    }

    func immediates(dataIndex: UInt32) -> [String] { [info.dataNames.reference(dataIndex)] }
    func immediates(elemIndex: UInt32) -> [String] { [info.elementNames.reference(elemIndex)] }
    func immediates(functionIndex: UInt32) -> [String] { [info.functionNames.reference(functionIndex)] }
    func immediates(globalIndex: UInt32) -> [String] { [info.globalNames.reference(globalIndex)] }
    func immediates(localIndex: UInt32) -> [String] { [locals.reference(localIndex)] }
    func immediates(tagIndex: UInt32) -> [String] { [info.tagNames.reference(tagIndex)] }
    func immediates(typeIndex: UInt32) -> [String] { [info.typeNames.reference(typeIndex)] }
    func immediates(type: HeapType) -> [String] { [info.text(of: type)] }
    func immediates(relativeDepth: UInt32) -> [String] { [labelReference(relativeDepth)] }
    func immediates(lane: UInt8) -> [String] { [String(lane)] }
    func immediates(lanes: V128ShuffleMask) -> [String] { lanes.lanes.map { String($0) } }
    func immediates(memory: UInt32) -> [String] { memory == 0 ? [] : [info.memoryNames.reference(memory)] }
    func immediates(table: UInt32) -> [String] { table == 0 ? [] : [info.tableNames.reference(table)] }
    func immediates(targets: BrTable) -> [String] { (targets.labelIndices + [targets.defaultIndex]).map(labelReference) }

    func immediates(value: Int32) -> [String] { [String(value)] }
    func immediates(value: Int64) -> [String] { [String(value)] }
    func immediates(value: IEEE754.Float32) -> [String] { [formatF32(value)] }
    func immediates(value: IEEE754.Float64) -> [String] { [formatF64(value)] }
    func immediates(value: V128) -> [String] { ["i8x16"] + value.bytes.map { String($0) } }

    func immediates(memarg: MemArg, naturalAlignment: Int) throws(WasmParserError) -> [String] {
        // `align=` takes a u32.
        guard memarg.align < 32 else {
            throw WasmParserError("alignment 2^\(memarg.align) has no text form", offset: binaryOffset)
        }
        var tokens = immediates(memory: memarg.memory)
        if memarg.offset != 0 { tokens.append("offset=\(memarg.offset)") }
        if memarg.align != naturalAlignment { tokens.append("align=\(UInt32(1) << memarg.align)") }
        return tokens
    }

    func immediates(memarg: MemArg, lane: UInt8, naturalAlignment: Int) throws(WasmParserError) -> [String] {
        try immediates(memarg: memarg, naturalAlignment: naturalAlignment) + immediates(lane: lane)
    }

    func immediates(dataIndex: UInt32, memory: UInt32) -> [String] {
        immediates(memory: memory) + immediates(dataIndex: dataIndex)
    }

    func immediates(elemIndex: UInt32, table: UInt32) -> [String] {
        [info.tableNames.reference(table)] + immediates(elemIndex: elemIndex)
    }

    func immediates(dstMem: UInt32, srcMem: UInt32) -> [String] {
        dstMem == 0 && srcMem == 0 ? [] : [info.memoryNames.reference(dstMem), info.memoryNames.reference(srcMem)]
    }

    func immediates(dstTable: UInt32, srcTable: UInt32) -> [String] {
        dstTable == 0 && srcTable == 0 ? [] : [info.tableNames.reference(dstTable), info.tableNames.reference(srcTable)]
    }

    func immediates(typeIndex: UInt32, tableIndex: UInt32) -> [String] {
        immediates(table: tableIndex) + ["(type \(info.typeNames.reference(typeIndex)))"]
    }

    func immediates(destType: UInt32, srcType: UInt32) -> [String] {
        immediates(typeIndex: destType) + immediates(typeIndex: srcType)
    }

    func immediates(typeIndex: UInt32, dataIndex: UInt32) -> [String] {
        immediates(typeIndex: typeIndex) + immediates(dataIndex: dataIndex)
    }

    func immediates(typeIndex: UInt32, elemIndex: UInt32) -> [String] {
        immediates(typeIndex: typeIndex) + immediates(elemIndex: elemIndex)
    }

    func immediates(typeIndex: UInt32, fieldIndex: UInt32) -> [String] {
        immediates(typeIndex: typeIndex) + [String(fieldIndex)]
    }

    func immediates(typeIndex: UInt32, size: UInt32) -> [String] {
        immediates(typeIndex: typeIndex) + [String(size)]
    }

    func immediates(relativeDepth: UInt32, castFrom: ReferenceType, castTo: ReferenceType) -> [String] {
        immediates(relativeDepth: relativeDepth) + [info.text(of: castFrom), info.text(of: castTo)]
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
}
