import XCTest

@testable import WasmKit

final class ControlInstructionTests: XCTestCase {
    func testUnreachable() {
        let instruction = Instruction.control(.unreachable)
        let runtime = Runtime()
        XCTAssertThrowsError(try runtime.execute(instruction)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testNop() throws {
        let instruction = Instruction.control(.nop)
        let runtime = Runtime()
        try runtime.execute(instruction)
        XCTAssertEqual(runtime.programCounter, 1)
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

        let runtime = Runtime()
        try runtime.execute(instruction)

        XCTAssertEqual(
            runtime.stack.top,
            .label(.init(arity: 1, expression: dummyExpression, continuation: 1, exit: 1))
        )
        XCTAssertEqual(runtime.programCounter, 0)
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

        let runtime = Runtime()
        try runtime.execute(instruction)
        XCTAssertEqual(
            runtime.stack.top,
            .label(.init(arity: 0, expression: dummyExpression, continuation: 0, exit: 1))
        )
        XCTAssertEqual(runtime.programCounter, 0)
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

        let runtime = Runtime()
        runtime.stack.push(value: .i32(1))

        try runtime.execute(instruction)

        XCTAssertEqual(
            runtime.stack.top,
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

        let runtime = Runtime()
        runtime.stack.push(value: .i32(0))

        try runtime.execute(instruction)

        XCTAssertEqual(
            runtime.stack.top,
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

        let runtime = Runtime()
        runtime.stack.push(value: .i32(0))

        try runtime.execute(instruction)

        XCTAssertEqual(runtime.stack.top, nil)

        runtime.stack.push(value: .i32(1))
        runtime.programCounter = 0

        try runtime.execute(instruction)

        XCTAssertEqual(
            runtime.stack.top,
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

        let runtime = Runtime()
        _ = try runtime.instantiate(module: module)

        try runtime.invoke(functionAddress: 0)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<5 {
            try runtime.step()
        }

        XCTAssertEqual(runtime.stack.elements, [])
    }

    func testElse() throws {
        let instruction = Instruction.pseudo(.else)

        let runtime = Runtime()
        XCTAssertThrowsError(try runtime.execute(instruction)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testEnd() {
        let instruction = Instruction.pseudo(.end)

        let runtime = Runtime()
        XCTAssertThrowsError(try runtime.execute(instruction)) { error in
            guard case Trap.unreachable = error else {
                return XCTFail("unknown error thrown: \(error)")
            }
        }
    }

    func testBr0() throws {
        let instruction = Instruction.control(.br(0))
        let arity0 = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        let runtime = Runtime()
        runtime.stack.push(label: arity0)

        try runtime.execute(instruction)

        XCTAssertNil(runtime.stack.top)
        XCTAssertEqual(runtime.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        runtime.stack.push(label: arity1)
        runtime.stack.push(value: .i32(42))
        try runtime.execute(instruction)

        XCTAssertEqual(runtime.stack.top, .value(.i32(42)))
        XCTAssertEqual(runtime.programCounter, 321)
    }

    func testBr1() throws {
        let instruction = Instruction.control(.br(1))
        let arity0 = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        let runtime = Runtime()
        runtime.stack.push(label: arity0)
        runtime.stack.push(label: arity0)

        try runtime.execute(instruction)

        XCTAssertNil(runtime.stack.top)
        XCTAssertEqual(runtime.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        runtime.stack.push(label: arity1)
        runtime.stack.push(label: arity1)
        runtime.stack.push(value: .i32(42))
        try runtime.execute(instruction)

        XCTAssertEqual(runtime.stack.top, .value(.i32(42)))
        XCTAssertEqual(runtime.programCounter, 321)
    }

    func testBrIf_true() throws {
        let instruction = Instruction.control(.brIf(0))
        let label = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        let runtime = Runtime()
        runtime.stack.push(label: label)
        runtime.stack.push(value: .i32(1))
        try runtime.execute(instruction)

        XCTAssertNil(runtime.stack.top)
        XCTAssertEqual(runtime.programCounter, 123)

        let arity1 = Label(arity: 1, expression: [instruction], continuation: 321, exit: 0)
        runtime.stack.push(label: arity1)
        runtime.stack.push(value: .i32(42))
        runtime.stack.push(value: .i32(1))
        try runtime.execute(instruction)

        XCTAssertEqual(runtime.stack.top, .value(.i32(42)))
        XCTAssertEqual(runtime.programCounter, 321)
    }

    func testBrIf_false() throws {
        let instruction = Instruction.control(.brIf(0))
        let label = Label(arity: 0, expression: [instruction], continuation: 123, exit: 0)
        let runtime = Runtime()
        runtime.stack.push(label: label)
        runtime.stack.push(value: .i32(0))
        try runtime.execute(instruction)

        XCTAssertEqual(runtime.stack.top, .label(label))
        XCTAssertEqual(runtime.programCounter, 1)
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

        let runtime = Runtime()
        _ = try runtime.instantiate(module: module)

        try runtime.invoke(functionAddress: 0)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<6 {
            try runtime.step()
        }

        XCTAssertEqual(runtime.stack.elements, [])

        try runtime.invoke(functionAddress: 1)

        // Step a limited number of times to avoid infinite loops in case of test failure.
        for _ in 0..<(loopRange * 8 + 4) {
            try runtime.step()
        }

        XCTAssertEqual(runtime.stack.elements, [.value(loopRangeValue)])
    }

    func testI32Load8() throws {
        var memory = MemoryInstance(.init(min: 1, max: nil))
        memory.data[0..<3] = [97, 98, 99, 100]  // ASCII "abcd"
        let runtime = Runtime()
        runtime.store.memories.append(memory)

        let module = ModuleInstance()
        module.memoryAddresses = [0]

        let frame = Frame(arity: 0, module: module, locals: [])
        try runtime.stack.push(frame: frame)
        runtime.stack.push(value: .i32(0))

        let instruction = Instruction.memory(.load(.init(offset: 0, align: 1), bitWidth: 8, .i32, isSigned: false))

        try runtime.execute(instruction)
        XCTAssertEqual(runtime.programCounter, 1)
        XCTAssertEqual(runtime.stack.elements, [.frame(frame), .value(.i32(97))])
    }
}

extension Function {
    init(type: TypeIndex, locals: [ValueType], body: Expression) {
        self.init(type: type, locals: locals, body: { body })
    }
}
