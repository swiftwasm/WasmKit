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
    let instructions: [Instruction]

    init(instructions: [Instruction]) {
        self.instructions = instructions
    }
}

extension Expression: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Instruction...) {
        self.init(instructions: elements)
    }
}
