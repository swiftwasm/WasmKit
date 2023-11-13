/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
enum ControlInstruction: Equatable {
    case unreachable
    case nop
    case block(expression: Expression, type: ResultType)
    case loop(expression: Expression, type: ResultType)
    case `if`(then: Expression, else: Expression, type: ResultType)
    case br(_ labelIndex: LabelIndex)
    case brIf(_ labelIndex: LabelIndex)
    case brTable(_ labelIndices: [LabelIndex], default: LabelIndex)
    case `return`
    case call(functionIndex: UInt32)
    case callIndirect(tableIndex: TableIndex, typeIndex: TypeIndex)

    func execute(runtime: Runtime, execution: inout ExecutionState) throws {
        switch self {
        case .unreachable:
            throw Trap.unreachable

        case .nop:
            execution.programCounter += 1

        case let .block(expression, type):
            let (paramSize, resultSize) = type.arity(typeSection: { execution.stack.currentFrame.module.types })
            let values = try execution.stack.popValues(count: paramSize)
            execution.enter(expression, continuation: execution.programCounter + 1, arity: resultSize)
            execution.stack.push(values: values)

        case let .loop(expression, type):
            let (paramSize, _) = type.arity(typeSection: { execution.stack.currentFrame.module.types })
            let values = try execution.stack.popValues(count: paramSize)
            execution.enter(expression, continuation: execution.programCounter, arity: paramSize)
            execution.stack.push(values: values)

        case let .if(then, `else`, type):
            let isTrue = try execution.stack.popValue().i32 != 0

            let expression: Expression
            if isTrue {
                expression = then
            } else {
                expression = `else`
            }

            if !expression.instructions.isEmpty {
                let derived = ControlInstruction.block(expression: expression, type: type)
                try derived.execute(runtime: runtime, execution: &execution)
            } else {
                execution.programCounter += 1
            }

        case let .brIf(labelIndex):
            guard try execution.stack.popValue().i32 != 0 else {
                execution.programCounter += 1
                return
            }

            fallthrough

        case let .br(labelIndex):
            try execution.branch(labelIndex: Int(labelIndex))

        case let .brTable(labelIndices, defaultLabelIndex):
            let value = try execution.stack.popValue().i32
            let labelIndex: LabelIndex
            if labelIndices.indices.contains(Int(value)) {
                labelIndex = labelIndices[Int(value)]
            } else {
                labelIndex = defaultLabelIndex
            }

            try execution.branch(labelIndex: Int(labelIndex))

        case .return:
            let values = try execution.stack.popValues(count: execution.stack.currentFrame.arity)

            let currentFrame = Stack.Element.frame(execution.stack.currentFrame)
            var lastLabel: Label?
            while execution.stack.top != currentFrame {
                execution.stack.discardTopValues()
                lastLabel = try execution.stack.popLabel()
            }
            if let lastLabel {
                execution.programCounter = lastLabel.continuation
            }
            execution.stack.push(values: values)

        case let .call(functionIndex):
            let functionAddresses = execution.stack.currentFrame.module.functionAddresses

            guard functionAddresses.indices.contains(Int(functionIndex)) else {
                throw Trap.invalidFunctionIndex(functionIndex)
            }

            try execution.invoke(functionAddress: functionAddresses[Int(functionIndex)], runtime: runtime)

        case let .callIndirect(tableIndex, typeIndex):
            let moduleInstance = execution.stack.currentFrame.module
            let tableAddresses = moduleInstance.tableAddresses[Int(tableIndex)]
            let tableInstance = runtime.store.tables[tableAddresses]
            let expectedType = moduleInstance.types[Int(typeIndex)]
            let value = try execution.stack.popValue().i32
            let elementIndex = Int(value)
            guard elementIndex < tableInstance.elements.count else {
                throw Trap.undefinedElement
            }
            guard case let .function(functionAddress?) = tableInstance.elements[elementIndex]
            else {
                throw Trap.tableUninitialized(ElementIndex(elementIndex))
            }
            let function = runtime.store.functions[functionAddress]
            guard function.type == expectedType else {
                throw Trap.callIndirectFunctionTypeMismatch(actual: function.type, expected: expectedType)
            }

            try execution.invoke(functionAddress: functionAddress, runtime: runtime)
        }
    }
}

extension ControlInstruction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .loop:
            return "loop"

        case .block:
            return "block"

        case let .br(i):
            return "br \(i)"

        case let .brIf(i):
            return "br_if \(i)"

        case let .brTable(i, d):
            return "br_if \(i.map(\.description).joined(separator: " ")) \(d)"

        case let .call(functionIndex):
            return "call \(functionIndex)"

        case let .callIndirect(tableIndex, typeIndex):
            return "call_indirect \(tableIndex) \(typeIndex)"

        case let .if(type, then, `else`):
            return """
                if \(type)\n  \(then)
                else\n  \(`else`)
                end
                """

        case .unreachable:
            return "unreachable"

        case .nop:
            return "nop"

        case .return:
            return "return"
        }
    }
}
