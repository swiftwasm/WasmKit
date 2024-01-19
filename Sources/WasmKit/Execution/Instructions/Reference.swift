/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
extension ExecutionState {
    mutating func refNull(runtime: Runtime, referenceType: ReferenceType) throws {
        switch referenceType {
        case .externRef:
            stack.push(value: .ref(.extern(nil)))
        case .funcRef:
            stack.push(value: .ref(.function(nil)))
        }
    }
    mutating func refIsNull(runtime: Runtime) throws {
        let value = try stack.popValue()

        switch value {
        case .ref(.extern(nil)), .ref(.function(nil)):
            stack.push(value: .i32(1))
        case .ref(.extern(_)), .ref(.function(_)):
            stack.push(value: .i32(0))
        default:
            fatalError("Invalid type \(value.type) for `\(#function)` implementation")
        }
    }
    mutating func refFunc(runtime: Runtime, functionIndex: FunctionIndex) throws {
        let module = runtime.store.module(address: stack.currentFrame.module)
        let functionAddress = module.functionAddresses[Int(functionIndex)]

        stack.push(value: .ref(.function(functionAddress)))
    }
}
