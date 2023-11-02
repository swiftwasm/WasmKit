import XCTest

@testable import WasmKit

final class VariableInstructionTests: XCTestCase {
    func testLocalSet() throws {
        let expression = Expression(instructions: [
            .numeric(.const(.i32(42))),
            .variable(.localSet(index: 0)),
        ])

        let module = Module(
            types: [
                FunctionType(parameters: [], results: [.i32])
            ],
            functions: [
                .init(type: 0, locals: [.i32], body: expression)
            ]
        )

        let runtime = Runtime()

        _ = try runtime.instantiate(module: module)

        try runtime.invoke(functionAddress: 0)

        try runtime.step()
        try runtime.step()

        XCTAssertEqual(runtime.stack.top, .label(.init(arity: 1, expression: expression, continuation: 1, exit: 1)))
        XCTAssertEqual(runtime.stack.currentFrame.locals, [.i32(42)])
    }

    func testLocalGet() throws {
        let module = Module(
            types: [
                FunctionType(parameters: [], results: [.i32])
            ],
            functions: [
                .init(
                    type: 0, locals: [.i32],
                    body: [
                        .numeric(.const(.i32(42))),
                        .variable(.localSet(index: 0)),
                        .variable(.localGet(index: 0)),
                    ])
            ]
        )

        let runtime = Runtime()

        _ = try runtime.instantiate(module: module)

        try runtime.invoke(functionAddress: 0)

        try runtime.step()
        try runtime.step()
        try runtime.step()

        XCTAssertEqual(runtime.stack.top, .value(.i32(42)))
        XCTAssertEqual(runtime.stack.currentFrame.locals, [.i32(42)])
    }

    func testLocalTee() throws {
        let module = Module(
            types: [
                FunctionType(parameters: [], results: [.i32])
            ],
            functions: [
                .init(
                    type: 0, locals: [.i32],
                    body: [
                        .numeric(.const(.i32(42))),
                        .variable(.localTee(index: 0)),
                    ])
            ]
        )

        let runtime = Runtime()

        _ = try runtime.instantiate(module: module)

        try runtime.invoke(functionAddress: 0)

        try runtime.step()
        try runtime.step()

        XCTAssertEqual(runtime.stack.top, .value(.i32(42)))
        XCTAssertEqual(runtime.stack.currentFrame.locals, [.i32(42)])
    }
}
