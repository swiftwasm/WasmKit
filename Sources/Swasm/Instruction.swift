struct Expression {
	var instructions: [Instruction]
}

protocol Instruction {
	var isConstant: Bool { get }
}
