struct BranchLabel: Equatable {
    let label: Label
    var index: LabelIndex
}

/// See spec's
/// [definition](https://webassembly.github.io/spec/core/text/instructions.html?highlight=pseudo#control-instructions).
/// > The `block`, `loop` and `if` instructions are structured instructions. They bracket nested sequences of
/// > instructions, called blocks, terminated with, or separated by, end or else pseudo-instructions. As the
/// > grammar prescribes, they must be well-nested.
enum PseudoInstruction {
    case `else`
    case end
}

struct InstructionSequence: Equatable {
    let instructions: UnsafeBufferPointer<Instruction>

    init(instructions: [Instruction]) {
        assert(_isPOD(Instruction.self))
        let buffer = UnsafeMutableBufferPointer<Instruction>.allocate(capacity: instructions.count + 1)
        for (idx, instruction) in instructions.enumerated() {
            buffer[idx] = instruction
        }
        buffer[instructions.count] = .endOfFunction
        self.instructions = UnsafeBufferPointer(buffer)
    }

    func deallocate() {
        instructions.deallocate()
    }

    var baseAddress: UnsafePointer<Instruction> {
        self.instructions.baseAddress!
    }

    static func == (lhs: InstructionSequence, rhs: InstructionSequence) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

extension InstructionSequence: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Instruction...) {
        self.init(instructions: elements)
    }
}

struct ExpressionRef: Equatable {
    let relativeOffset: Int

    init(_ relativeOffset: Int) {
        self.relativeOffset = relativeOffset
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#expressions>

typealias Expression = [Instruction]
