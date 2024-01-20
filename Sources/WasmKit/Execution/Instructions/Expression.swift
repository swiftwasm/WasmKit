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

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#expressions>
struct Expression: Equatable {
    /// Note that `end` or `else` pseudo instructions are omitted in this array
    let instructions: UnsafeBufferPointer<Instruction>

    init(instructions: [Instruction]) {
        assert(_isPOD(Instruction.self))
        let buffer = UnsafeMutableBufferPointer<Instruction>.allocate(capacity: instructions.count + 1)
        for (idx, instruction) in instructions.enumerated() {
            buffer[idx] = instruction
        }
        buffer[instructions.count] = .endExpr
        self.instructions = UnsafeBufferPointer(buffer)
    }

    func deallocate() {
        instructions.deallocate()
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

extension Expression: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Instruction...) {
        self.init(instructions: elements)
    }
}
