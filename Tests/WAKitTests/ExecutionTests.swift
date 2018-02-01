@testable import WAKit
import XCTest

final class ExecutionTests: XCTestCase {
    func testExecution_const() throws {
        var stack = Stack()
        try Expression(instructions: [
            NumericInstruction.const(.i32(123)),
        ]).execute(stack: &stack)

        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(123)))
        XCTAssertEqual(stack.pop(), nil)
    }

    func testExecution_eqz() throws {
        var stack = Stack()
        try Expression(instructions: [
            NumericInstruction.const(.i32(123)),
            NumericInstruction.eqz(.i32),
            NumericInstruction.const(.i32(0)),
            NumericInstruction.eqz(.i32),
        ]).execute(stack: &stack)

        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(1)))
        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(0)))
        XCTAssertEqual(stack.pop(), nil)
    }

    func testExecution_eq() throws {
        var stack = Stack()
        try Expression(instructions: [
            NumericInstruction.const(.i32(123)),
            NumericInstruction.const(.i32(123)),
            NumericInstruction.eq(.i32),
            NumericInstruction.const(.i32(123)),
            NumericInstruction.const(.i32(456)),
            NumericInstruction.eq(.i32),
        ]).execute(stack: &stack)

        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(0)))
        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(1)))
        XCTAssertEqual(stack.pop(), nil)
    }

    func testExecution_ne() throws {
        var stack = Stack()
        try Expression(instructions: [
            NumericInstruction.const(.i32(123)),
            NumericInstruction.const(.i32(123)),
            NumericInstruction.ne(.i32),
            NumericInstruction.const(.i32(123)),
            NumericInstruction.const(.i32(456)),
            NumericInstruction.ne(.i32),
        ]).execute(stack: &stack)

        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(1)))
        XCTAssertEqual(stack.pop(), Stack.Element.value(.i32(0)))
        XCTAssertEqual(stack.pop(), nil)
    }
}
