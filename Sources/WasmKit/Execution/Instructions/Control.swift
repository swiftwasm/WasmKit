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

    func execute(runtime: Runtime) throws {
        switch self {
        case .unreachable:
            throw Trap.unreachable

        case .nop:
            runtime.programCounter += 1

        case let .block(expression, type):
            let (paramSize, resultSize) = type.arity(typeSection: { runtime.stack.currentFrame.module.types })
            let values = try runtime.stack.popValues(count: paramSize)
            runtime.enter(expression, continuation: runtime.programCounter + 1, arity: resultSize)
            runtime.stack.push(values: values)

        case let .loop(expression, type):
            let (paramSize, _) = type.arity(typeSection: { runtime.stack.currentFrame.module.types })
            let values = try runtime.stack.popValues(count: paramSize)
            runtime.enter(expression, continuation: runtime.programCounter, arity: paramSize)
            runtime.stack.push(values: values)

        case let .if(then, `else`, type):
            let isTrue = try runtime.stack.popValue().i32 != 0

            let expression: Expression
            if isTrue {
                expression = then
            } else {
                expression = `else`
            }

            if !expression.instructions.isEmpty {
                let derived = ControlInstruction.block(expression: expression, type: type)
                try derived.execute(runtime: runtime)
            } else {
                runtime.programCounter += 1
            }

        case let .brIf(labelIndex):
            guard try runtime.stack.popValue().i32 != 0 else {
                runtime.programCounter += 1
                return
            }

            fallthrough

        case let .br(labelIndex):
            try runtime.branch(labelIndex: Int(labelIndex))

        case let .brTable(labelIndices, defaultLabelIndex):
            let value = try runtime.stack.popValue().i32
            let labelIndex: LabelIndex
            if labelIndices.indices.contains(Int(value)) {
                labelIndex = labelIndices[Int(value)]
            } else {
                labelIndex = defaultLabelIndex
            }

            try runtime.branch(labelIndex: Int(labelIndex))

        case .return:
            let values = try runtime.stack.popValues(count: runtime.stack.currentFrame.arity)

            let currentFrame = Stack.Element.frame(runtime.stack.currentFrame)
            var lastLabel: Label?
            while runtime.stack.top != currentFrame {
                runtime.stack.discardTopValues()
                lastLabel = try runtime.stack.popLabel()
            }
            if let lastLabel {
                runtime.programCounter = lastLabel.continuation
            }
            runtime.stack.push(values: values)

        case let .call(functionIndex):
            let functionAddresses = runtime.stack.currentFrame.module.functionAddresses

            guard functionAddresses.indices.contains(Int(functionIndex)) else {
                throw Trap.invalidFunctionIndex(functionIndex)
            }

            try runtime.invoke(functionAddress: functionAddresses[Int(functionIndex)])

        case let .callIndirect(tableIndex, typeIndex):
            let moduleInstance = runtime.stack.currentFrame.module
            let tableAddresses = moduleInstance.tableAddresses[Int(tableIndex)]
            let tableInstance = runtime.store.tables[tableAddresses]
            let expectedType = moduleInstance.types[Int(typeIndex)]
            let value = try runtime.stack.popValue().i32
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

            try runtime.invoke(functionAddress: functionAddress)
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
