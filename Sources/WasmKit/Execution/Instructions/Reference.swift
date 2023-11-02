/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
enum ReferenceInstruction: Equatable {
    case refNull(ReferenceType)
    case refIsNull
    case refFunc(FunctionIndex)

    func execute(_ stack: inout Stack) throws {
        switch self {
        case let .refNull(type):
            switch type {
            case .externRef:
                stack.push(value: .ref(.extern(nil)))
            case .funcRef:
                stack.push(value: .ref(.function(nil)))
            }

        case .refIsNull:
            let value = try stack.popValue()

            switch value {
            case .ref(.extern(nil)), .ref(.function(nil)):
                stack.push(value: .i32(1))
            case .ref(.extern(_)), .ref(.function(_)):
                stack.push(value: .i32(0))
            default:
                fatalError("Invalid type \(value.type) for `\(#function)` implementation")
            }

        case let .refFunc(functionIndex):
            let functionAddress = stack.currentFrame.module.functionAddresses[Int(functionIndex)]

            stack.push(value: .ref(.function(functionAddress)))
        }
    }
}
