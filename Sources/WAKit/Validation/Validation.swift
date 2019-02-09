enum ValidationError: Error {
    case genericError
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/conventions.html#contexts>
final class ValidationContext {
    var types: [FunctionType] = []
    var functions: [FunctionType] = []
    var tables: [TableType] = []
    var memories: [MemoryType] = []
    var globals: [GlobalType] = []
    var locals: [ValueType] = []
    var labels: [ResultType] = []
    var `return`: ResultType?
}

protocol Validatable {
    func validate(context: ValidationContext) throws
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#types>

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#limits>
extension Limits: Validatable {
    func validate(context _: ValidationContext) throws {
        if let max = max {
            guard min < max else {
                throw ValidationError.genericError
            }
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#function-types>
extension FunctionType: Validatable {
    func validate(context _: ValidationContext) throws {
        guard let results = results else {
            return
        }
        guard results.count <= 1 else {
            throw ValidationError.genericError
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#table-types>
extension TableType: Validatable {
    func validate(context: ValidationContext) throws {
        try limits.validate(context: context)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#global-types>
extension GlobalType: Validatable {
    func validate(context _: ValidationContext) throws {}
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/instructions.html#instructions>

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/instructions.html#expressions>
extension Expression: Validatable {
    func validate(context: ValidationContext) throws {
        try validate(instructions: instructions, context: context)
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/valid/instructions.html#instruction-sequences>
    private func validate(instructions: [Instruction], context: ValidationContext) throws {
        guard !instructions.isEmpty else {
            return
        }

        var instructions = instructions
        let instruction = instructions.popLast()
        try validate(instructions: instructions, context: context)
        guard let i = instruction as? Validatable else {
            throw ValidationError.genericError
        }
        try i.validate(context: context)
    }
}
