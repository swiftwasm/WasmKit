@testable import WAKit
import XCTest

extension Int: Stackable {}

internal func XCTAssertEqual(
    _ stack: Stack,
    _ expectedEntries: [Stackable],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    let message = message() + " expected: \(expectedEntries), actual: \(stack.entries())"
    let actualEntries = stack.entries()

    guard actualEntries.count == expectedEntries.count else {
        return XCTFail(message)
    }

    for (actual, expected) in zip(actualEntries, expectedEntries) {
        switch (actual, expected) {
        case let (actual as Value, expected as Value):
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        case let (actual as Frame, expected as Frame):
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        case let (actual as Label, expected as Label):
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        default:
            return XCTFail(message)
        }
    }
}

final class StackTests: XCTestCase {
    func testStack() {
        var stack = Stack()
        XCTAssertNil(stack.top)

        let values = Array(1 ... 10)

        for v in values {
            stack.push(v)
            XCTAssertEqual(stack.top as? Int, v)
        }

        let expected = values.reversed()
        for v in expected {
            XCTAssertEqual(stack.pop() as? Int, v)
        }

        XCTAssertNil(stack.top)
    }
}
