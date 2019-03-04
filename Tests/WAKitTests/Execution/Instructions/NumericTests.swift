@testable import WAKit
import XCTest

final class NumericTests: XCTestCase {
    func testConst() {
        let runtime = Runtime()
        XCTAssertNoThrow(try runtime.execute(NumericInstruction.Constant.const(.Int32(123))))
        XCTAssertEqual(runtime.stack, [Value.Int32(123)])
    }

    func testClz() {
        let runtime = Runtime()

        runtime.stack.push(Value.Int32(rawValue: 0b0000_0000_1111_1111_0000_0000_1111_1111))
        XCTAssertNoThrow(try runtime.execute(NumericInstruction.Unary.clz(Value.Int32.self)))
        XCTAssertEqual(runtime.stack, [Value.Int32(8)])

        runtime.stack.push(Value.Int32(rawValue: 0b1111_1111_0000_0000_1111_1111_0000_0000))
        XCTAssertNoThrow(try runtime.execute(NumericInstruction.Unary.clz(Value.Int32.self)))
        XCTAssertEqual(runtime.stack, [Value.Int32(0), Value.Int32(8)])
    }
}
