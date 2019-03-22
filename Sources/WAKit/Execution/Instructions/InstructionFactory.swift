final class InstructionFactory {
    let code: InstructionCode

    init(code: InstructionCode) {
        self.code = code
    }

    func makeInstruction(_ implementation: @escaping Instruction.Implementation) -> Instruction {
        return Instruction(code, implementation: implementation)
    }
}
