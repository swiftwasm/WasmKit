import XCTest

@testable import WasmKit

final class StackTests: XCTestCase {
    func testStack() throws {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let values = [UInt32](1...10)

        for v in values {
            stack.push(value: .i32(v))
            let top = try XCTUnwrap(stack.top)
            XCTAssertEqual(top, .value(.i32(v)))
        }

        let expected = values.reversed()
        for v in expected {
            XCTAssertEqual(try stack.popValue().i32, v)
        }

        XCTAssertNil(stack.top)
    }

    func testPushMultipleValues() {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let values = [UInt32](1...10).map { Value($0) }
        stack.push(values: values)
        XCTAssertEqual(stack.top, .value(.i32(10)))

        XCTAssertEqual(stack.elements, values.map { Stack.Element.value($0) })
    }

    func testPopMultipleValues() throws {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let values = [UInt32](1...10).map { Value($0) }
        stack.push(values: values)

        XCTAssertEqual(try stack.popValues(count: 10), values)
    }

    func testPopTopValues() throws {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let frame = Frame(arity: 0, module: ModuleInstance(), locals: [])
        try stack.push(frame: frame)
        let values = [UInt32](1...10).map { Value($0) }
        stack.push(values: values)

        XCTAssertEqual(try stack.popTopValues(), values)
        XCTAssertEqual(stack.top, .frame(frame))
    }

    func testPopFrame() throws {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let values = [UInt32](1...10).map { Value($0) }
        stack.push(values: values)

        let frame0 = Frame(arity: 0, module: .init(), locals: [])
        try stack.push(frame: frame0)

        stack.push(values: values)

        let frame1 = Frame(arity: 1, module: .init(), locals: [])
        try stack.push(frame: frame1)

        XCTAssertEqual(stack.currentFrame, frame1)

        try stack.popFrame()
        XCTAssertEqual(stack.currentFrame, frame0)

        stack.discardTopValues()
        try stack.popFrame()
        XCTAssertNil(stack.currentFrame)
    }

    func testPopLabel() throws {
        var stack = Stack()
        try stack.push(frame: .init(arity: 1, module: .init(), locals: []))
        let label24 = Label(arity: 1, expression: [], continuation: 24, exit: 0)
        stack.push(label: label24)
        let label123 = Label(arity: 1, expression: [], continuation: 123, exit: 0)
        stack.push(label: label123)

        try stack.push(frame: .init(arity: 1, module: .init(), locals: []))
        let label42 = Label(arity: 1, expression: [], continuation: 42, exit: 0)
        stack.push(label: label42)
        let label0 = Label(arity: 1, expression: [], continuation: 0, exit: 0)
        stack.push(label: label0)

        XCTAssertEqual(stack.currentLabel, label0)
        _ = try stack.popLabel()
        XCTAssertEqual(stack.currentLabel, label42)
        _ = try stack.popLabel()
        XCTAssertNil(stack.currentLabel)
        try stack.popFrame()
        XCTAssertEqual(stack.currentLabel, label123)
    }
}
