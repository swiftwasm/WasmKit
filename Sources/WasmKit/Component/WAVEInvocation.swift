#if ComponentModel
    import ComponentModel
    import WAVE

    // MARK: - Component Invocation Errors

    /// Errors that can occur during component function invocation using WAVE syntax.
    public enum ComponentInvokeError: Error, CustomStringConvertible {
        /// Invalid WAVE syntax in the invocation expression
        case invalidSyntax(String)
        /// The specified function was not found in the component's exports
        case functionNotFound(String)
        /// Type mismatch between provided arguments and function signature
        case typeMismatch(String)

        public var description: String {
            switch self {
            case .invalidSyntax(let msg): return "Invalid syntax: \(msg)"
            case .functionNotFound(let name): return "Function '\(name)' not found in component exports"
            case .typeMismatch(let msg): return "Type mismatch: \(msg)"
            }
        }
    }

    // MARK: - WAVE Invocation Result

    /// The result of invoking a component function using WAVE syntax.
    public struct WAVEInvocationResult {
        /// The function that was invoked
        public let functionName: String
        /// The results returned by the function
        public let results: [ComponentValue]

        /// Format the results as a WAVE string.
        public func formatResults() -> String {
            if results.isEmpty {
                return ""
            } else if results.count == 1 {
                return WAVEFormatter.format(results[0])
            } else {
                let formatted = results.map { WAVEFormatter.format($0) }
                return "(\(formatted.joined(separator: ", ")))"
            }
        }
    }

    // MARK: - ComponentInstance WAVE Extension

    extension ComponentInstance {
        /// Invoke a component function using WAVE syntax.
        ///
        /// This method parses a WAVE function call expression like `get-answer()` or `add(1, 2)`
        /// and invokes the corresponding exported function with the parsed arguments.
        ///
        /// - Parameter waveExpression: A WAVE function call expression (e.g., `greet("World")`)
        /// - Returns: The invocation result containing the function name and results
        /// - Throws: `ComponentInvokeError` for syntax errors or missing functions,
        ///           or any error from the underlying function invocation
        ///
        /// Example:
        /// ```swift
        /// let result = try instance.invoke("add(1, 2)")
        /// print(result.formatResults())  // "3"
        /// ```
        @discardableResult
        public func invoke(_ waveExpression: String) throws -> WAVEInvocationResult {
            // Parse WAVE function call
            var parser = WAVEParser(waveExpression)
            let funcCall: WAVEParser.FunctionCall
            do {
                funcCall = try parser.parseFunctionCall()
            } catch {
                throw ComponentInvokeError.invalidSyntax("Parse error: \(error.message)")
            }
            // Look up the function
            guard let function = exportedFunction(funcCall.name) else {
                throw ComponentInvokeError.functionNotFound(funcCall.name)
            }

            // Parse arguments using WAVE
            let parsedArgs = try parseWAVEArguments(
                funcCall.argumentsString,
                for: function
            )

            // Invoke the function
            let results = try function.invoke(parsedArgs)

            return WAVEInvocationResult(functionName: funcCall.name, results: results)
        }
    }

    // MARK: - ComponentFunction WAVE Extension

    extension ComponentFunction {
        /// Invoke the function with arguments parsed from a WAVE argument string.
        ///
        /// - Parameter waveArguments: A WAVE argument string (e.g., `"hello", 42`)
        /// - Returns: The component values returned by the function
        /// - Throws: `ComponentInvokeError` for parse errors, or any invocation error
        @discardableResult
        public func invoke(waveArguments: String) throws -> [ComponentValue] {
            let parsedArgs = try parseWAVEArguments(waveArguments, for: self)
            return try invoke(parsedArgs)
        }
    }

    // MARK: - WAVE Argument Parsing

    /// Parse WAVE argument string into component values using function signature for type information.
    ///
    /// - Parameters:
    ///   - argumentsString: The raw argument string from WAVE parsing
    ///   - function: The function whose signature provides type information
    /// - Returns: Parsed component values ready for invocation
    /// - Throws: WAVE parsing errors
    public func parseWAVEArguments(
        _ argumentsString: String,
        for function: ComponentFunction
    ) throws -> [ComponentValue] {
        let params = function.type.params

        // Handle empty arguments
        if params.isEmpty && argumentsString.trimmingCharacters(in: .whitespaces).isEmpty {
            return []
        }

        // Use the component's type resolver for nested type lookups.
        let resolver: (ComponentTypeIndex) throws -> ComponentValueType = { idx in
            try function.resolveType(idx)
        }

        // Parse arguments
        var argsParser = WAVEParser(argumentsString)
        return try argsParser.parseArguments(
            params: params.map { $0.type },
            resolver: resolver
        )
    }

#endif
