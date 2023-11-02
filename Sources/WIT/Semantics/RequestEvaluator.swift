protocol EvaluationRequest: Hashable {
    associatedtype Output

    func evaluate(evaluator: Evaluator) throws -> Output
}

/// A central gate of computation that evaluates "requests" and caches their output, tracking dependencies graph.
/// This "Request-Evaluator" architecture allows to eliminate mutable state from AST, enable lazy-resolution, and
/// extremely simplifies cyclic-reference-detection.
///
/// This technique is heavily inspired by https://github.com/apple/swift/blob/main/docs/RequestEvaluator.md
internal class Evaluator {
    /// A cache that stores the result by request as a key
    private var cache: [AnyHashable: Result<Any, any Error>] = [:]
    /// A stack of current evaluating requests used to diagnostic report.
    /// The last element is the most recent request.
    private var activeRequests: [any EvaluationRequest] = []
    /// A set of current evaluating requests used for cyclic dependencies detection.
    private var activeRequestsSet: Set<AnyHashable> = []

    /// Create a new evaluator
    internal init() {}

    /// The entrypoint of the gate way, which evaluates the given request.
    /// - Parameter request: A request to be evaluated
    /// - Returns: Returns freshly-evaluated result if the request has never been evaluated yet.
    ///            Otherwise, returns the cached result.
    /// - Throws: Whatever is thrown by the `evaluate` method of the given request
    ///           and cyclic dependencies error if found.
    func evaluate<R: EvaluationRequest>(request: R) throws -> R.Output {
        let requestAsHashable = AnyHashable(request)
        if let cached = cache[requestAsHashable] {
            return try cached.get() as! R.Output
        }

        // Check cyclical request
        if activeRequestsSet.contains(requestAsHashable) {
            throw CyclicalRequestError(activeRequests: activeRequests + [request])
        }

        // Push the given request as an active request
        activeRequests.append(request)
        activeRequestsSet.insert(requestAsHashable)

        let result: Result<Any, any Error>
        defer {
            // Pop the request from active requests
            activeRequests.removeLast()
            activeRequestsSet.remove(requestAsHashable)

            // Cache the result by request as a key
            cache[requestAsHashable] = result
        }
        do {
            let output = try request.evaluate(evaluator: self)
            result = .success(output)
            return output
        } catch {
            result = .failure(error)
            throw error
        }
    }
}

extension Evaluator {
    struct CyclicalRequestError: Error, CustomStringConvertible {
        let activeRequests: [any EvaluationRequest]

        var description: String {
            var description = "==== Cycle detected! ====\n"
            for (index, request) in activeRequests.enumerated() {
                let indent = String(repeating: "  ", count: index)
                description += "\(indent)\\- \(request)\n"
            }
            return description
        }
    }
}
