import WasmParser

struct InstructionSequence: Equatable {
    let instructions: UnsafeBufferPointer<Instruction>
    /// The maximum height of the value stack during execution of this function.
    /// This height does not count the locals.
    let maxStackHeight: Int

    init(instructions: UnsafeBufferPointer<Instruction>, maxStackHeight: Int) {
        self.instructions = instructions
        assert(self.instructions.last == .endOfFunction)
        self.maxStackHeight = maxStackHeight
    }

    var baseAddress: UnsafePointer<Instruction> {
        self.instructions.baseAddress!
    }

    static func == (lhs: InstructionSequence, rhs: InstructionSequence) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

struct ExpressionRef: Equatable {
    let _relativeOffset: UInt32
    var relativeOffset: Int {
        Int(_relativeOffset)
    }

    init(_ relativeOffset: Int) {
        self._relativeOffset = UInt32(relativeOffset)
    }
}
