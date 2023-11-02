import XCTest

@testable import WIT

class RequestEvaluatorTests: XCTestCase {
    struct MyRequest<T>: EvaluationRequest {
        let key: Int
        let evaluate: (Evaluator) throws -> T

        init(key: Int, evaluate: @escaping (Evaluator) throws -> T = { _ in }) {
            self.key = key
            self.evaluate = evaluate
        }

        func evaluate(evaluator: Evaluator) throws -> T {
            return try self.evaluate(evaluator)
        }

        static func == (lhs: MyRequest, rhs: MyRequest) -> Bool {
            return lhs.key == rhs.key
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }
    }

    struct MyError: Error {}

    func testMemoization() throws {
        var invoked = 0
        let request = MyRequest(key: 1) { _ in
            invoked += 1
            return invoked
        }
        let evaluator = Evaluator()
        XCTAssertEqual(try evaluator.evaluate(request: request), 1)
        // Ensure it returns the same value
        XCTAssertEqual(try evaluator.evaluate(request: request), 1)
        // Ensure the evaluation method is called only once
        XCTAssertEqual(invoked, 1)
    }

    func testCycleDetection() throws {
        let evaluator = Evaluator()
        var anyError: Error?
        XCTAssertThrowsError(
            try evaluator.evaluate(
                request: MyRequest(
                    key: 1,
                    evaluate: {
                        try $0.evaluate(
                            request: MyRequest(
                                key: 2,
                                evaluate: {
                                    try $0.evaluate(request: MyRequest(key: 1))  // again request key=1
                                }))
                    })),
            "CyclicalRequestError expected",
            { anyError = $0 }
        )

        let cyclicalRequestError = try XCTUnwrap(anyError as? Evaluator.CyclicalRequestError)
        XCTAssertEqual(cyclicalRequestError.activeRequests.count, 3)
    }

    func testThrowingRequest() throws {
        var invoked = 0
        let request = MyRequest(key: 1) { _ in
            invoked += 1
            throw MyError()
        }
        let evaluator = Evaluator()
        XCTAssertThrowsError(try evaluator.evaluate(request: request))
        XCTAssertThrowsError(try evaluator.evaluate(request: request))
        // Ensure the evaluation method is called only once even though
        // the request throws error
        XCTAssertEqual(invoked, 1)
    }
}
