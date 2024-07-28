import WasmParser

class ISeqAllocator {

    private var buffers: [UnsafeMutableRawBufferPointer] = []

    func allocateBrTable(capacity: Int) -> UnsafeMutableBufferPointer<Instruction.BrTable.Entry> {
        assert(_isPOD(Instruction.BrTable.Entry.self), "Instruction.BrTable.Entry must be POD")
        let buffer = UnsafeMutableBufferPointer<Instruction.BrTable.Entry>.allocate(capacity: capacity)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return buffer
    }

    func allocateDefaultLocals(_ locals: [ValueType]) -> UnsafeBufferPointer<Value> {
        let buffer = UnsafeMutableBufferPointer<Value>.allocate(capacity: locals.count)
        for (index, localType) in locals.enumerated() {
            buffer[index] = localType.defaultValue
        }
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return UnsafeBufferPointer(buffer)
    }

    func allocateInstructions(capacity: Int) -> UnsafeMutableBufferPointer<Instruction> {
        assert(_isPOD(Instruction.self), "Instruction must be POD")
        let buffer = UnsafeMutableBufferPointer<Instruction>.allocate(capacity: capacity)
        self.buffers.append(UnsafeMutableRawBufferPointer(buffer))
        return buffer
    }

    deinit {
        for buffer in buffers {
            buffer.deallocate()
        }
    }
}

struct InstructionTranslator: InstructionVisitor {
    typealias Output = Void

    struct Module {
        private let typeSection: [FunctionType]
        private let functionTypeIndices: [TypeIndex]
        private let globalTypes: [GlobalType]
        private let memoryTypes: [MemoryType]
        private let tableTypes: [TableType]

        init(
            typeSection: [FunctionType],
            importSection: [Import],
            functionSection: [TypeIndex],
            globalTypes: [GlobalType],
            memoryTypes: [MemoryType],
            tables: [Table]
        ) {
            self.typeSection = typeSection
            self.functionTypeIndices =
                importSection.compactMap { (entry) -> TypeIndex? in
                    guard case let .function(typeIndex) = entry.descriptor else { return nil }
                    return typeIndex
                } + functionSection
            self.globalTypes =
                importSection.compactMap { (entry) -> GlobalType? in
                    guard case let .global(type) = entry.descriptor else { return nil }
                    return type
                } + globalTypes
            self.memoryTypes =
                importSection.compactMap { (entry) -> MemoryType? in
                    guard case let .memory(type) = entry.descriptor else { return nil }
                    return type
                } + memoryTypes
            self.tableTypes =
                importSection.compactMap { (entry) -> TableType? in
                    guard case let .table(type) = entry.descriptor else { return nil }
                    return type
                } + tables.map(\.type)
        }

        func resolveType(_ index: TypeIndex) throws -> FunctionType {
            guard Int(index) < typeSection.count else {
                throw TranslationError("Type index \(index) is out of range")
            }
            return typeSection[Int(index)]
        }
        func resolveBlockType(_ blockType: BlockType) throws -> FunctionType {
            try FunctionType(blockType: blockType, typeSection: typeSection)
        }
        func functionType(_ index: FunctionIndex) throws -> FunctionType {
            guard Int(index) < functionTypeIndices.count else {
                throw TranslationError("Function index \(index) is out of range")
            }
            let typeIndex = functionTypeIndices[Int(index)]
            return try resolveType(typeIndex)
        }
        func globalType(_ index: GlobalIndex) throws -> ValueType {
            guard Int(index) < globalTypes.count else {
                throw TranslationError("Global index \(index) is out of range")
            }
            return self.globalTypes[Int(index)].valueType
        }
        func isMemory64(memoryIndex index: MemoryIndex) throws -> Bool {
            guard Int(index) < memoryTypes.count else {
                throw TranslationError("Memory index \(index) is out of range")
            }
            return self.memoryTypes[Int(index)].isMemory64
        }
        func addressType(memoryIndex: MemoryIndex) throws -> ValueType {
            try isMemory64(memoryIndex: memoryIndex) ? .i64 : .i32
        }
        func isMemory64(tableIndex index: TableIndex) throws -> Bool {
            guard Int(index) < tableTypes.count else {
                throw TranslationError("Table index \(index) is out of range")
            }
            return self.tableTypes[Int(index)].limits.isMemory64
        }
        func addressType(tableIndex: TableIndex) throws -> ValueType {
            try isMemory64(tableIndex: tableIndex) ? .i64 : .i32
        }
        func elementType(_ index: TableIndex) throws -> ReferenceType {
            guard Int(index) < tableTypes.count else {
                throw TranslationError("Table index \(index) is out of range")
            }
            return self.tableTypes[Int(index)].elementType
        }
    }

    struct MetaProgramCounter {
        let offsetFromHead: Int
    }
    typealias LabelRef = Int
    typealias ValueType = WasmParser.ValueType

    struct ControlStack {
        typealias BlockType = FunctionType

        struct ControlFrame {
            enum Kind {
                case block(root: Bool)
                case loop
                case `if`(elseLabel: LabelRef, endLabel: LabelRef)

                static var block: Kind { .block(root: false) }
            }

            let blockType: BlockType
            /// The height of `ValueStack` without including the frame parameters
            let stackHeight: Int
            let continuation: LabelRef
            var kind: Kind
            var reachable: Bool = true

            var copyCount: UInt16 {
                switch self.kind {
                case .block, .if:
                    return UInt16(blockType.results.count)
                case .loop:
                    return UInt16(blockType.parameters.count)
                }
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

        mutating func markUnreachable() throws {
            guard !self.frames.isEmpty else {
                throw TranslationError("Control stack is empty. Instruction cannot be appeared after \"end\" of function")
            }
            self.frames[self.frames.count - 1].reachable = false
        }

        func currentFrame() throws -> ControlFrame {
            guard let frame = self.frames.last else {
                throw TranslationError("Control stack is empty. Instruction cannot be appeared after \"end\" of function")
            }
            return frame
        }

        enum BranchTarget {
            case returnFunction
            case localJump(ControlFrame)
        }
        func branchTarget(relativeDepth: UInt32) throws -> BranchTarget {
            if frames.count == relativeDepth { return .returnFunction }
            if frames.count < relativeDepth {
                throw TranslationError("Relative depth \(relativeDepth) is out of range")
            }
            return .localJump(frames[frames.count - 1 - Int(relativeDepth)])
        }
    }

    enum MetaValue: Equatable {
        case some(ValueType)
        case unknown
    }
    struct ValueStack {
        private var values: [MetaValue] = []
        /// The maximum height of the stack within the function
        private(set) var maxHeight: Int = 0
        var height: Int { values.count }

        mutating func push(_ value: ValueType) {
            push(.some(value))
        }
        mutating func push(_ value: MetaValue) {
            // Record the maximum height of the stack we have seen
            maxHeight = max(maxHeight, height)
            self.values.append(value)
        }

        mutating func pop() throws -> MetaValue {
            guard let value = self.values.popLast() else {
                throw TranslationError("Expected a value on stack but it's empty")
            }
            return value
        }
        mutating func pop(_ expected: ValueType) throws {
            switch try pop() {
            case .some(let actual):
                guard actual == expected else {
                    throw TranslationError("Expected \(expected) on the stack top but got \(actual)")
                }
            case .unknown: break  // OK
            }
        }
        mutating func popRef() throws {
            switch try pop() {
            case .some(let actual):
                guard case .ref = actual else {
                    throw TranslationError("Expected reference value on the stack top but got \(actual)")
                }
            case .unknown: break  // OK
            }
        }
        mutating func truncate(height: Int) throws {
            guard height <= self.height else {
                throw TranslationError("Truncating to \(height) but the stack height is \(self.height)")
            }
            while height != self.height {
                guard self.values.popLast() != nil else {
                    throw TranslationError("Internal consistency error: Stack height is \(self.height) but failed to pop")
                }
            }
        }
    }

    struct ISeqBuilder {
        typealias InstructionFactoryWithLabel = (ISeqBuilder, MetaProgramCounter) -> (WasmKit.Instruction)
        typealias BrTableEntryFactory = (ISeqBuilder, MetaProgramCounter) -> Instruction.BrTable.Entry
        typealias BuildingBrTable = UnsafeMutableBufferPointer<Instruction.BrTable.Entry>

        enum OnPinAction {
            case emitInstruction(insertAt: MetaProgramCounter, InstructionFactoryWithLabel)
            case fillBrTableEntry(
                buildingTable: BuildingBrTable,
                index: Int, make: BrTableEntryFactory
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

        private var labels: [LabelEntry] = []
        private var instructions: [WasmKit.Instruction] = []
        var insertingPC: MetaProgramCounter {
            MetaProgramCounter(offsetFromHead: instructions.count)
        }

        func assertDanglingLabels() {
            for (ref, label) in labels.enumerated() {
                switch label {
                case .unpinned(let users):
                    assert(users.isEmpty, "Label (#\(ref)) is used but not pinned at finalization-time: \(users)")
                case .pinned: break
                }
            }
        }

        func dump() {
            for instruction in instructions {
                print(instruction)
            }
        }

        func finalize() -> [Instruction] {
            return instructions
        }

        mutating func emit(_ instruction: Instruction) {
            self.instructions.append(instruction)
        }

        mutating func putLabel() -> LabelRef {
            let ref = labels.count
            self.labels.append(.pinned(insertingPC))
            return ref
        }

        mutating func allocLabel() -> LabelRef {
            let ref = labels.count
            self.labels.append(.unpinned(users: []))
            return ref
        }

        func resolveLabel(_ ref: LabelRef) -> MetaProgramCounter? {
            let entry = self.labels[ref]
            switch entry {
            case .pinned(let pc): return pc
            case .unpinned: return nil
            }
        }

        mutating func pinLabel(_ ref: LabelRef, pc: MetaProgramCounter) {
            switch self.labels[ref] {
            case .pinned(let oldPC):
                fatalError("Internal consistency error: Label \(ref) is already pinned at \(oldPC), but tried to pin at \(pc) again")
            case .unpinned(let users):
                self.labels[ref] = .pinned(pc)
                for user in users {
                    switch user.action {
                    case let .emitInstruction(insertAt, make):
                        instructions[insertAt.offsetFromHead] = make(self, pc)
                    case let .fillBrTableEntry(brTable, index, make):
                        brTable[index] = make(self, pc)
                    }
                }
            }
        }

        mutating func pinLabelHere(_ ref: LabelRef) {
            pinLabel(ref, pc: insertingPC)
        }

        /// Emit an instruction at the current insertion point with resolved label position
        /// - Parameters:
        ///   - ref: Label reference to be resolved
        ///   - make: Factory closure to make an inserting instruction
        mutating func emitWithLabel(_ ref: LabelRef, line: UInt = #line, make: @escaping InstructionFactoryWithLabel) {
            let insertAt = insertingPC
            emit(.nop)  // Emit dummy instruction to be replaced later
            emitWithLabel(ref, insertAt: insertAt, line: line, make: make)
        }

        /// Emit an instruction at the specified position with resolved label position
        /// - Parameters:
        ///   - ref: Label reference to be resolved
        ///   - insertAt: Instruction sequence offset to insert at
        ///   - make: Factory closure to make an inserting instruction
        mutating func emitWithLabel(
            _ ref: LabelRef, insertAt: MetaProgramCounter,
            line: UInt = #line, make: @escaping InstructionFactoryWithLabel
        ) {
            switch self.labels[ref] {
            case .pinned(let pc):
                self.instructions[insertAt.offsetFromHead] = make(self, pc)
            case .unpinned(var users):
                users.append(LabelUser(action: .emitInstruction(insertAt: insertAt, make), sourceLine: line))
                self.labels[ref] = .unpinned(users: users)
            }
        }
    }

    struct Locals {
        let types: [ValueType]

        func type(of localIndex: UInt32) throws -> ValueType {
            guard Int(localIndex) < types.count else {
                throw TranslationError("Local index \(localIndex) is out of range")
            }
            return self.types[Int(localIndex)]
        }
    }

    let allocator: ISeqAllocator
    let module: Module
    var iseqBuilder: ISeqBuilder
    var controlStack: ControlStack
    var valueStack: ValueStack
    let locals: Locals
    let endOfFunctionLabel: LabelRef

    init(allocator: ISeqAllocator, module: Module, type: FunctionType, locals: [WasmParser.ValueType]) {
        self.allocator = allocator
        self.module = module
        self.iseqBuilder = ISeqBuilder()
        self.controlStack = ControlStack()
        self.valueStack = ValueStack()
        self.locals = Locals(types: type.parameters + locals)

        do {
            let endLabel = self.iseqBuilder.allocLabel()
            let rootFrame = ControlStack.ControlFrame(
                blockType: type,
                stackHeight: 0,
                continuation: endLabel,
                kind: .block(root: true)
            )
            self.endOfFunctionLabel = endLabel
            self.controlStack.pushFrame(rootFrame)
        }
    }

    private mutating func emit(_ instruction: Instruction) {
        iseqBuilder.emit(instruction)
    }

    /// Perform a precondition check for pop operation on value stack.
    ///
    /// - Parameter typeHint: A type expected to be popped. Only used for diagnostic purpose.
    /// - Returns: `true` if check succeed. `false` if the pop operation is going to be performed in unreachable code path.
    private func checkBeforePop(typeHint: ValueType?) throws -> Bool {
        let controlFrame = try controlStack.currentFrame()
        if _slowPath(valueStack.height <= controlFrame.stackHeight) {
            if controlFrame.reachable {
                let message: String
                if let typeHint {
                    message = "Expected a \(typeHint) value on stack but it's empty"
                } else {
                    message = "Expected a value on stack but it's empty"
                }
                throw TranslationError(message)
            }
            // Too many pop on unreachable path is ignored
            return false
        }
        return true
    }
    private mutating func popOperand(_ type: ValueType) throws {
        guard try checkBeforePop(typeHint: type) else {
            return
        }
        try valueStack.pop(type)
    }

    private mutating func popAnyOperand() throws -> MetaValue {
        guard try checkBeforePop(typeHint: nil) else {
            return .unknown
        }
        return try valueStack.pop()
    }

    private mutating func translateReturn() {
        iseqBuilder.emit(.return)
    }
    private mutating func markUnreachable() throws {
        try controlStack.markUnreachable()
        let currentFrame = try controlStack.currentFrame()
        try valueStack.truncate(height: currentFrame.stackHeight)
    }

    mutating func finalize() throws -> InstructionSequence {
        if controlStack.numberOfFrames > 1 {
            throw TranslationError("Expect \(controlStack.numberOfFrames - 1) more `end` instructions")
        }
        iseqBuilder.pinLabelHere(self.endOfFunctionLabel)
        #if DEBUG
            // Check dangling labels
            iseqBuilder.assertDanglingLabels()
        #endif
        let instructions = iseqBuilder.finalize()
        // TODO: Figure out a way to avoid the copy here while keeping the execution performance.
        let buffer = allocator.allocateInstructions(capacity: instructions.count + 1)
        for (idx, instruction) in instructions.enumerated() {
            buffer[idx] = instruction
        }
        buffer[instructions.count] = .endOfFunction
        return InstructionSequence(instructions: UnsafeBufferPointer(buffer), maxStackHeight: valueStack.maxHeight)
    }

    // MARK: - Visitor

    mutating func visitUnreachable() throws -> Output {
        emit(.unreachable)
        try markUnreachable()
    }
    mutating func visitNop() -> Output { emit(.nop) }

    mutating func visitBlock(blockType: WasmParser.BlockType) throws -> Output {
        let blockType = try module.resolveBlockType(blockType)
        let endLabel = iseqBuilder.allocLabel()
        let stackHeight = self.valueStack.height - Int(blockType.parameters.count)
        controlStack.pushFrame(ControlStack.ControlFrame(blockType: blockType, stackHeight: stackHeight, continuation: endLabel, kind: .block))
    }

    mutating func visitLoop(blockType: WasmParser.BlockType) throws -> Output {
        let blockType = try module.resolveBlockType(blockType)
        let headLabel = iseqBuilder.putLabel()
        let stackHeight = self.valueStack.height - Int(blockType.parameters.count)
        controlStack.pushFrame(ControlStack.ControlFrame(blockType: blockType, stackHeight: stackHeight, continuation: headLabel, kind: .loop))
    }

    mutating func visitIf(blockType: WasmParser.BlockType) throws -> Output {
        // Pop condition value
        try popOperand(.i32)
        let blockType = try module.resolveBlockType(blockType)
        let endLabel = iseqBuilder.allocLabel()
        let elseLabel = iseqBuilder.allocLabel()
        let stackHeight = self.valueStack.height - Int(blockType.parameters.count)
        controlStack.pushFrame(
            ControlStack.ControlFrame(
                blockType: blockType, stackHeight: stackHeight, continuation: endLabel,
                kind: .if(elseLabel: elseLabel, endLabel: endLabel)
            )
        )
        let selfPC = iseqBuilder.insertingPC
        iseqBuilder.emitWithLabel(endLabel) { iseqBuilder, endPC in
            let elseOrEndRef: ExpressionRef
            if let elsePC = iseqBuilder.resolveLabel(elseLabel) {
                elseOrEndRef = ExpressionRef(from: selfPC, to: elsePC)
            } else {
                elseOrEndRef = ExpressionRef(from: selfPC, to: endPC)
            }
            return .ifThen(elseOrEndRef: elseOrEndRef)
        }
    }

    mutating func visitElse() throws -> Output {
        let frame = try controlStack.currentFrame()
        guard case let .if(elseLabel, endLabel) = frame.kind else {
            throw TranslationError("Expected `if` control frame on top of the stack for `else` but got \(frame)")
        }
        let selfPC = iseqBuilder.insertingPC
        iseqBuilder.emitWithLabel(endLabel) { _, endPC in
            let endRef = ExpressionRef(from: selfPC, to: endPC)
            return .else(endRef: endRef)
        }
        try valueStack.truncate(height: frame.stackHeight)
        // Re-push parameters
        for parameter in frame.blockType.parameters {
            valueStack.push(parameter)
        }
        iseqBuilder.pinLabelHere(elseLabel)
    }

    mutating func visitEnd() throws -> Output {
        guard let poppedFrame = controlStack.popFrame() else {
            throw TranslationError("Unexpected `end` instruction")
        }

        if case .block(root: true) = poppedFrame.kind {
            // TODO: Move endOfFunction emission from ISeq type
            // iseqBuilder.emit(.endOfFunction)
            return
        }

        switch poppedFrame.kind {
        case .block:
            iseqBuilder.pinLabelHere(poppedFrame.continuation)
        case .loop: break
        case .if:
            iseqBuilder.pinLabelHere(poppedFrame.continuation)
        }
        try valueStack.truncate(height: poppedFrame.stackHeight)
        for result in poppedFrame.blockType.results {
            valueStack.push(result)
        }
    }

    private static func computePopCount(
        destination: ControlStack.ControlFrame,
        currentFrame: ControlStack.ControlFrame,
        currentHeight: Int
    ) throws -> UInt32 {
        let popCount: UInt32
        if _fastPath(currentFrame.reachable) {
            let count = currentHeight - Int(destination.copyCount) - destination.stackHeight
            guard count >= 0 else {
                throw TranslationError("Stack height underflow: available \(currentHeight), required \(destination.stackHeight + Int(destination.copyCount))")
            }
            popCount = UInt32(count)
        } else {
            // Slow path: This path is taken when "br" is placed after "unreachable"
            // It's ok to put the fake popCount because it will not be executed at runtime.
            popCount = 0
        }
        return popCount
    }

    private mutating func emitBranch(
        relativeDepth: UInt32,
        make: @escaping (_ offset: Int32, _ copyCount: UInt32, _ popCount: UInt32) -> Instruction
    ) throws {
        let frame: ControlStack.ControlFrame
        switch try controlStack.branchTarget(relativeDepth: relativeDepth) {
        case .returnFunction:
            // XX: unreachable?
            self.translateReturn()
            return
        case .localJump(let found):
            frame = found
        }
        let selfPC = iseqBuilder.insertingPC
        let copyCount = frame.copyCount

        let popCount = try Self.computePopCount(
            destination: frame,
            currentFrame: try controlStack.currentFrame(),
            currentHeight: valueStack.height
        )
        iseqBuilder.emitWithLabel(frame.continuation) { _, continuation in
            let relativeOffset = continuation.offsetFromHead - selfPC.offsetFromHead
            return make(Int32(relativeOffset), UInt32(copyCount), popCount)
        }
    }
    mutating func visitBr(relativeDepth: UInt32) throws -> Output {
        try emitBranch(relativeDepth: relativeDepth) { offset, copyCount, popCount in
            return .br(
                offset: offset,
                copyCount: copyCount, popCount: popCount
            )
        }
        try markUnreachable()
    }

    mutating func visitBrIf(relativeDepth: UInt32) throws -> Output {
        try popOperand(.i32)
        try emitBranch(relativeDepth: relativeDepth) { offset, copyCount, popCount in
            return .brIf(
                offset: offset,
                copyCount: copyCount, popCount: popCount
            )
        }
    }

    mutating func visitBrTable(targets: WasmParser.BrTable) throws -> Output {
        try popOperand(.i32)  // Table index

        let allLabelIndices = targets.labelIndices + [targets.defaultIndex]
        let tableBuffer = allocator.allocateBrTable(capacity: allLabelIndices.count)
        let brTable = Instruction.BrTable(buffer: UnsafeBufferPointer(tableBuffer))
        let insertAt = iseqBuilder.insertingPC
        iseqBuilder.emit(.brTable(brTable))

        let currentFrame = try controlStack.currentFrame()
        let currentHeight = valueStack.height

        for (entryIndex, labelIndex) in allLabelIndices.enumerated() {
            let frame: ControlStack.ControlFrame
            switch try controlStack.branchTarget(relativeDepth: labelIndex) {
            case .returnFunction:
                // XX: unreachable?
                self.translateReturn()
                return
            case .localJump(let found):
                frame = found
            }
            let popCount = try Self.computePopCount(
                destination: frame, currentFrame: currentFrame, currentHeight: currentHeight
            )

            iseqBuilder.emitWithLabel(frame.continuation, insertAt: insertAt) { iseqBuilder, continuation in
                let relativeOffset = continuation.offsetFromHead - insertAt.offsetFromHead
                tableBuffer[entryIndex] = Instruction.BrTable.Entry(
                    labelIndex: labelIndex, offset: Int32(relativeOffset),
                    copyCount: frame.copyCount, popCount: UInt16(popCount)
                )
                assert(tableBuffer[entryIndex].labelIndex == labelIndex)
                return .brTable(brTable)
            }
        }
        try markUnreachable()
    }

    mutating func visitReturn() throws -> Output {
        translateReturn()
        try markUnreachable()
    }

    private mutating func visitCallLike(calleeType: FunctionType) throws {
        for parameter in calleeType.parameters.reversed() {
            try popOperand(parameter)
        }
        for result in calleeType.results {
            valueStack.push(result)
        }
    }
    mutating func visitCall(functionIndex: UInt32) throws -> Output {
        let calleeType = try self.module.functionType(functionIndex)
        try visitCallLike(calleeType: calleeType)
        emit(.call(functionIndex: functionIndex))
    }

    mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws -> Output {
        let addressType = try module.addressType(tableIndex: tableIndex)
        try popOperand(addressType)  // function address
        let calleeType = try self.module.resolveType(typeIndex)
        try visitCallLike(calleeType: calleeType)
        emit(.callIndirect(tableIndex: tableIndex, typeIndex: typeIndex))
    }

    mutating func visitDrop() throws -> Output {
        _ = try popAnyOperand()
        emit(.drop)
    }
    mutating func visitSelect() throws -> Output {
        try popOperand(.i32)
        let value1 = try popAnyOperand()
        let value2 = try popAnyOperand()
        switch (value1, value2) {
        case let (.some(type1), .some(type2)):
            guard type1 == type2 else {
                throw TranslationError("Type mismatch on `select`. Expected \(value1) and \(value2) to be same")
            }
        case (.unknown, _), (_, .unknown):
            break
        }
        valueStack.push(value1)
        emit(.select)
    }
    mutating func visitTypedSelect(type: WasmParser.ValueType) throws -> Output {
        try popOperand(.i32)
        let value1 = try popAnyOperand()
        _ = try popAnyOperand()
        // TODO: Perform actual validation
        // guard value1 == ValueType(type) else {
        //     throw TranslationError("Type mismatch on `select`. Expected \(value1) and \(type) to be same")
        // }
        // guard value2 == ValueType(type) else {
        //     throw TranslationError("Type mismatch on `select`. Expected \(value2) and \(type) to be same")
        // }
        valueStack.push(value1)
        emit(.select)
    }
    mutating func visitLocalGet(localIndex: UInt32) throws -> Output {
        let type = try locals.type(of: localIndex)
        valueStack.push(type)
        emit(.localGet(index: localIndex))
    }
    mutating func visitLocalSet(localIndex: UInt32) throws -> Output {
        let type = try locals.type(of: localIndex)
        try popOperand(type)
        emit(.localSet(index: localIndex))
    }
    mutating func visitLocalTee(localIndex: UInt32) -> Output {
        // No value stack traffic here
        emit(.localTee(index: localIndex))
    }
    mutating func visitGlobalGet(globalIndex: UInt32) throws -> Output {
        let type = try module.globalType(globalIndex)
        valueStack.push(type)
        emit(.globalGet(index: globalIndex))
    }
    mutating func visitGlobalSet(globalIndex: UInt32) throws -> Output {
        let type = try module.globalType(globalIndex)
        try popOperand(type)
        emit(.globalSet(index: globalIndex))
    }

    private mutating func pushEmit(_ type: ValueType, _ instruction: Instruction) {
        valueStack.push(type)
        emit(instruction)
    }
    private mutating func popEmit(_ type: ValueType, _ instruction: Instruction) throws {
        try popOperand(type)
        emit(instruction)
    }
    private mutating func popPushEmit(_ pop: ValueType, _ push: ValueType, _ instruction: Instruction) throws {
        try popOperand(pop)
        valueStack.push(push)
        emit(instruction)
    }
    private mutating func popPushEmit(_ pops: [ValueType], _ pushs: [ValueType], _ instruction: Instruction) throws {
        for pop in pops {
            try popOperand(pop)
        }
        for push in pushs {
            valueStack.push(push)
        }
        emit(instruction)
    }
    private mutating func visitLoad(_ memarg: MemArg, _ type: ValueType, _ instruction: Instruction) throws {
        let isMemory64 = try module.isMemory64(memoryIndex: 0)
        let alignLog2Limit = isMemory64 ? 64 : 32
        if memarg.align >= alignLog2Limit {
            throw TranslationError("Alignment 2**\(memarg.align) is out of limit \(alignLog2Limit)")
        }
        try popPushEmit(.address(isMemory64: isMemory64), type, instruction)
    }
    private mutating func visitStore(_ memarg: MemArg, _ type: ValueType, _ instruction: Instruction) throws {
        try popOperand(type)
        try popOperand(module.addressType(memoryIndex: 0))
        emit(instruction)
    }
    mutating func visitI32Load(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i32, .i32Load(memarg: memarg)) }
    mutating func visitI64Load(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load(memarg: memarg)) }
    mutating func visitF32Load(memarg: MemArg) throws -> Output { try visitLoad(memarg, .f32, .f32Load(memarg: memarg)) }
    mutating func visitF64Load(memarg: MemArg) throws -> Output { try visitLoad(memarg, .f64, .f64Load(memarg: memarg)) }
    mutating func visitI32Load8S(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i32, .i32Load8S(memarg: memarg)) }
    mutating func visitI32Load8U(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i32, .i32Load8U(memarg: memarg)) }
    mutating func visitI32Load16S(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i32, .i32Load16S(memarg: memarg)) }
    mutating func visitI32Load16U(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i32, .i32Load16U(memarg: memarg)) }
    mutating func visitI64Load8S(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load8S(memarg: memarg)) }
    mutating func visitI64Load8U(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load8U(memarg: memarg)) }
    mutating func visitI64Load16S(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load16S(memarg: memarg)) }
    mutating func visitI64Load16U(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load16U(memarg: memarg)) }
    mutating func visitI64Load32S(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load32S(memarg: memarg)) }
    mutating func visitI64Load32U(memarg: MemArg) throws -> Output { try visitLoad(memarg, .i64, .i64Load32U(memarg: memarg)) }
    mutating func visitI32Store(memarg: MemArg) throws -> Output { try visitStore(memarg, .i32, .i32Store(memarg: memarg)) }
    mutating func visitI64Store(memarg: MemArg) throws -> Output { try visitStore(memarg, .i64, .i64Store(memarg: memarg)) }
    mutating func visitF32Store(memarg: MemArg) throws -> Output { try visitStore(memarg, .f32, .f32Store(memarg: memarg)) }
    mutating func visitF64Store(memarg: MemArg) throws -> Output { try visitStore(memarg, .f64, .f64Store(memarg: memarg)) }
    mutating func visitI32Store8(memarg: MemArg) throws -> Output { try visitStore(memarg, .i32, .i32Store8(memarg: memarg)) }
    mutating func visitI32Store16(memarg: MemArg) throws -> Output { try visitStore(memarg, .i32, .i32Store16(memarg: memarg)) }
    mutating func visitI64Store8(memarg: MemArg) throws -> Output { try visitStore(memarg, .i64, .i64Store8(memarg: memarg)) }
    mutating func visitI64Store16(memarg: MemArg) throws -> Output { try visitStore(memarg, .i64, .i64Store16(memarg: memarg)) }
    mutating func visitI64Store32(memarg: MemArg) throws -> Output { try visitStore(memarg, .i64, .i64Store32(memarg: memarg)) }
    mutating func visitMemorySize(memory: UInt32) throws -> Output {
        let sizeType: ValueType = try module.isMemory64(memoryIndex: memory) ? .i64 : .i32
        pushEmit(sizeType, .memorySize)
    }
    mutating func visitMemoryGrow(memory: UInt32) throws -> Output {
        // Just pop/push the same type (i64 or i32) value
        emit(.memoryGrow)
    }
    mutating func visitI32Const(value: Int32) -> Output { pushEmit(.i32, .numericConst(.i32(UInt32(bitPattern: value)))) }
    mutating func visitI64Const(value: Int64) -> Output { pushEmit(.i64, .numericConst(.i64(UInt64(bitPattern: value)))) }
    mutating func visitF32Const(value: IEEE754.Float32) -> Output { pushEmit(.f32, .numericConst(.f32(value.bitPattern))) }
    mutating func visitF64Const(value: IEEE754.Float64) -> Output { pushEmit(.f64, .numericConst(.f64(value.bitPattern))) }
    mutating func visitRefNull(type: WasmParser.ReferenceType) -> Output { pushEmit(.ref(type), .refNull(type)) }
    mutating func visitRefIsNull() throws -> Output {
        try valueStack.popRef()
        valueStack.push(.i32)
        emit(.refIsNull)
    }
    mutating func visitRefFunc(functionIndex: UInt32) -> Output { pushEmit(.ref(.funcRef), .refFunc(functionIndex)) }

    private mutating func visitUnary(_ operand: ValueType, _ instruction: Instruction) throws {
        try popPushEmit(operand, operand, instruction)
    }
    private mutating func visitBinary(_ operand: ValueType, _ result: ValueType, _ instruction: Instruction) throws {
        try popOperand(operand)
        try popOperand(operand)
        valueStack.push(result)
        emit(instruction)
    }
    private mutating func visitCmp(_ operand: ValueType, _ instruction: Instruction) throws {
        try popPushEmit([operand, operand], [.i32], instruction)
    }
    private mutating func visitConversion(_ from: ValueType, _ to: ValueType, _ instruction: Instruction) throws {
        try popPushEmit(from, to, instruction)
    }
    mutating func visitI32Eqz() throws -> Output {
        try popPushEmit(.i32, .i32, .i32Eqz)
    }
    mutating func visitI32Eq() throws -> Output { try visitCmp(.i32, .i32Eq) }
    mutating func visitI32Ne() throws -> Output { try visitCmp(.i32, .i32Ne) }
    mutating func visitI32LtS() throws -> Output { try visitCmp(.i32, .i32LtS) }
    mutating func visitI32LtU() throws -> Output { try visitCmp(.i32, .i32LtU) }
    mutating func visitI32GtS() throws -> Output { try visitCmp(.i32, .i32GtS) }
    mutating func visitI32GtU() throws -> Output { try visitCmp(.i32, .i32GtU) }
    mutating func visitI32LeS() throws -> Output { try visitCmp(.i32, .i32LeS) }
    mutating func visitI32LeU() throws -> Output { try visitCmp(.i32, .i32LeU) }
    mutating func visitI32GeS() throws -> Output { try visitCmp(.i32, .i32GeS) }
    mutating func visitI32GeU() throws -> Output { try visitCmp(.i32, .i32GeU) }
    mutating func visitI64Eqz() throws -> Output {
        try popPushEmit(.i64, .i32, .i64Eqz)
    }
    mutating func visitI64Eq() throws -> Output { try visitCmp(.i64, .i64Eq) }
    mutating func visitI64Ne() throws -> Output { try visitCmp(.i64, .i64Ne) }
    mutating func visitI64LtS() throws -> Output { try visitCmp(.i64, .i64LtS) }
    mutating func visitI64LtU() throws -> Output { try visitCmp(.i64, .i64LtU) }
    mutating func visitI64GtS() throws -> Output { try visitCmp(.i64, .i64GtS) }
    mutating func visitI64GtU() throws -> Output { try visitCmp(.i64, .i64GtU) }
    mutating func visitI64LeS() throws -> Output { try visitCmp(.i64, .i64LeS) }
    mutating func visitI64LeU() throws -> Output { try visitCmp(.i64, .i64LeU) }
    mutating func visitI64GeS() throws -> Output { try visitCmp(.i64, .i64GeS) }
    mutating func visitI64GeU() throws -> Output { try visitCmp(.i64, .i64GeU) }
    mutating func visitF32Eq() throws -> Output { try visitCmp(.f32, .f32Eq) }
    mutating func visitF32Ne() throws -> Output { try visitCmp(.f32, .f32Ne) }
    mutating func visitF32Lt() throws -> Output { try visitCmp(.f32, .f32Lt) }
    mutating func visitF32Gt() throws -> Output { try visitCmp(.f32, .f32Gt) }
    mutating func visitF32Le() throws -> Output { try visitCmp(.f32, .f32Le) }
    mutating func visitF32Ge() throws -> Output { try visitCmp(.f32, .f32Ge) }
    mutating func visitF64Eq() throws -> Output { try visitCmp(.f64, .f64Eq) }
    mutating func visitF64Ne() throws -> Output { try visitCmp(.f64, .f64Ne) }
    mutating func visitF64Lt() throws -> Output { try visitCmp(.f64, .f64Lt) }
    mutating func visitF64Gt() throws -> Output { try visitCmp(.f64, .f64Gt) }
    mutating func visitF64Le() throws -> Output { try visitCmp(.f64, .f64Le) }
    mutating func visitF64Ge() throws -> Output { try visitCmp(.f64, .f64Ge) }
    mutating func visitI32Clz() throws -> Output { try visitUnary(.i32, .i32Clz) }
    mutating func visitI32Ctz() throws -> Output { try visitUnary(.i32, .i32Ctz) }
    mutating func visitI32Popcnt() throws -> Output { try visitUnary(.i32, .i32Popcnt) }
    mutating func visitI32Add() throws -> Output { try visitBinary(.i32, .i32, .i32Add) }
    mutating func visitI32Sub() throws -> Output { try visitBinary(.i32, .i32, .i32Sub) }
    mutating func visitI32Mul() throws -> Output { try visitBinary(.i32, .i32, .i32Mul) }
    mutating func visitI32DivS() throws -> Output { try visitBinary(.i32, .i32, .i32DivS) }
    mutating func visitI32DivU() throws -> Output { try visitBinary(.i32, .i32, .i32DivU) }
    mutating func visitI32RemS() throws -> Output { try visitBinary(.i32, .i32, .i32RemS) }
    mutating func visitI32RemU() throws -> Output { try visitBinary(.i32, .i32, .i32RemU) }
    mutating func visitI32And() throws -> Output { try visitBinary(.i32, .i32, .i32And) }
    mutating func visitI32Or() throws -> Output { try visitBinary(.i32, .i32, .i32Or) }
    mutating func visitI32Xor() throws -> Output { try visitBinary(.i32, .i32, .i32Xor) }
    mutating func visitI32Shl() throws -> Output { try visitBinary(.i32, .i32, .i32Shl) }
    mutating func visitI32ShrS() throws -> Output { try visitBinary(.i32, .i32, .i32ShrS) }
    mutating func visitI32ShrU() throws -> Output { try visitBinary(.i32, .i32, .i32ShrU) }
    mutating func visitI32Rotl() throws -> Output { try visitBinary(.i32, .i32, .i32Rotl) }
    mutating func visitI32Rotr() throws -> Output { try visitBinary(.i32, .i32, .i32Rotr) }
    mutating func visitI64Clz() throws -> Output { try visitUnary(.i64, .i64Clz) }
    mutating func visitI64Ctz() throws -> Output { try visitUnary(.i64, .i64Ctz) }
    mutating func visitI64Popcnt() throws -> Output { try visitUnary(.i64, .i64Popcnt) }
    mutating func visitI64Add() throws -> Output { try visitBinary(.i64, .i64, .i64Add) }
    mutating func visitI64Sub() throws -> Output { try visitBinary(.i64, .i64, .i64Sub) }
    mutating func visitI64Mul() throws -> Output { try visitBinary(.i64, .i64, .i64Mul) }
    mutating func visitI64DivS() throws -> Output { try visitBinary(.i64, .i64, .i64DivS) }
    mutating func visitI64DivU() throws -> Output { try visitBinary(.i64, .i64, .i64DivU) }
    mutating func visitI64RemS() throws -> Output { try visitBinary(.i64, .i64, .i64RemS) }
    mutating func visitI64RemU() throws -> Output { try visitBinary(.i64, .i64, .i64RemU) }
    mutating func visitI64And() throws -> Output { try visitBinary(.i64, .i64, .i64And) }
    mutating func visitI64Or() throws -> Output { try visitBinary(.i64, .i64, .i64Or) }
    mutating func visitI64Xor() throws -> Output { try visitBinary(.i64, .i64, .i64Xor) }
    mutating func visitI64Shl() throws -> Output { try visitBinary(.i64, .i64, .i64Shl) }
    mutating func visitI64ShrS() throws -> Output { try visitBinary(.i64, .i64, .i64ShrS) }
    mutating func visitI64ShrU() throws -> Output { try visitBinary(.i64, .i64, .i64ShrU) }
    mutating func visitI64Rotl() throws -> Output { try visitBinary(.i64, .i64, .i64Rotl) }
    mutating func visitI64Rotr() throws -> Output { try visitBinary(.i64, .i64, .i64Rotr) }
    mutating func visitF32Abs() throws -> Output { try visitUnary(.f32, .f32Abs) }
    mutating func visitF32Neg() throws -> Output { try visitUnary(.f32, .f32Neg) }
    mutating func visitF32Ceil() throws -> Output { try visitUnary(.f32, .f32Ceil) }
    mutating func visitF32Floor() throws -> Output { try visitUnary(.f32, .f32Floor) }
    mutating func visitF32Trunc() throws -> Output { try visitUnary(.f32, .f32Trunc) }
    mutating func visitF32Nearest() throws -> Output { try visitUnary(.f32, .f32Nearest) }
    mutating func visitF32Sqrt() throws -> Output { try visitUnary(.f32, .f32Sqrt) }
    mutating func visitF32Add() throws -> Output { try visitBinary(.f32, .f32, .f32Add) }
    mutating func visitF32Sub() throws -> Output { try visitBinary(.f32, .f32, .f32Sub) }
    mutating func visitF32Mul() throws -> Output { try visitBinary(.f32, .f32, .f32Mul) }
    mutating func visitF32Div() throws -> Output { try visitBinary(.f32, .f32, .f32Div) }
    mutating func visitF32Min() throws -> Output { try visitBinary(.f32, .f32, .f32Min) }
    mutating func visitF32Max() throws -> Output { try visitBinary(.f32, .f32, .f32Max) }
    mutating func visitF32Copysign() throws -> Output { try visitBinary(.f32, .f32, .f32Copysign) }
    mutating func visitF64Abs() throws -> Output { try visitUnary(.f64, .f64Abs) }
    mutating func visitF64Neg() throws -> Output { try visitUnary(.f64, .f64Neg) }
    mutating func visitF64Ceil() throws -> Output { try visitUnary(.f64, .f64Ceil) }
    mutating func visitF64Floor() throws -> Output { try visitUnary(.f64, .f64Floor) }
    mutating func visitF64Trunc() throws -> Output { try visitUnary(.f64, .f64Trunc) }
    mutating func visitF64Nearest() throws -> Output { try visitUnary(.f64, .f64Nearest) }
    mutating func visitF64Sqrt() throws -> Output { try visitUnary(.f64, .f64Sqrt) }
    mutating func visitF64Add() throws -> Output { try visitBinary(.f64, .f64, .f64Add) }
    mutating func visitF64Sub() throws -> Output { try visitBinary(.f64, .f64, .f64Sub) }
    mutating func visitF64Mul() throws -> Output { try visitBinary(.f64, .f64, .f64Mul) }
    mutating func visitF64Div() throws -> Output { try visitBinary(.f64, .f64, .f64Div) }
    mutating func visitF64Min() throws -> Output { try visitBinary(.f64, .f64, .f64Min) }
    mutating func visitF64Max() throws -> Output { try visitBinary(.f64, .f64, .f64Max) }
    mutating func visitF64Copysign() throws -> Output { try visitBinary(.f64, .f64, .f64Copysign) }
    mutating func visitI32WrapI64() throws -> Output { try visitConversion(.i64, .i32, .i32WrapI64) }
    mutating func visitI32TruncF32S() throws -> Output { try visitConversion(.f32, .i32, .i32TruncF32S) }
    mutating func visitI32TruncF32U() throws -> Output { try visitConversion(.f32, .i32, .i32TruncF32U) }
    mutating func visitI32TruncF64S() throws -> Output { try visitConversion(.f64, .i32, .i32TruncF64S) }
    mutating func visitI32TruncF64U() throws -> Output { try visitConversion(.f64, .i32, .i32TruncF64U) }
    mutating func visitI64ExtendI32S() throws -> Output { try visitConversion(.i32, .i64, .i64ExtendI32S) }
    mutating func visitI64ExtendI32U() throws -> Output { try visitConversion(.i32, .i64, .i64ExtendI32U) }
    mutating func visitI64TruncF32S() throws -> Output { try visitConversion(.f32, .i64, .i64TruncF32S) }
    mutating func visitI64TruncF32U() throws -> Output { try visitConversion(.f32, .i64, .i64TruncF32U) }
    mutating func visitI64TruncF64S() throws -> Output { try visitConversion(.f64, .i64, .i64TruncF64S) }
    mutating func visitI64TruncF64U() throws -> Output { try visitConversion(.f64, .i64, .i64TruncF64U) }
    mutating func visitF32ConvertI32S() throws -> Output { try visitConversion(.i32, .f32, .f32ConvertI32S) }
    mutating func visitF32ConvertI32U() throws -> Output { try visitConversion(.i32, .f32, .f32ConvertI32U) }
    mutating func visitF32ConvertI64S() throws -> Output { try visitConversion(.i64, .f32, .f32ConvertI64S) }
    mutating func visitF32ConvertI64U() throws -> Output { try visitConversion(.i64, .f32, .f32ConvertI64U) }
    mutating func visitF32DemoteF64() throws -> Output { try visitConversion(.f64, .f32, .f32DemoteF64) }
    mutating func visitF64ConvertI32S() throws -> Output { try visitConversion(.i32, .f64, .f64ConvertI32S) }
    mutating func visitF64ConvertI32U() throws -> Output { try visitConversion(.i32, .f64, .f64ConvertI32U) }
    mutating func visitF64ConvertI64S() throws -> Output { try visitConversion(.i64, .f64, .f64ConvertI64S) }
    mutating func visitF64ConvertI64U() throws -> Output { try visitConversion(.i64, .f64, .f64ConvertI64U) }
    mutating func visitF64PromoteF32() throws -> Output { try visitConversion(.f32, .f64, .f64PromoteF32) }
    mutating func visitI32ReinterpretF32() throws -> Output { try visitConversion(.f32, .i32, .i32ReinterpretF32) }
    mutating func visitI64ReinterpretF64() throws -> Output { try visitConversion(.f64, .i64, .i64ReinterpretF64) }
    mutating func visitF32ReinterpretI32() throws -> Output { try visitConversion(.i32, .f32, .f32ReinterpretI32) }
    mutating func visitF64ReinterpretI64() throws -> Output { try visitConversion(.i64, .f64, .f64ReinterpretI64) }
    mutating func visitI32Extend8S() throws -> Output { try visitUnary(.i32, .i32Extend8S) }
    mutating func visitI32Extend16S() throws -> Output { try visitUnary(.i32, .i32Extend16S) }
    mutating func visitI64Extend8S() throws -> Output { try visitUnary(.i64, .i64Extend8S) }
    mutating func visitI64Extend16S() throws -> Output { try visitUnary(.i64, .i64Extend16S) }
    mutating func visitI64Extend32S() throws -> Output { try visitUnary(.i64, .i64Extend32S) }
    mutating func visitMemoryInit(dataIndex: UInt32) throws -> Output {
        let addressType = try module.addressType(memoryIndex: 0)
        try popPushEmit([.i32, .i32, addressType], [], .memoryInit(dataIndex))
    }
    mutating func visitDataDrop(dataIndex: UInt32) -> Output { emit(.memoryDataDrop(dataIndex)) }
    mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws -> Output {
        //     C.mems[0] = it limits
        // -----------------------------
        // C ⊦ memory.fill : [it i32 it] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        let addressType = try module.addressType(memoryIndex: 0)
        try popPushEmit([addressType, addressType, addressType], [], .memoryCopy)
    }
    mutating func visitMemoryFill(memory: UInt32) throws -> Output {
        //     C.mems[0] = it limits
        // -----------------------------
        // C ⊦ memory.fill : [it i32 it] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        let addressType = try module.addressType(memoryIndex: 0)
        try popPushEmit([addressType, .i32, addressType], [], .memoryFill)
    }
    mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws -> Output {
        try popPushEmit([.i32, .i32, module.addressType(tableIndex: table)], [], .tableInit(table, elemIndex))
    }
    mutating func visitElemDrop(elemIndex: UInt32) -> Output { emit(.tableElementDrop(elemIndex)) }
    mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws -> Output {
        //   C.tables[d] = iN limits t   C.tables[s] = iM limits t    K = min {N, M}
        // -----------------------------------------------------------------------------
        // C ⊦ table.copy d s : [iN iM iK] → []
        // https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md
        let destIsMemory64 = try module.isMemory64(tableIndex: dstTable)
        let sourceIsMemory64 = try module.isMemory64(tableIndex: srcTable)
        let lengthIsMemory64 = destIsMemory64 || sourceIsMemory64
        try popPushEmit(
            [
                .address(isMemory64: lengthIsMemory64),
                .address(isMemory64: sourceIsMemory64),
                .address(isMemory64: destIsMemory64),
            ],
            [],
            .tableCopy(dest: dstTable, src: srcTable)
        )
    }
    mutating func visitTableFill(table: UInt32) throws -> Output {
        let address = try module.addressType(tableIndex: table)
        try popPushEmit([address, .ref(module.elementType(table)), address], [], .tableFill(table))
    }
    mutating func visitTableGet(table: UInt32) throws -> Output {
        try popPushEmit(module.addressType(tableIndex: table), .ref(module.elementType(table)), .tableGet(table))
    }
    mutating func visitTableSet(table: UInt32) throws -> Output {
        try popPushEmit([.ref(module.elementType(table)), module.addressType(tableIndex: table)], [], .tableSet(table))
    }
    mutating func visitTableGrow(table: UInt32) throws -> Output {
        try popPushEmit([module.addressType(tableIndex: table), .ref(module.elementType(table))], [.i32], .tableGrow(table))
    }
    mutating func visitTableSize(table: UInt32) throws -> Output {
        pushEmit(try module.addressType(tableIndex: table), .tableSize(table))
    }
    mutating func visitI32TruncSatF32S() throws -> Output { try visitConversion(.f32, .i32, .i32TruncSatF32S) }
    mutating func visitI32TruncSatF32U() throws -> Output { try visitConversion(.f32, .i32, .i32TruncSatF32U) }
    mutating func visitI32TruncSatF64S() throws -> Output { try visitConversion(.f64, .i32, .i32TruncSatF64S) }
    mutating func visitI32TruncSatF64U() throws -> Output { try visitConversion(.f64, .i32, .i32TruncSatF64U) }
    mutating func visitI64TruncSatF32S() throws -> Output { try visitConversion(.f32, .i64, .i64TruncSatF32S) }
    mutating func visitI64TruncSatF32U() throws -> Output { try visitConversion(.f32, .i64, .i64TruncSatF32U) }
    mutating func visitI64TruncSatF64S() throws -> Output { try visitConversion(.f64, .i64, .i64TruncSatF64S) }
    mutating func visitI64TruncSatF64U() throws -> Output { try visitConversion(.f64, .i64, .i64TruncSatF64U) }
}

struct TranslationError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

extension ExpressionRef {
    fileprivate init(from source: InstructionTranslator.MetaProgramCounter, to destination: InstructionTranslator.MetaProgramCounter) {
        self.init(destination.offsetFromHead - source.offsetFromHead)
    }
}

extension FunctionType {
    fileprivate init(blockType: WasmParser.BlockType, typeSection: [FunctionType]) throws {
        switch blockType {
        case .type(let valueType):
            self.init(parameters: [], results: [valueType])
        case .empty:
            self.init(parameters: [], results: [])
        case let .funcType(typeIndex):
            let typeIndex = Int(typeIndex)
            guard typeIndex < typeSection.count else {
                throw WasmParserError.invalidTypeSectionReference
            }
            let funcType = typeSection[typeIndex]
            self.init(
                parameters: funcType.parameters,
                results: funcType.results
            )
        }
    }
}

extension ValueType {
    fileprivate static func address(isMemory64: Bool) -> ValueType {
        return isMemory64 ? .i64 : .i32
    }
}
