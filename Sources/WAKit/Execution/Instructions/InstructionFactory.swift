final class InstructionFactory {
    let code: InstructionCode

    init(code: InstructionCode) {
        self.code = code
    }

    func makeInstruction(
        implementation: @escaping Instruction.Implementation,
        validator: @escaping Instruction.Validator = {
            _, instr, _ in throw ValidationError(diagnostic: "unsupported: \(instr.code)")
        }
    ) -> Instruction {
        return Instruction(code, implementation: implementation, validator: validator)
    }
}
