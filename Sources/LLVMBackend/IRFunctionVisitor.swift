import LLVMInterop
import WasmParser
import WasmTypes

struct IRFunctionVisitor: InstructionVisitor {
    enum Error: Swift.Error {
        case irFunctionUnknown(Int)
        case irFunctionCreationFailed
        case irFunctionStackNotEmpty
        case irFunctionVerificationFailure(String)
    }

    struct Local {
        let type: IRType
        let address: IRValue
    }
    private var locals: [Local]

    private var ir: IRContext
    let function: IRFunction

    var binaryOffset = 0

    private(set) var stack = [IRValue]()
    private(set) var types = [FunctionType]()
    private(set) var functionTypes = [TypeIndex]()
    private(set) var functionNames = [String]()
    private(set) var importedFunctions = [IRValue]()
    private(set) var memories = [Memory]()

    private let name: String
    private let code: Code
    private var blocks: [IRBlock]
    private var currentBlock: IRBlock

    /// Blocks that haven't had their own instructions visited yet, but are needed as targets of `br` instructions
    private var pendingBlocks = [IRBlock]()

    /// Trivial counter used for unique block names, incremented when new blocks are created.
    private var blockCounter = 0

    /// Representation of nested Wasm blocks to keep track of when converting to a linear sequence of LLVM IR basic blocks.
    struct NestedWasmBlock {
        enum Kind {
            case `if`(condition: IRValue)
            case loop
            case plain
        }

        let kind: Kind

        let parent: IRBlock
        let resultType: IRType?

        var branchBlocks = [IRBlock]()
        var phiValues = [IRValue]()
    }

    private var nestedBlocks = [NestedWasmBlock]()

    mutating func push(_ value: IRValue) {
        stack.append(value)
    }

    mutating func pop() -> IRValue {
        stack.removeLast()
    }

    init(name: String, type: FunctionType, locals: [ValueType], code: Code, ir: IRContext) throws {
        let functionType = ir.codegen(functionType: type)

        guard let function = ir.function(type: functionType, name: name) else {
            throw Error.irFunctionCreationFailed
        }

        self.name = name
        self.code = code
        self.ir = ir

        self.currentBlock = "entry".withStringRef { ir.__blockUnsafe(function, $0) }
        self.blocks = [self.currentBlock]
        self.ir.setInsertPoint(self.currentBlock)

        self.locals = locals.enumerated().map {
            let type = ir.codegen(type: $1)
            let address = ir.__createLocalUnsafe(type)
            let result = IRFunctionVisitor.Local(
                type: type,
                address: address
            )

            ir.setLocal(address, function.getArgument(UInt32($0)))

            return result
        }

        self.function = function
    }

    mutating func createBlock() {
        defer { self.blockCounter += 1 }
        "bb\(blockCounter)".withStringRef {
            self.currentBlock = self.ir.__blockUnsafe(self.function, $0)
        }
        self.blocks.append(self.currentBlock)
        self.ir.setInsertPoint(self.currentBlock)
    }

    mutating func visit(
        _ types: [FunctionType],
        _ functionTypes: [TypeIndex],
        _ memories: [Memory],
        importedFunctions: [IRValue],
        functionNames: [String]
    ) throws {
        self.types = types
        self.functionTypes = functionTypes
        self.memories = memories
        self.importedFunctions = importedFunctions
        self.functionNames = functionNames

        self.ir.setInsertPoint(self.currentBlock)

        try self.code.parseExpression(visitor: &self)

        // optimization passes don't like empty blocks
        if self.currentBlock.isEmpty() && self.blocks.count > 1 {
            self.currentBlock.eraseFromParent()
            self.blocks.removeLast()
            self.currentBlock = self.blocks.last!
            self.ir.setInsertPoint(self.currentBlock)
        }

        self.ir.createRet(pop())

        guard self.stack.isEmpty else {
            throw Error.irFunctionStackNotEmpty
        }

        if let error = self.function.verify().value {
            throw Error.irFunctionVerificationFailure(.init(error))
        }

        self.ir.optimize(self.function)

        if let error = self.function.verify().value {
            throw Error.irFunctionVerificationFailure(.init(error))
        }
    }

    mutating func visitCall(functionIndex: UInt32) throws {
        let functionIndex = Int(functionIndex)

        guard
            self.functionNames.count > functionIndex,
            let f = self.functionNames[functionIndex].withStringRef({ ir.getFunction($0) }).value
        else {
            throw Error.irFunctionUnknown(functionIndex)
        }

        let argTypes = self.types[Int(self.functionTypes[functionIndex])].parameters
        var args = IRValueVector()

        for _ in 0..<argTypes.count {
            args.push_back(self.pop()._v)
        }

        self.push(self.ir.__callUnsafe(f, args))
    }

    mutating func visitDrop() {
        _ = self.pop()
    }

    mutating func visitI32Const(value: Int32) {
        self.push(self.ir.__i32ValueUnsafe(.init(bitPattern: value)))
    }

    mutating func visitBinary(_ instruction: Instruction.Binary) {
        let v2 = pop()
        let v1 = pop()

        switch instruction {
        case .i32Add, .i64Add:
            push(ir.__iAddUnsafe(v1, v2))
        case .f32Add, .f64Add:
            push(ir.__fAddUnsafe(v1, v2))
        case .i32Sub, .i64Sub:
            push(ir.__iSubUnsafe(v1, v2))
        case .f32Sub, .f64Sub:
            push(ir.__fSubUnsafe(v1, v2))
        case .i32Mul, .i64Mul:
            push(ir.__iMulUnsafe(v1, v2))
        case .f32Mul, .f64Mul:
            push(ir.__fMulUnsafe(v1, v2))
        default:
            fatalError()
        }
    }

    mutating func visitCmp(_ instruction: Instruction.Cmp) throws {
        let v2 = pop()
        let v1 = pop()

        switch instruction {
        case .i32Eq, .i64Eq:
            push(ir.__iEqUnsafe(v1, v2))
        case .f32Eq, .f64Eq:
            push(ir.__fEqUnsafe(v1, v2))
        case .i32Ne, .i64Ne:
            push(ir.__iNeUnsafe(v1, v2))
        case .f32Ne, .f64Ne:
            push(ir.__fNeUnsafe(v1, v2))
        default:
            fatalError()
        }
    }

    mutating func visitLocalGet(localIndex: UInt32) throws {
        let local = self.locals[Int(localIndex)]
        push(ir.__getLocalUnsafe(local.type, local.address))
    }

    mutating func visitUnreachable() throws {
        self.ir.__unreachableUnsafe()
    }

    mutating func visitNop() throws {}
    mutating func visitEnd() throws {
        guard var lastNestedBlock = self.nestedBlocks.last else {
            return
        }

        if lastNestedBlock.resultType != nil {
            lastNestedBlock.phiValues.append(pop())
        }

        if case .if(let condition) = lastNestedBlock.kind {
            lastNestedBlock.branchBlocks.append(self.currentBlock)

            self.ir.setInsertPoint(lastNestedBlock.parent)

            if lastNestedBlock.branchBlocks.count > 1 {
                self.ir.__condBrUnsafe(
                    condition, lastNestedBlock.branchBlocks[0], lastNestedBlock.branchBlocks[1])
            } else {
                self.ir.__condBrUnsafe(condition, lastNestedBlock.branchBlocks[0])
            }
        }

        self.createBlock()

        if case .if = lastNestedBlock.kind, let resultType = lastNestedBlock.resultType {
            // Make sure that `branchBlocks` have terminators.
            for block in lastNestedBlock.branchBlocks {
                self.ir.setInsertPoint(block)

                // Terminators of `if` blocks should branch to the current block we've just created.
                self.ir.br(self.currentBlock)
            }
            // Set the insertion point back after it was moved for `branchBlocks`.
            self.ir.setInsertPoint(self.currentBlock)

            var phi = self.ir.__phiUnsafe(
                resultType, .init(lastNestedBlock.phiValues.count)
            )

            for (value, block) in zip(lastNestedBlock.phiValues, lastNestedBlock.branchBlocks) {
                phi.addIncoming(value, block)
            }

            self.push(IRValue(phi))
        }

        self.nestedBlocks.removeLast()
    }

    mutating func visitBlock(blockType: BlockType) throws { fatalError() }
    mutating func visitLoop(blockType: BlockType) throws { fatalError() }

    mutating func visitIf(blockType: BlockType) throws {
        let condition = self.ir.__bEqUnsafe(self.pop(), self.ir.__i32ValueUnsafe(1))

        switch blockType {
        case .funcType(let index):
            fatalError("multi-value blocks are currently not supported")

        case .empty:
            self.nestedBlocks.append(
                .init(kind: .if(condition: condition), parent: self.currentBlock, resultType: nil))

        case .type(let type):
            self.nestedBlocks.append(
                .init(
                    kind: .if(condition: condition), parent: self.currentBlock,
                    resultType: self.ir.codegen(type: type))
            )
        }

        createBlock()
    }

    mutating func visitElse() throws {
        guard let lastBlock = self.nestedBlocks.last, case .if = lastBlock.kind else {
            fatalError()
        }

        if lastBlock.resultType != nil {
            self.nestedBlocks[self.nestedBlocks.count - 1].phiValues.append(pop())
        }

        self.nestedBlocks[self.nestedBlocks.count - 1].branchBlocks.append(self.currentBlock)

        self.createBlock()
    }

    mutating func visitBr(relativeDepth: UInt32) throws { fatalError() }

    mutating func visitBrIf(relativeDepth: UInt32) throws { fatalError() }
    mutating func visitBrTable(targets: BrTable) throws { fatalError() }
    mutating func visitReturn() throws { fatalError() }
    mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws { fatalError() }
    mutating func visitReturnCall(functionIndex: UInt32) throws { fatalError() }
    mutating func visitReturnCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws {
        fatalError()
    }
    mutating func visitSelect() throws { fatalError() }
    mutating func visitTypedSelect(type: ValueType) throws { fatalError() }
    mutating func visitLocalSet(localIndex: UInt32) throws { fatalError() }
    mutating func visitLocalTee(localIndex: UInt32) throws { fatalError() }
    mutating func visitGlobalGet(globalIndex: UInt32) throws { fatalError() }
    mutating func visitGlobalSet(globalIndex: UInt32) throws { fatalError() }
    mutating func visitLoad(_ load: Instruction.Load, memarg: MemArg) throws { fatalError() }
    mutating func visitStore(_ store: Instruction.Store, memarg: MemArg) throws { fatalError() }
    mutating func visitMemorySize(memory: UInt32) throws { fatalError() }
    mutating func visitMemoryGrow(memory: UInt32) throws { fatalError() }
    mutating func visitI64Const(value: Int64) throws { fatalError() }
    mutating func visitF32Const(value: IEEE754.Float32) throws { fatalError() }
    mutating func visitF64Const(value: IEEE754.Float64) throws { fatalError() }
    mutating func visitI32Eqz() throws { fatalError() }
    mutating func visitI64Eqz() throws { fatalError() }
    mutating func visitUnary(_ unary: Instruction.Unary) throws { fatalError() }
    mutating func visitConversion(_ conversion: Instruction.Conversion) throws { fatalError() }
    mutating func visitMemoryInit(dataIndex: UInt32) throws { fatalError() }
    mutating func visitDataDrop(dataIndex: UInt32) throws { fatalError() }
    mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws { fatalError() }
    mutating func visitMemoryFill(memory: UInt32) throws { fatalError() }

    mutating func visitRefNull(type: ReferenceType) throws { fatalError() }
    mutating func visitRefIsNull() throws { fatalError() }
    mutating func visitRefFunc(functionIndex: UInt32) throws { fatalError() }

    mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws { fatalError() }
    mutating func visitElemDrop(elemIndex: UInt32) throws { fatalError() }
    mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws { fatalError() }
    mutating func visitTableFill(table: UInt32) throws { fatalError() }
    mutating func visitTableGet(table: UInt32) throws { fatalError() }
    mutating func visitTableSet(table: UInt32) throws { fatalError() }
    mutating func visitTableGrow(table: UInt32) throws { fatalError() }
    mutating func visitTableSize(table: UInt32) throws { fatalError() }

    private mutating func codegen(value: Value) {
        switch value {
        case .f32(let f32):
            push(ir.__f32ValueUnsafe(.init(bitPattern: f32)))
        case .f64(let f64):
            push(ir.__f64ValueUnsafe(.init(bitPattern: f64)))
        case .i32(let i32):
            push(ir.__i32ValueUnsafe(i32))
        case .i64(let i64):
            push(ir.__i64ValueUnsafe(i64))
        case .ref:
            fatalError()
        }
    }

    // mutating func codegen(conversion instruction: NumericInstruction.Conversion) {
    //   let v = pop()
    //
    //   switch instruction {
    //   case .wrap:
    //     push(ir.__wrapUnsafe(v))
    //   case .extendUnsigned:
    //     push(ir.__extendUnsignedUnsafe(v))
    //   case .extendSigned:
    //     push(ir.__extendSignedUnsafe(v))
    //   default:
    //     fatalError()
    //   }
    // }
}

extension IRFunction: @retroactive CustomStringConvertible {
    public var description: String {
        .init(self.print().value!)
    }
}

extension IRFunctionType: @retroactive CustomStringConvertible {
    public var description: String {
        .init(self.print())
    }
}
