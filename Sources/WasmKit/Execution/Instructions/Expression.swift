import WasmParser

struct InstructionSequence: Equatable {
    let instructions: UnsafeMutableBufferPointer<CodeSlot>
    /// The maximum height of the value stack during execution of this function.
    /// This height does not count the locals.
    let maxStackHeight: Int

    let constants: UnsafeBufferPointer<UntypedValue>

    init(instructions: UnsafeMutableBufferPointer<CodeSlot>, maxStackHeight: Int, constants: UnsafeBufferPointer<UntypedValue>) {
        self.instructions = instructions
        self.maxStackHeight = maxStackHeight
        self.constants = constants
    }

    var baseAddress: UnsafeMutablePointer<CodeSlot> {
        self.instructions.baseAddress!
    }

    static func == (lhs: InstructionSequence, rhs: InstructionSequence) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

extension InstructionSequence {
    func write<Target>(to target: inout Target, context: inout InstructionPrintingContext) where Target : TextOutputStream {
        var hexOffsetWidth = String(instructions.count - 1, radix: 16).count
        hexOffsetWidth = (hexOffsetWidth + 1) & ~1

        guard let cursorStart = instructions.baseAddress else { return }
        let cursorEnd = cursorStart.advanced(by: instructions.count)

        var cursor = cursorStart
        while cursor < cursorEnd {
            let index = cursor - cursorStart
            var hexOffset = String(index, radix: 16)
            while hexOffset.count < hexOffsetWidth {
                hexOffset = "0" + hexOffset
            }
            target.write("0x\(hexOffset): ")
            let instruction = Instruction.load(from: &cursor)
            context.print(instruction: instruction, to: &target)
            target.write("\n")
        }
    }
}
