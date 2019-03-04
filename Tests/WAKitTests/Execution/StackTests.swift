@testable import WAKit
import XCTest

extension Int: Stackable {}

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
