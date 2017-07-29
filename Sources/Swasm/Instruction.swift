struct Expression {
	var instructions: [AnyInstruction]
}

extension Expression: Equatable {
	static func == (lhs: Expression, rhs: Expression) -> Bool {
		return lhs.instructions == rhs.instructions
	}
}

protocol Instruction {
	var isConstant: Bool { get }

	func isEqual(to another: Instruction) -> Bool
}

struct AnyInstruction: Instruction {
	var isConstant: Bool {
		return instruction.isConstant
	}

	let instruction: Instruction

	func isEqual(to another: Instruction) -> Bool {
		return instruction.isEqual(to: instruction)
	}
}

extension AnyInstruction: Equatable {
	static func == (lhs: AnyInstruction, rhs: AnyInstruction) -> Bool {
		return lhs.instruction.isEqual(to: rhs.instruction)
	}
}
