import WasmParser

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
    let _relativeOffset: UInt32
    var relativeOffset: Int {
        Int(_relativeOffset)
    }

    init(_ relativeOffset: Int) {
        self._relativeOffset = UInt32(relativeOffset)
    }
}
