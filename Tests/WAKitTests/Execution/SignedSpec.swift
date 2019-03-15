@testable import WAKit

import Quick
import Nimble

final class SignedSpec: QuickSpec {
    override func spec() {
        describe("Int32.signed") {
            it("should return its two's complement if negative") {
                expect(Int32(123).unsigned) == 123
                expect(Int32(-123).unsigned) == (UInt32(Int64(1 << 32) - 123))
            }
        }

        describe("UInt32.unsigned") {
            it("should be an inverse function of Int32.signed") {
                expect(Int32(123).unsigned.signed) == 123
                expect(Int32(-123).unsigned.signed) == -123
            }
        }
    }
}
