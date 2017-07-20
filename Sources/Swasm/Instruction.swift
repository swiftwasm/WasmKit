struct Expression {
	var instructions: [Instruction]
}

protocol Instruction: Validatable {
	var isConstant: Bool { get }
}

enum PseudoInstruction: Instruction {

	case end
	case `else`

	var isConstant: Bool {
		return false
	}

	func validate(with context: Context) throws {}

}
