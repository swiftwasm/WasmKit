@testable import WAKit

import XCTest

final class ControlInstructionTests: XCTestCase {
    var store: Store!
    var stack: Stack!

    override func setUp() {
        store = Store()
        stack = Stack()
    }

    func testUnreachable() {
        let instruction = InstructionFactory(code: .unreachable).unreachable
        let expression = Expression(instructions: [instruction])
        XCTAssertThrowsError(try expression.execute(address: 0, store: store, stack: &stack)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testNop() {
        let instruction = InstructionFactory(code: .nop).nop
        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )
    }

    func testBlock() {
        let dummyExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let instructions = InstructionFactory(code: .block).block(
            type: [.int(.i32)],
            expression: dummyExpression
        )
        XCTAssertEqual(instructions.map { $0.code }, [.block, .unreachable])

        let expression = Expression(instructions: instructions)
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )

        XCTAssertEqual(stack.top as? Label, Label(arity: 1, continuation: 2, range: 1 ... 1))
    }

    func testLoop() {
        let dummyExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let instructions = InstructionFactory(code: .loop).loop(
            type: [.int(.i32)],
            expression: dummyExpression
        )
        XCTAssertEqual(instructions.map { $0.code }, [.loop, .unreachable])

        let expression = Expression(instructions: instructions)
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )

        XCTAssertEqual(stack.top as? Label, Label(arity: 1, continuation: 0, range: 1 ... 1))
    }

    func testIf_true() {
        let thenExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let elseExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let instructions = InstructionFactory(code: .if).if(
            type: [.int(.i32)],
            then: thenExpression,
            else: elseExpression
        )

        stack.push(Value.i32(1))
        XCTAssertEqual(instructions.map { $0.code }, [.if, .unreachable, .unreachable])

        let expression = Expression(instructions: instructions)
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )

        XCTAssertEqual(stack.top as? Label, Label(arity: 1, continuation: 3, range: 1 ... 1))
    }

    func testIf_false() {
        let thenExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let elseExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let instructions = InstructionFactory(code: .if).if(
            type: [.int(.i32)],
            then: thenExpression,
            else: elseExpression
        )

        stack = Stack()

        stack.push(Value.i32(0))
        XCTAssertEqual(instructions.map { $0.code }, [.if, .unreachable, .unreachable])

        let expression = Expression(instructions: instructions)
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(2)
        )

        XCTAssertEqual(stack.top as? Label, Label(arity: 1, continuation: 3, range: 2 ... 2))
    }

    func testIf_noElse() {
        let thenExpression = Expression(instructions: [
            InstructionFactory(code: .unreachable).unreachable,
        ])

        let elseExpression = Expression(instructions: [])

        let instructions = InstructionFactory(code: .if).if(
            type: [.int(.i32)],
            then: thenExpression,
            else: elseExpression
        )

        stack = Stack()

        stack.push(Value.i32(0))
        XCTAssertEqual(instructions.map { $0.code }, [.if, .unreachable])

        let expression = Expression(instructions: instructions)
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(2)
        )

        XCTAssertNil(stack.top)
    }

    func testElse() {
        let instruction = InstructionFactory(code: .else).else
        XCTAssertEqual(instruction.code, .else)

        let expression = Expression(instructions: [instruction])
        XCTAssertThrowsError(try expression.execute(address: 0, store: store, stack: &stack)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testEnd() {
        let instruction = InstructionFactory(code: .end).end
        XCTAssertEqual(instruction.code, .end)

        let expression = Expression(instructions: [instruction])
        XCTAssertThrowsError(try expression.execute(address: 0, store: store, stack: &stack)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testBr() {
        stack.push(Label(arity: 0, continuation: 123, range: 0 ... 0))

        let instruction = InstructionFactory(code: .br).br(0)
        XCTAssertEqual(instruction.code, .br)

        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(123)
        )

        XCTAssertNil(stack.top)
    }

    func testBrIf_true() {
        stack.push(Label(arity: 0, continuation: 123, range: 0 ... 0))
        stack.push(Value.i32(1))

        let instruction = InstructionFactory(code: .br).brIf(0)
        XCTAssertEqual(instruction.code, .br)

        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(123)
        )

        XCTAssertNil(stack.top)
    }

    func testBrIf_false() {
        stack.push(Label(arity: 0, continuation: 123, range: 0 ... 0))
        stack.push(Value.i32(0))

        let instruction = InstructionFactory(code: .br).brIf(0)
        XCTAssertEqual(instruction.code, .br)

        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )

        XCTAssertEqual(stack.top as? Label, Label(arity: 0, continuation: 123, range: 0 ... 0))
    }

    func testCall() {
        let moduleInstance = ModuleInstance()
        moduleInstance.types = [FunctionType.some(parameters: [], results: [.int(.i32)])]
        moduleInstance.functionAddresses = [0]

        let funcExpression = Expression(instructions: [
            InstructionFactory(code: .i32_const).const(.i32(0)),
        ])

        store.functions = [
            FunctionInstance(Function(type: 0, locals: [], body: funcExpression), module: moduleInstance),
        ]

        let frame = Frame(arity: 0, module: moduleInstance, locals: [])
        stack.push(frame)

        let instruction = InstructionFactory(code: .call).call(0)
        XCTAssertEqual(instruction.code, .call)

        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.invoke(0)
        )
    }

    func testI32Load8() {
        let memory = MemoryInstance(.init(min: 1, max: nil))
        memory.data[0..<3] = [97, 98, 99, 100] // ASCII "abcd"
        store.memories.append(memory)

        let module = ModuleInstance()
        module.memoryAddresses = [0]

        let frame = Frame(arity: 0, module: module, locals: [])
        stack.push(frame)
        stack.push(Value.i32(0))

        let instruction = InstructionFactory(code: .i32_load8_u).load(.int(.i32), bitWidth: 8, isSigned: false, 0)
        XCTAssertEqual(instruction.code, .i32_load8_u)

        let expression = Expression(instructions: [instruction])
        XCTAssertEqual(
            try expression.execute(address: 0, store: store, stack: &stack),
            Instruction.Action.jump(1)
        )

        XCTAssertEqual(stack, [Value.i32(97), frame])
    }
}
