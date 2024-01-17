import XCTest

@testable import WasmKit

final class ControlInstructionTests: XCTestCase {
    func testUnreachable() {
        let instruction = Instruction.control(.unreachable)
        var execution = ExecutionState()
        XCTAssertThrowsError(try execution.execute(instruction, runtime: Runtime())) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testNop() throws {
        let instruction = Instruction.control(.nop)
        var execution = ExecutionState()
        try execution.execute(instruction, runtime: Runtime())
        XCTAssertEqual(execution.programCounter, 1)
    }

    func testBlock() throws {
        let dummyExpression = Expression(instructions: [
            .numeric(.const(.i32(42)))
        ])

        let instruction = Instruction.control(
            .block(
                expression: dummyExpression, type: .single(.i32)
            )
        )

        var execution = ExecutionState()
        try execution.execute(instruction, runtime: Runtime())

        XCTAssertEqual(
            execution.stack.top,
            .label(.init(arity: 1, expression: dummyExpression, continuation: 1, exit: 1))
        )
        XCTAssertEqual(execution.programCounter, 0)
    }

    func testLoop() throws {
        let dummyExpression = Expression(instructions: [
            .numeric(.const(.i32(42)))
        ])

        let instruction = Instruction.control(
            .loop(
                expression: dummyExpression, type: .single(.i32)
            )
        )

        var execution = ExecutionState()
        try execution.execute(instruction, runtime: Runtime())
        XCTAssertEqual(
            execution.stack.top,
            .label(.init(arity: 0, expression: dummyExpression, continuation: 0, exit: 1))
        )
        XCTAssertEqual(execution.programCounter, 0)
    }

    func testIf_true() throws {
        let thenExpression = Expression(instructions: [
            .numeric(.const(.i32(42)))
        ])

        let elseExpression = Expression(instructions: [
            .control(.unreachable)
        ])

        let instruction = Instruction.control(
            .if(
                then: thenExpression,
                else: elseExpression,
                type: .single(.i32)
            )
        )

        var execution = ExecutionState()
        execution.stack.push(value: .i32(1))
        try execution.execute(instruction, runtime: Runtime())

        XCTAssertEqual(
            execution.stack.top,
            .label(.init(arity: 1, expression: thenExpression, continuation: 1, exit: 1))
        )
    }

    func testIf_false() throws {
        let thenExpression = Expression(instructions: [
            .control(.unreachable)
        ])

        let elseExpression = Expression(instructions: [
            .numeric(.const(.i32(42)))
        ])

        let instruction = Instruction.control(
            .if(
                then: thenExpression,
                else: elseExpression,
                type: .single(.i32)
            )
        )

        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(value: .i32(0))

        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(
            execution.stack.top,
            .label(.init(arity: 1, expression: elseExpression, continuation: 1, exit: 1))
        )
    }

    func testIf_noElse() throws {
        let thenExpression = Expression(instructions: [
            .control(.unreachable)
        ])

        let elseExpression = Expression(instructions: [])

        let instruction = Instruction.control(
            .if(
                then: thenExpression,
                else: elseExpression,
                type: .single(.i32)
            )
        )

        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(value: .i32(0))

        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(execution.stack.top, nil)

        execution.stack.push(value: .i32(1))
        execution.programCounter = 0

        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(
            execution.stack.top,
            .label(.init(arity: 1, expression: thenExpression, continuation: 1, exit: 1))
        )
    }

    func testIf_bareBreak() throws {
        let expression1 = Expression(instructions: [
            .numeric(.const(.i32(1))),
            .control(
                .if(
                    then: [.control(.br(0))],
                    else: [.control(.unreachable)],
                    type: .empty
                )),
        ])

        let module = Module(
            types: [
                FunctionType(parameters: [], results: [])
            ],
            functions: [
                .init(type: 0, locals: [], body: expression1)
            ]
        )

        var execution = ExecutionState()
        let runtime = Runtime()
        _ = try runtime.instantiate(module: module)

        try execution.invoke(functionAddress: 0, runtime: runtime)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<5 {
            try execution.step(runtime: runtime)
        }

        XCTAssertEqual(execution.stack.elements, [])
    }

    func testElse() throws {
        let instruction = Instruction.pseudo(.else)

        var execution = ExecutionState()
        XCTAssertThrowsError(try execution.execute(instruction, runtime: Runtime())) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testEnd() {
        let instruction = Instruction.pseudo(.end)

        var execution = ExecutionState()
        XCTAssertThrowsError(try execution.execute(instruction, runtime: Runtime())) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testBr0() throws {
        let instruction = Instruction.control(.br(0))
        let arity0 = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(label: arity0)

        try execution.execute(instruction, runtime: runtime)

        XCTAssertNil(execution.stack.top)
        XCTAssertEqual(execution.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        execution.stack.push(label: arity1)
        execution.stack.push(value: .i32(42))
        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(execution.stack.top, .value(.i32(42)))
        XCTAssertEqual(execution.programCounter, 321)
    }

    func testBr1() throws {
        let instruction = Instruction.control(.br(1))
        let arity0 = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(label: arity0)
        execution.stack.push(label: arity0)

        try execution.execute(instruction, runtime: runtime)

        XCTAssertNil(execution.stack.top)
        XCTAssertEqual(execution.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        execution.stack.push(label: arity1)
        execution.stack.push(label: arity1)
        execution.stack.push(value: .i32(42))
        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(execution.stack.top, .value(.i32(42)))
        XCTAssertEqual(execution.programCounter, 321)
    }

    func testBrIf_true() throws {
        let instruction = Instruction.control(.brIf(0))
        let label = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(label: label)
        execution.stack.push(value: .i32(1))
        try execution.execute(instruction, runtime: runtime)

        XCTAssertNil(execution.stack.top)
        XCTAssertEqual(execution.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        execution.stack.push(label: arity1)
        execution.stack.push(value: .i32(42))
        execution.stack.push(value: .i32(1))
        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(execution.stack.top, .value(.i32(42)))
        XCTAssertEqual(execution.programCounter, 321)
    }

    func testBrIf_false() throws {
        let instruction = Instruction.control(.brIf(0))
        let label = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        var execution = ExecutionState()
        let runtime = Runtime()
        execution.stack.push(label: label)
        execution.stack.push(value: .i32(0))
        try execution.execute(instruction, runtime: runtime)

        XCTAssertEqual(execution.stack.top, .label(label))
        XCTAssertEqual(execution.programCounter, 1)
    }

    func testCall() throws {
        let func1Expression = Expression(instructions: [
            .numeric(.const(.i32(42))),
            .control(.call(functionIndex: 1)),
            .numeric(.const(.i32(2))),
            .numeric(.binary(.add(.int(.i32)))),
        ])
        let func2Expression = Expression(instructions: [
            .variable(.localGet(index: 0)),
            .numeric(.const(.i32(1))),
            .numeric(.binary(.add(.int(.i32)))),
        ])

        let module = Module(
            types: [
                FunctionType(parameters: [], results: [.i32]),
                FunctionType(parameters: [.i32], results: [.i32]),
            ],
            functions: [
                .init(type: 0, locals: [], body: func1Expression),
                .init(type: 1, locals: [], body: func2Expression),
            ],
            exports: [.init(name: "start", descriptor: .function(0))]
        )

        let runtime = Runtime()
        let moduleInstance = try runtime.instantiate(module: module)

        let results = try runtime.invoke(moduleInstance, function: "start", with: [])
        XCTAssertEqual(results, [.i32(45)])
    }

    func testLoopBranch() throws {
        let expression1 = Expression(instructions: [
            .control(
                .loop(
                    expression: [
                        .numeric(.const(.i32(0))),
                        .control(.brIf(0)),
                    ],
                    type: .empty
                ))
        ])

        let loopRange = 5
        let loopRangeValue = Value.i32(.init(loopRange))

        let expression2 = Expression(instructions: [
            .control(
                .loop(
                    expression: [
                        .numeric(.const(.i32(1))),
                        .variable(.localGet(index: 0)),
                        .numeric(.binary(.add(.int(.i32)))),
                        .variable(.localTee(index: 0)),
                        .numeric(.const(loopRangeValue)),
                        .numeric(.intBinary(.ltU(.i32))),
                        .control(.brIf(0)),
                    ],
                    type: .empty
                )),
            .variable(.localGet(index: 0)),
        ])

        let module = Module(
            types: [
                FunctionType(parameters: [], results: []),
                FunctionType(parameters: [], results: [.i32]),
            ],
            functions: [
                .init(type: 0, locals: [], body: expression1),
                .init(type: 1, locals: [.i32], body: expression2),
            ]
        )

        var execution = ExecutionState()
        let runtime = Runtime()
        _ = try runtime.instantiate(module: module)

        try execution.invoke(functionAddress: 0, runtime: runtime)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<6 {
            try execution.step(runtime: runtime)
        }

        XCTAssertEqual(execution.stack.elements, [])

        try execution.invoke(functionAddress: 1, runtime: runtime)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<(loopRange * 8 + 4) {
            try execution.step(runtime: runtime)
        }

        XCTAssertEqual(execution.stack.elements, [.value(loopRangeValue)])
    }

    func testI32Load8() throws {
        var memory = MemoryInstance(.init(min: 1, max: nil))
        memory.data[0..<3] = [97, 98, 99, 100]  // ASCII "abcd"
        var execution = ExecutionState()
        let runtime = Runtime()
        runtime.store.memories.append(memory)

        let module = ModuleInstance()
        module.memoryAddresses = [0]

        let frame = try execution.stack.pushFrame(arity: 0, module: module, locals: [])
        execution.stack.push(value: .i32(0))

        let instruction = Instruction.memory(.load(.init(offset: 0, align: 1), bitWidth: 8, .i32, isSigned: false))

        try execution.execute(instruction, runtime: runtime)
        XCTAssertEqual(execution.programCounter, 1)
        XCTAssertEqual(execution.stack.elements, [.frame(frame), .value(.i32(97))])
    }
}

extension GuestFunction {
    init(type: TypeIndex, locals: [ValueType], body: Expression) {
        self.init(type: type, locals: locals, body: { body })
    }
}
