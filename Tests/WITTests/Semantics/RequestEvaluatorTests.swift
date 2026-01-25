import Testing

@testable import WIT

@Suite
struct RequestEvaluatorTests {
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

    @Test func memoization() throws {
        var invoked = 0
        let request = MyRequest(key: 1) { _ in
            invoked += 1
            return invoked
        }
        let evaluator = Evaluator()
        #expect(try evaluator.evaluate(request: request) == 1)
        // Ensure it returns the same value
        #expect(try evaluator.evaluate(request: request) == 1)
        // Ensure the evaluation method is called only once
        #expect(invoked == 1)
    }

    @Test func cycleDetection() throws {
        let evaluator = Evaluator()
        var capturedError: Error?
        do {
            try evaluator.evaluate(
                request: MyRequest(
                    key: 1,
                    evaluate: {
                        try $0.evaluate(
                            request: MyRequest(
                                key: 2,
                                evaluate: {
                                    try $0.evaluate(request: MyRequest(key: 1))  // again request key=1
                                }
                            )
                        )
                    }
                )
            )
            #expect((false), "CyclicalRequestError expected")
        } catch {
            capturedError = error
        }

        let cyclicalRequestError = try #require(capturedError as? Evaluator.CyclicalRequestError)
        #expect(cyclicalRequestError.activeRequestDescriptions.count == 3)
    }

    @Test func throwingRequest() throws {
        var invoked = 0
        let request = MyRequest(key: 1) { _ in
            invoked += 1
            throw MyError()
        }
        let evaluator = Evaluator()
        #expect(throws: (any Error).self) {
            try evaluator.evaluate(request: request)
        }
        #expect(throws: (any Error).self) {
            try evaluator.evaluate(request: request)
        }
        // Ensure the evaluation method is called only once even though
        // the request throws error
        #expect(invoked == 1)
    }
}
