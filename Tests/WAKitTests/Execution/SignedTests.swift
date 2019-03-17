@testable import WAKit

import XCTest

final class SignedTests: XCTestCase {
    func testSigned() {
        XCTAssertEqual(Int32(123).unsigned, 123)
        XCTAssertEqual(Int32(-123).unsigned, UInt32(Int64(1 << 32) - 123))
    }

    func testUnsigned() {
        XCTAssertEqual(Int32(123).unsigned.signed, 123)
        XCTAssertEqual(Int32(-123).unsigned.signed, -123)
    }
}
