import WasmParser

struct InstructionSequence: Equatable {
    let instructions: UnsafeMutableRawBufferPointer
    /// The maximum height of the value stack during execution of this function.
    /// This height does not count the locals.
    let maxStackHeight: Int

    init(instructions: UnsafeMutableRawBufferPointer, maxStackHeight: Int) {
        self.instructions = instructions
        self.maxStackHeight = maxStackHeight
    }

    var baseAddress: UnsafeMutableRawPointer {
        self.instructions.baseAddress!
    }

    static func == (lhs: InstructionSequence, rhs: InstructionSequence) -> Bool {
        lhs.instructions.baseAddress == rhs.instructions.baseAddress
    }
}

extension InstructionSequence {
    func write<Target>(to target: inout Target, context: inout InstructionPrintingContext) where Target : TextOutputStream {
//        var hexOffsetWidth = String(instructions.count - 1, radix: 16).count
//        hexOffsetWidth = (hexOffsetWidth + 1) & ~1
//        for (index, instruction) in instructions.enumerated() {
//            var hexOffset = String(index, radix: 16)
//            while hexOffset.count < hexOffsetWidth {
//                hexOffset = "0" + hexOffset
//            }
//            target.write("0x\(hexOffset): ")
//            context.print(instruction: instruction, to: &target)
//            target.write("\n")
//        }
    }
}
