#if ComponentModel
    import ComponentModel

    /// WAVE Parser - Type-directed parsing of WAVE format into ComponentValues
    public struct WAVEParser: ~Copyable {
        private var lexer: WAVELexer
        private let input: String

        public init(_ input: String) {
            self.input = input
            self.lexer = WAVELexer(input)
        }

        /// Extract a substring using byte offsets from a SourceSpan
        public func substring(from span: SourceSpan) -> String {
            let startIndex = input.utf8.index(input.utf8.startIndex, offsetBy: span.start)
            let endIndex = input.utf8.index(input.utf8.startIndex, offsetBy: span.end)
            return String(input[startIndex..<endIndex])
        }

        /// Extract a substring between two byte offsets
        public func substring(start: Int, end: Int) -> String {
            let startIndex = input.utf8.index(input.utf8.startIndex, offsetBy: start)
            let endIndex = input.utf8.index(input.utf8.startIndex, offsetBy: end)
            return String(input[startIndex..<endIndex])
        }

        /// Parse a value given its expected type
        public mutating func parse(type: ComponentValueType) throws(WAVEParserError) -> ComponentValue {
            switch type {
            case .bool:
                return try parseBool()
            case .u8, .u16, .u32, .u64:
                return try parseUnsignedInt(type: type)
            case .s8, .s16, .s32, .s64:
                return try parseSignedInt(type: type)
            case .float32:
                return try parseFloat32()
            case .float64:
                return try parseFloat64()
            case .char:
                return try parseChar()
            case .string:
                return try parseString()
            case .list(_):
                // For now, we need a type context to resolve the element type
                // This will be provided by the caller
                throw WAVEParserError("list type requires type context", span: try lexer.peek().span)
            case .tuple(_):
                throw WAVEParserError("tuple type requires type context", span: try lexer.peek().span)
            case .record(_):
                throw WAVEParserError("record type requires type context", span: try lexer.peek().span)
            case .variant(_):
                throw WAVEParserError("variant type requires type context", span: try lexer.peek().span)
            case .enum(let cases):
                return try parseEnum(cases: cases)
            case .flags(let flagNames):
                return try parseFlags(flagNames: flagNames)
            case .option(_):
                throw WAVEParserError("option type requires type context", span: try lexer.peek().span)
            case .result(_, _):
                throw WAVEParserError("result type requires type context", span: try lexer.peek().span)
            default:
                throw WAVEParserError("unsupported type", span: try lexer.peek().span)
            }
        }

        /// Parse a value with a type resolver for composite types
        public mutating func parse(
            type: ComponentValueType,
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            switch type {
            case .bool:
                return try parseBool()
            case .u8, .u16, .u32, .u64:
                return try parseUnsignedInt(type: type)
            case .s8, .s16, .s32, .s64:
                return try parseSignedInt(type: type)
            case .float32:
                return try parseFloat32()
            case .float64:
                return try parseFloat64()
            case .char:
                return try parseChar()
            case .string:
                return try parseString()
            case .list(let elementTypeIdx):
                let elementType = resolver(elementTypeIdx)
                return try parseList(elementType: elementType, resolver: resolver)
            case .tuple(let typeIndices):
                let types = typeIndices.map { resolver($0) }
                return try parseTuple(types: types, resolver: resolver)
            case .record(let fields):
                return try parseRecord(fields: fields, resolver: resolver)
            case .variant(let cases):
                return try parseVariant(cases: cases, resolver: resolver)
            case .enum(let cases):
                return try parseEnum(cases: cases)
            case .flags(let flagNames):
                return try parseFlags(flagNames: flagNames)
            case .option(let innerTypeIdx):
                let innerType = resolver(innerTypeIdx)
                return try parseOption(innerType: innerType, resolver: resolver)
            case .result(let okTypeIdx, let errTypeIdx):
                let okType = okTypeIdx.map { resolver($0) }
                let errType = errTypeIdx.map { resolver($0) }
                return try parseResult(okType: okType, errType: errType, resolver: resolver)
            case .indexed(let idx):
                return try parse(type: resolver(idx), resolver: resolver)
            default:
                throw WAVEParserError("unsupported type", span: try lexer.peek().span)
            }
        }

        // MARK: - Primitive Parsing

        private mutating func parseBool() throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            switch token {
            case .true:
                return .bool(true)
            case .false:
                return .bool(false)
            default:
                throw WAVEParserError("expected bool", span: token.span)
            }
        }

        private mutating func parseUnsignedInt(type: ComponentValueType) throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            guard case .number(let str, let span) = token else {
                throw WAVEParserError("expected number", span: token.span)
            }

            guard let value = UInt64(str) else {
                throw WAVEParserError("invalid integer", span: span)
            }

            switch type {
            case .u8:
                guard value <= UInt64(UInt8.max) else {
                    throw WAVEParserError("value out of range for u8", span: span)
                }
                return .u8(UInt8(value))
            case .u16:
                guard value <= UInt64(UInt16.max) else {
                    throw WAVEParserError("value out of range for u16", span: span)
                }
                return .u16(UInt16(value))
            case .u32:
                guard value <= UInt64(UInt32.max) else {
                    throw WAVEParserError("value out of range for u32", span: span)
                }
                return .u32(UInt32(value))
            case .u64:
                return .u64(value)
            default:
                fatalError("unreachable")
            }
        }

        private mutating func parseSignedInt(type: ComponentValueType) throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            guard case .number(let str, let span) = token else {
                throw WAVEParserError("expected number", span: token.span)
            }

            guard let value = Int64(str) else {
                throw WAVEParserError("invalid integer", span: span)
            }

            switch type {
            case .s8:
                guard value >= Int64(Int8.min) && value <= Int64(Int8.max) else {
                    throw WAVEParserError("value out of range for s8", span: span)
                }
                return .s8(Int8(value))
            case .s16:
                guard value >= Int64(Int16.min) && value <= Int64(Int16.max) else {
                    throw WAVEParserError("value out of range for s16", span: span)
                }
                return .s16(Int16(value))
            case .s32:
                guard value >= Int64(Int32.min) && value <= Int64(Int32.max) else {
                    throw WAVEParserError("value out of range for s32", span: span)
                }
                return .s32(Int32(value))
            case .s64:
                return .s64(value)
            default:
                fatalError("unreachable")
            }
        }

        private mutating func parseFloat32() throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            switch token {
            case .number(let str, let span):
                guard let value = Float(str) else {
                    throw WAVEParserError("invalid float", span: span)
                }
                return .float32(value)
            case .nan:
                return .float32(Float.nan)
            case .inf:
                return .float32(Float.infinity)
            case .negInf:
                return .float32(-Float.infinity)
            default:
                throw WAVEParserError("expected float", span: token.span)
            }
        }

        private mutating func parseFloat64() throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            switch token {
            case .number(let str, let span):
                guard let value = Double(str) else {
                    throw WAVEParserError("invalid float", span: span)
                }
                return .float64(value)
            case .nan:
                return .float64(Double.nan)
            case .inf:
                return .float64(Double.infinity)
            case .negInf:
                return .float64(-Double.infinity)
            default:
                throw WAVEParserError("expected float", span: token.span)
            }
        }

        private mutating func parseChar() throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            guard case .char(let scalar, _) = token else {
                throw WAVEParserError("expected char", span: token.span)
            }
            return .char(scalar)
        }

        private mutating func parseString() throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.next()
            guard case .string(let str, _) = token else {
                throw WAVEParserError("expected string", span: token.span)
            }
            return .string(str)
        }

        // MARK: - Composite Parsing

        private mutating func parseList(
            elementType: ComponentValueType,
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let open = try lexer.next()
            guard case .leftBracket = open else {
                throw WAVEParserError("expected '['", span: open.span)
            }

            var elements: [ComponentValue] = []

            // Check for empty list
            if case .rightBracket = try lexer.peek() {
                _ = try lexer.next()
                return .list(elements)
            }

            // Parse elements
            while true {
                let element = try parse(type: elementType, resolver: resolver)
                elements.append(element)

                let next = try lexer.peek()
                switch next {
                case .comma:
                    _ = try lexer.next()
                    // Allow trailing comma
                    if case .rightBracket = try lexer.peek() {
                        _ = try lexer.next()
                        return .list(elements)
                    }
                case .rightBracket:
                    _ = try lexer.next()
                    return .list(elements)
                default:
                    throw WAVEParserError("expected ',' or ']'", span: next.span)
                }
            }
        }

        private mutating func parseTuple(
            types: [ComponentValueType],
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let open = try lexer.next()
            guard case .leftParen = open else {
                throw WAVEParserError("expected '('", span: open.span)
            }

            var elements: [ComponentValue] = []

            for (i, type) in types.enumerated() {
                let element = try parse(type: type, resolver: resolver)
                elements.append(element)

                if i < types.count - 1 {
                    let comma = try lexer.next()
                    guard case .comma = comma else {
                        throw WAVEParserError("expected ','", span: comma.span)
                    }
                }
            }

            // Allow trailing comma
            if case .comma = try lexer.peek() {
                _ = try lexer.next()
            }

            let close = try lexer.next()
            guard case .rightParen = close else {
                throw WAVEParserError("expected ')'", span: close.span)
            }

            return .tuple(elements)
        }

        private mutating func parseRecord(
            fields: [ComponentRecordField],
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let open = try lexer.next()
            guard case .leftBrace = open else {
                throw WAVEParserError("expected '{'", span: open.span)
            }

            // Check for empty record {: }
            if case .colon = try lexer.peek() {
                _ = try lexer.next()  // consume :
                let close = try lexer.next()
                guard case .rightBrace = close else {
                    throw WAVEParserError("expected '}'", span: close.span)
                }
                // All fields must be optional and set to none
                var result: [(name: String, value: ComponentValue)] = []
                for field in fields {
                    let fieldType = resolver(field.type)
                    if case .option = fieldType {
                        result.append((field.name, .option(nil)))
                    } else {
                        throw WAVEParserError("non-optional field '\(field.name)' missing", span: open.span)
                    }
                }
                return .record(result)
            }

            var parsedFields: [String: ComponentValue] = [:]

            // Check for empty braces (flags syntax, not record)
            if case .rightBrace = try lexer.peek() {
                // This could be an empty flags value, not a record
                // For records, we need {: }
                throw WAVEParserError("expected field name or ':'", span: try lexer.peek().span)
            }

            // Parse fields
            while true {
                // Get field name (can be label or keyword like true, false, etc.)
                let labelToken = try lexer.next()
                let fieldName: String
                switch labelToken {
                case .label(let name, _), .escapedLabel(let name, _):
                    fieldName = name
                case .true:
                    fieldName = "true"
                case .false:
                    fieldName = "false"
                case .some:
                    fieldName = "some"
                case .none:
                    fieldName = "none"
                case .ok:
                    fieldName = "ok"
                case .err:
                    fieldName = "err"
                case .nan:
                    fieldName = "nan"
                case .inf:
                    fieldName = "inf"
                default:
                    throw WAVEParserError("expected field name", span: labelToken.span)
                }

                // Expect colon
                let colon = try lexer.next()
                guard case .colon = colon else {
                    throw WAVEParserError("expected ':'", span: colon.span)
                }

                // Find field type
                guard let fieldDef = fields.first(where: { $0.name == fieldName }) else {
                    throw WAVEParserError("unknown field '\(fieldName)'", span: labelToken.span)
                }

                let fieldType = resolver(fieldDef.type)
                let value = try parse(type: fieldType, resolver: resolver)
                parsedFields[fieldName] = value

                let next = try lexer.peek()
                switch next {
                case .comma:
                    _ = try lexer.next()
                    // Allow trailing comma
                    if case .rightBrace = try lexer.peek() {
                        _ = try lexer.next()
                        break
                    }
                    continue
                case .rightBrace:
                    _ = try lexer.next()
                    break
                default:
                    throw WAVEParserError("expected ',' or '}'", span: next.span)
                }
                break
            }

            // Build result with fields in definition order, filling in none for missing optionals
            var result: [(name: String, value: ComponentValue)] = []
            for field in fields {
                if let value = parsedFields[field.name] {
                    result.append((field.name, value))
                } else {
                    let fieldType = resolver(field.type)
                    if case .option = fieldType {
                        result.append((field.name, .option(nil)))
                    } else {
                        throw WAVEParserError("missing required field '\(field.name)'", span: open.span)
                    }
                }
            }

            return .record(result)
        }

        private mutating func parseVariant(
            cases: [ComponentCaseField],
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let labelToken = try lexer.next()
            let caseName: String
            switch labelToken {
            case .label(let name, _), .escapedLabel(let name, _):
                caseName = name
            case .true:
                caseName = "true"
            case .false:
                caseName = "false"
            case .some:
                caseName = "some"
            case .none:
                caseName = "none"
            case .ok:
                caseName = "ok"
            case .err:
                caseName = "err"
            case .nan:
                caseName = "nan"
            case .inf:
                caseName = "inf"
            default:
                throw WAVEParserError("expected variant case", span: labelToken.span)
            }

            // Find case definition
            guard let caseDef = cases.first(where: { $0.name == caseName }) else {
                throw WAVEParserError("unknown variant case '\(caseName)'", span: labelToken.span)
            }

            // Check for payload
            if let payloadTypeIdx = caseDef.type {
                let open = try lexer.next()
                guard case .leftParen = open else {
                    throw WAVEParserError("expected '(' for variant payload", span: open.span)
                }

                let payloadType = resolver(payloadTypeIdx)
                let payload = try parse(type: payloadType, resolver: resolver)

                let close = try lexer.next()
                guard case .rightParen = close else {
                    throw WAVEParserError("expected ')'", span: close.span)
                }

                return .variant(caseName: caseName, payload: payload)
            } else {
                return .variant(caseName: caseName, payload: nil)
            }
        }

        private mutating func parseEnum(cases: [String]) throws(WAVEParserError) -> ComponentValue {
            let labelToken = try lexer.next()
            let caseName: String
            switch labelToken {
            case .label(let name, _), .escapedLabel(let name, _):
                caseName = name
            // Reject bare keywords - they must be escaped with % to be used as identifiers
            case .true, .false, .some, .none, .ok, .err, .nan, .inf:
                throw WAVEParserError("invalid value type", span: labelToken.span)
            default:
                throw WAVEParserError("expected enum case", span: labelToken.span)
            }

            guard cases.contains(caseName) else {
                throw WAVEParserError("unknown enum case '\(caseName)'", span: labelToken.span)
            }

            return .enum(caseName)
        }

        private mutating func parseFlags(flagNames: [String]) throws(WAVEParserError) -> ComponentValue {
            let open = try lexer.next()
            guard case .leftBrace = open else {
                throw WAVEParserError("expected '{'", span: open.span)
            }

            var flags: Set<String> = []

            // Check for empty flags
            if case .rightBrace = try lexer.peek() {
                _ = try lexer.next()
                return .flags(flags)
            }

            // Parse flag names
            while true {
                let labelToken = try lexer.next()
                let flagName: String
                switch labelToken {
                case .label(let name, _), .escapedLabel(let name, _):
                    flagName = name
                default:
                    throw WAVEParserError("expected flag name", span: labelToken.span)
                }

                guard flagNames.contains(flagName) else {
                    throw WAVEParserError("unknown flag '\(flagName)'", span: labelToken.span)
                }

                // Check for duplicates
                if flags.contains(flagName) {
                    throw WAVEParserError("duplicate flag: \"\(flagName)\"", span: labelToken.span)
                }

                flags.insert(flagName)

                let next = try lexer.peek()
                switch next {
                case .comma:
                    _ = try lexer.next()
                    // Allow trailing comma
                    if case .rightBrace = try lexer.peek() {
                        _ = try lexer.next()
                        return .flags(flags)
                    }
                case .rightBrace:
                    _ = try lexer.next()
                    return .flags(flags)
                default:
                    throw WAVEParserError("expected ',' or '}'", span: next.span)
                }
            }
        }

        private mutating func parseOption(
            innerType: ComponentValueType,
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.peek()

            switch token {
            case .none:
                _ = try lexer.next()
                return .option(nil)
            case .some:
                _ = try lexer.next()
                let open = try lexer.next()
                guard case .leftParen = open else {
                    throw WAVEParserError("expected '('", span: open.span)
                }
                let inner = try parse(type: innerType, resolver: resolver)
                let close = try lexer.next()
                guard case .rightParen = close else {
                    throw WAVEParserError("expected ')'", span: close.span)
                }
                return .option(inner)
            default:
                // Flat form - parse as inner type (unless inner is option or result)
                if case .option = innerType {
                    throw WAVEParserError("nested option requires explicit 'some(...)' syntax", span: token.span)
                }
                if case .result = innerType {
                    throw WAVEParserError("option<result> requires explicit 'some(...)' syntax", span: token.span)
                }
                let inner = try parse(type: innerType, resolver: resolver)
                return .option(inner)
            }
        }

        private mutating func parseResult(
            okType: ComponentValueType?,
            errType: ComponentValueType?,
            resolver: (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> ComponentValue {
            let token = try lexer.peek()

            switch token {
            case .ok:
                _ = try lexer.next()
                if let okType = okType {
                    // Check for payload
                    if case .leftParen = try lexer.peek() {
                        _ = try lexer.next()
                        let payload = try parse(type: okType, resolver: resolver)
                        let close = try lexer.next()
                        guard case .rightParen = close else {
                            throw WAVEParserError("expected ')'", span: close.span)
                        }
                        return .result(ok: payload, error: nil)
                    }
                    // No payload - ok type might be unit
                }
                return .result(ok: nil, error: nil)
            case .err:
                _ = try lexer.next()
                if let errType = errType {
                    // Check for payload
                    if case .leftParen = try lexer.peek() {
                        _ = try lexer.next()
                        let payload = try parse(type: errType, resolver: resolver)
                        let close = try lexer.next()
                        guard case .rightParen = close else {
                            throw WAVEParserError("expected ')'", span: close.span)
                        }
                        return .result(ok: nil, error: payload)
                    }
                }
                // Use empty tuple as marker for err case with no payload
                return .result(ok: nil, error: .tuple([]))
            default:
                // Flat form - must have ok type that's not option or result
                guard let okType = okType else {
                    throw WAVEParserError("result with no ok type requires explicit 'ok' or 'err'", span: token.span)
                }
                if case .option = okType {
                    throw WAVEParserError("result<option> requires explicit 'ok(...)' syntax", span: token.span)
                }
                if case .result = okType {
                    throw WAVEParserError("result<result> requires explicit 'ok(...)' syntax", span: token.span)
                }
                let payload = try parse(type: okType, resolver: resolver)
                return .result(ok: payload, error: nil)
            }
        }

        // MARK: - Function Call Parsing

        /// Represents a parsed function call from WAVE text
        public struct FunctionCall {
            /// Leading comments before the function call
            public let comments: String
            /// Function name (kebab-case label)
            public let name: String
            /// Raw argument string (for re-parsing with type information)
            public let argumentsString: String
            /// Span of the function name
            public let nameSpan: SourceSpan
            /// Byte offset where arguments start in original input (for error span adjustment)
            public let argumentsStartOffset: Int
            /// Byte offset where function call starts (after comments) - for converting to relative spans
            public var functionCallStartOffset: Int { nameSpan.start }
        }

        /// Parse a function call: `// comments` + `label(args...)`
        ///
        /// This method extracts the function name and raw argument string,
        /// allowing the caller to re-parse arguments with type information.
        public mutating func parseFunctionCall() throws(WAVEParserError) -> FunctionCall {
            // Extract leading comments
            let comments = lexer.extractLeadingComments()

            // Parse function name
            let labelToken = try lexer.next()
            let funcName: String
            let nameSpan: SourceSpan
            switch labelToken {
            case .label(let name, let span):
                funcName = name
                nameSpan = span
            case .escapedLabel(let name, let span):
                funcName = name
                nameSpan = span
            default:
                throw WAVEParserError("expected function name", span: labelToken.span)
            }

            // Expect opening paren
            let open = try lexer.next()
            guard case .leftParen(let openSpan) = open else {
                throw WAVEParserError("expected '('", span: open.span)
            }

            let argsStart = openSpan.end

            // Scan to closing paren without tokenizing content
            // This avoids triggering lexer errors for invalid escapes inside strings
            let argsEnd = try lexer.scanToCloseParen()

            // Extract the argument string from the original input
            let argumentsString = substring(start: argsStart, end: argsEnd)

            return FunctionCall(
                comments: comments,
                name: funcName,
                argumentsString: argumentsString,
                nameSpan: nameSpan,
                argumentsStartOffset: argsStart
            )
        }

        /// Check if at end of input
        public mutating func isAtEnd() throws(WAVEParserError) -> Bool {
            if case .eof = try lexer.peek() {
                return true
            }
            return false
        }

        /// Expect semicolon
        public mutating func expectSemicolon() throws {
            let token = try lexer.next()
            guard case .semicolon = token else {
                throw WAVEParserError("expected ';'", span: token.span)
            }
        }

        /// Peek at next token
        public mutating func peek() throws(WAVEParserError) -> WAVEToken {
            return try lexer.peek()
        }

        /// Consume next token
        public mutating func next() throws(WAVEParserError) -> WAVEToken {
            return try lexer.next()
        }

        // MARK: - Argument List Parsing

        /// Parse a comma-separated list of arguments given their expected types.
        ///
        /// This is a convenience method for parsing function arguments where each
        /// argument's type is known from the function signature.
        ///
        /// - Parameters:
        ///   - params: The parameter types to parse, in order
        ///   - resolver: A function to resolve type indices to concrete types
        /// - Returns: The parsed argument values
        public mutating func parseArguments(
            params: [ComponentValueType],
            resolver: @escaping (ComponentTypeIndex) -> ComponentValueType
        ) throws(WAVEParserError) -> [ComponentValue] {
            var parsedArgs: [ComponentValue] = []

            for (i, paramType) in params.enumerated() {
                let value = try parse(type: paramType, resolver: resolver)
                parsedArgs.append(value)

                // Skip comma if not last param
                if i < params.count - 1 {
                    let next = try peek()
                    guard case .comma = next else {
                        throw WAVEParserError("expected ','", span: next.span)
                    }
                    _ = try self.next()
                }
            }

            return parsedArgs
        }
    }

    /// WAVE parsing error
    public struct WAVEParserError: Error, Equatable, Sendable {
        public let message: String
        public let span: SourceSpan

        public init(_ message: String, span: SourceSpan) {
            self.message = message
            self.span = span
        }
    }

#endif
