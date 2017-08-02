@testable import Swasm

import XCTest
import Nimble

class ValidationTests: XCTestCase {
	var context: Context!

	override func setUp() {
		super.setUp()
		context = Context()
	}
}

extension ValidationTests {
	func testLimits() {
		expect(
			try Limits(min: 0, max: 1).validate(with: self.context)
		).notTo(throwError())

		expect(
			try Limits(min: 2, max: 1).validate(with: self.context)
		).to(throwError(Limits.ValidationError.maxIsSmallerThanMin(min: 2, max: 1)))
	}
}

extension ValidationTests {
	func testFunctionTypeValidation() {
		var functionType: FunctionType

		functionType = FunctionType(parameters: [], results: [])
		XCTAssertNoThrow(try functionType.validate(with: context))

		functionType = FunctionType(parameters: [.int32], results: [.int32])
		XCTAssertNoThrow(try functionType.validate(with: context))

		functionType = FunctionType(parameters: [.int32], results: [.int32, .int64])
		XCTAssertThrowsError(try functionType.validate(with: context)) { error in
			guard case let FunctionType.ValidationError.tooManyResultTypes(types) = error else {
				XCTFail()
				return
			}
			XCTAssertEqual(functionType.results, types)
		}
	}
}
