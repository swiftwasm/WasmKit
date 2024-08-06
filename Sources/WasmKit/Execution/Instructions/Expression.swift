import WasmParser

struct InstructionSequence: Equatable {
    let instructions: UnsafeMutableBufferPointer<Instruction>
    /// The maximum height of the value stack during execution of this function.
    /// This height does not count the locals.
    let maxStackHeight: Int

    init(instructions: UnsafeMutableBufferPointer<Instruction>, maxStackHeight: Int) {
        self.instructions = instructions
        assert(self.instructions.last?.isEndOfFunction ?? false)
        self.maxStackHeight = maxStackHeight
    }

    var baseAddress: UnsafeMutablePointer<Instruction> {
        self.instructions.baseAddress!
    }

    static func == (lhs: InstructionSequence, rhs: InstructionSequence) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

extension InstructionSequence: TextOutputStreamable {
    func write<Target>(to target: inout Target) where Target : TextOutputStream {
        var hexOffsetWidth = String(self.instructions.count - 1, radix: 16).count
        hexOffsetWidth = (hexOffsetWidth + 1) & ~1
        for (index, instruction) in instructions.enumerated() {
            var hexOffset = String(index, radix: 16)
            while hexOffset.count < hexOffsetWidth {
                hexOffset = "0" + hexOffset
            }
            target.write("0x\(hexOffset): ")
            instruction.print(to: &target)
            target.write("\n")
        }
    }
}

extension Instruction {
    fileprivate var isEndOfFunction: Bool {
        if case .endOfFunction = self {
            return true
        }
        return false
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
