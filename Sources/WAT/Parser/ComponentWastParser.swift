#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    // MARK: - Component WAST Directive Types

    /// A directive in a Component WAST script.
    /// Mirrors WastDirective but for Component Model.
    public enum ComponentWastDirective {
        /// A component definition
        case component(ComponentDirective)

        /// Assert that a component is invalid (fails validation)
        /// Example: (assert_invalid (component ...) "error message")
        case assertInvalid(component: ComponentDirective, message: String)

        /// Assert that a component is malformed (fails parsing)
        /// Example: (assert_malformed (component quote "...") "error message")
        case assertMalformed(component: ComponentDirective, message: String)

        /// Assert that invoking a function returns expected values
        /// Example: (assert_return (invoke "func" (u32.const 1)) (bool.const true))
        case assertReturn(execute: ComponentWastExecute, results: [ComponentValue])

        /// Assert that invoking a function traps
        /// Example: (assert_trap (invoke "func") "trap message")
        case assertTrap(execute: ComponentWastExecute, message: String)

        /// Register a component with a name for later use
        /// Example: (register "name" $id)
        case register(name: String, componentId: String?)

        /// Invoke a component function
        /// Example: (invoke "func" (u32.const 42))
        case invoke(ComponentWastInvoke)
    }

    /// A component representation in "(component ...)" form in WAST.
    public struct ComponentDirective {
        /// The source of the component
        public let source: ComponentSource
        /// The name of the component specified in $id form
        public let id: String?
        /// The location of the component in the source
        public let location: Location
    }

    /// The source of a component in WAST.
    public enum ComponentSource {
        /// A parsed Component WAT
        case text(ComponentWatParser.ComponentDef)
        /// A text form of Component WAT (quoted strings)
        case quote([UInt8])
        /// A binary form of WebAssembly component
        case binary([UInt8])
    }

    /// Component-level execution in WAST.
    public enum ComponentWastExecute {
        /// Invoke a component function
        case invoke(ComponentWastInvoke)
        /// Get a component export value
        case get(component: String?, exportName: String)
    }

    /// A component function invocation in WAST.
    public struct ComponentWastInvoke {
        /// Optional component name (if not specified, use current component)
        public let component: String?
        /// The function name to invoke
        public let name: String
        /// Arguments to pass to the function (reuses ComponentValue from ComponentModel)
        public let args: [ComponentValue]
    }

    // MARK: - ComponentWastParser

    /// A parser for Component WAST format.
    /// Similar to WastParser but for Component Model scripts.
    public struct ComponentWastParser {
        var parser: Parser
        let features: WasmFeatureSet

        public init(_ input: String, features: WasmFeatureSet) {
            self.parser = Parser(input)
            self.features = features
        }

        // MARK: - Main Entry Point

        /// Saved parser state before the current directive, for error recovery
        private var savedParserBeforeDirective: Parser?

        /// Parse the next directive in the Component WAST script.
        public mutating func nextDirective() throws(WatParserError) -> ComponentWastDirective? {
            guard (try parser.peek(.leftParen)) != nil else { return nil }
            savedParserBeforeDirective = parser  // Save state before consuming opening paren
            try parser.consume()
            guard try ComponentWastDirective.peek(wastParser: self) else {
                if try peekComponentField() {
                    // Parse inline component, which doesn't include surrounding (component)
                    let location = savedParserBeforeDirective!.lexer.location()
                    let componentParser = ComponentWatParser(features: features)
                    var parserCopy = savedParserBeforeDirective!
                    let componentDef = try componentParser.parse(&parserCopy)
                    parser = parserCopy
                    savedParserBeforeDirective = nil
                    // Note: ComponentWatParser.parse() already consumes the closing )
                    return .component(
                        ComponentDirective(
                            source: .text(componentDef),
                            id: nil,
                            location: location
                        ))
                }
                throw WatParserError("unexpected component wast directive token", location: parser.lexer.location())
            }
            let directive = try ComponentWastDirective.parse(wastParser: &self)
            savedParserBeforeDirective = nil
            return directive
        }

        /// Skip the current directive after an error.
        /// Call this after catching an error from `nextDirective()`.
        /// This restores to before the directive and skips the entire paren block.
        public mutating func skipCurrentDirective() {
            // Restore to the saved position (before the directive's opening paren)
            if let saved = savedParserBeforeDirective {
                parser = saved
                savedParserBeforeDirective = nil
            }
            // Now skip the entire paren block
            guard (try? parser.peek(.leftParen)) != nil else { return }
            _ = try? parser.consume()  // consume the opening (
            var depth = 1
            while depth > 0 {
                guard let token = try? parser.consume() else { return }
                switch token.kind {
                case .leftParen:
                    depth += 1
                case .rightParen:
                    depth -= 1
                default:
                    break
                }
            }
        }

        // MARK: - Helper Methods

        private func peekComponentField() throws(WatParserError) -> Bool {
            guard let keyword = try parser.peekKeyword() else { return false }
            switch keyword {
            case "core", "type", "func", "import", "export", "instance", "alias", "canon":
                return true
            default:
                return false
            }
        }

        mutating func parens<T>(_ body: (inout ComponentWastParser) throws(WatParserError) -> T) throws(WatParserError) -> T {
            try parser.expect(.leftParen)
            let result = try body(&self)
            return result
        }

        // MARK: - Component Value Parsing

        /// Parse component argument values for invoke.
        /// Supports: u32.const, bool.const, char.const, etc.
        mutating func argumentValues() throws(WatParserError) -> [ComponentValue] {
            var values: [ComponentValue] = []
            while try parseComponentConstValue(&values) {}
            return values
        }

        /// Parse component expected values for assert_return.
        mutating func expectationValues() throws(WatParserError) -> [ComponentValue] {
            var values: [ComponentValue] = []
            while try parseComponentConstValue(&values) {}
            return values
        }

        // MARK: - Component Const Value Parsing

        /// Parse a single component const value instruction.
        /// Returns true if a value was parsed.
        private mutating func parseComponentConstValue(_ values: inout [ComponentValue]) throws(WatParserError) -> Bool {
            // Check if we're at a left paren
            guard (try parser.peek(.leftParen)) != nil else { return false }

            // Peek at the keyword after the paren
            var lookahead = parser
            try lookahead.consume()  // consume left paren
            guard let keyword = try lookahead.peekKeyword() else { return false }

            // Parse based on keyword
            switch keyword {
            // Unsigned integers
            case "u8.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("u8.const")
                let value = try parser.expectUnsignedInt(UInt8.self)
                values.append(.u8(value))
                try parser.expect(.rightParen)
                return true

            case "u16.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("u16.const")
                let value = try parser.expectUnsignedInt(UInt16.self)
                values.append(.u16(value))
                try parser.expect(.rightParen)
                return true

            case "u32.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("u32.const")
                let value = try parser.expectUnsignedInt(UInt32.self)
                values.append(.u32(value))
                try parser.expect(.rightParen)
                return true

            case "u64.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("u64.const")
                let value = try parser.expectUnsignedInt(UInt64.self)
                values.append(.u64(value))
                try parser.expect(.rightParen)
                return true

            // Signed integers
            case "s8.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("s8.const")
                let value: Int8 = try parser.expectSignedInt(fromBitPattern: Int8.init(bitPattern:))
                values.append(.s8(value))
                try parser.expect(.rightParen)
                return true

            case "s16.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("s16.const")
                let value: Int16 = try parser.expectSignedInt(fromBitPattern: Int16.init(bitPattern:))
                values.append(.s16(value))
                try parser.expect(.rightParen)
                return true

            case "s32.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("s32.const")
                let value: Int32 = try parser.expectSignedInt(fromBitPattern: Int32.init(bitPattern:))
                values.append(.s32(value))
                try parser.expect(.rightParen)
                return true

            case "s64.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("s64.const")
                let value: Int64 = try parser.expectSignedInt(fromBitPattern: Int64.init(bitPattern:))
                values.append(.s64(value))
                try parser.expect(.rightParen)
                return true

            // Boolean
            case "bool.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("bool.const")
                let boolKeyword = try parser.expectKeyword()
                let value: Bool
                switch boolKeyword {
                case "true": value = true
                case "false": value = false
                default:
                    throw WatParserError("expected 'true' or 'false'", location: parser.lexer.location())
                }
                values.append(.bool(value))
                try parser.expect(.rightParen)
                return true

            // Floating point
            case "float32.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("float32.const")
                let value = try parser.expectFloat32()
                values.append(.float32(Float(bitPattern: value.bitPattern)))
                try parser.expect(.rightParen)
                return true

            case "float64.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("float64.const")
                let value = try parser.expectFloat64()
                values.append(.float64(Double(bitPattern: value.bitPattern)))
                try parser.expect(.rightParen)
                return true

            // Character
            case "char.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("char.const")
                let str = try parser.expectString()
                guard let scalar = str.unicodeScalars.first, str.unicodeScalars.count == 1 else {
                    throw WatParserError("char.const expects a single character", location: parser.lexer.location())
                }
                values.append(.char(scalar))
                try parser.expect(.rightParen)
                return true

            // String (using "str.const" per component model test syntax)
            case "str.const":
                try parser.expect(.leftParen)
                try parser.expectKeyword("str.const")
                let str = try parser.expectString()
                values.append(.string(str))
                try parser.expect(.rightParen)
                return true

            default:
                return false
            }
        }
    }

    // MARK: - Directive Parsing

    extension ComponentWastDirective {
        static func peek(wastParser: ComponentWastParser) throws(WatParserError) -> Bool {
            guard let keyword = try wastParser.parser.peekKeyword() else { return false }
            return keyword.starts(with: "assert_")
                || keyword == "component"
                || keyword == "register"
                || keyword == "invoke"
        }

        /// Parse a directive in a Component WAST script from "keyword ...)" form.
        /// Leading left parenthesis is already consumed.
        static func parse(wastParser: inout ComponentWastParser) throws(WatParserError) -> ComponentWastDirective {
            let keyword = try wastParser.parser.peekKeyword()
            switch keyword {
            case "component":
                return .component(try ComponentDirective.parse(wastParser: &wastParser))

            case "assert_invalid":
                try wastParser.parser.consume()
                let component = try wastParser.parens { wp throws(WatParserError) in
                    try ComponentDirective.parse(wastParser: &wp)
                }
                let message = try wastParser.parser.expectString()
                try wastParser.parser.expect(.rightParen)
                return .assertInvalid(component: component, message: message)

            case "assert_malformed":
                try wastParser.parser.consume()
                let component = try wastParser.parens { wp throws(WatParserError) in
                    try ComponentDirective.parse(wastParser: &wp)
                }
                let message = try wastParser.parser.expectString()
                try wastParser.parser.expect(.rightParen)
                return .assertMalformed(component: component, message: message)

            case "assert_return":
                try wastParser.parser.consume()
                let execute = try wastParser.parens { wp throws(WatParserError) in
                    try ComponentWastExecute.parse(wastParser: &wp)
                }
                let results = try wastParser.expectationValues()
                try wastParser.parser.expect(.rightParen)
                return .assertReturn(execute: execute, results: results)

            case "assert_trap":
                try wastParser.parser.consume()
                let execute = try wastParser.parens { wp throws(WatParserError) in
                    try ComponentWastExecute.parse(wastParser: &wp)
                }
                let message = try wastParser.parser.expectString()
                try wastParser.parser.expect(.rightParen)
                return .assertTrap(execute: execute, message: message)

            case "register":
                try wastParser.parser.consume()
                let name = try wastParser.parser.expectString()
                let componentId = try wastParser.parser.takeId()
                try wastParser.parser.expect(.rightParen)
                return .register(name: name, componentId: componentId?.value)

            case "invoke":
                let invoke = try ComponentWastInvoke.parse(wastParser: &wastParser)
                return .invoke(invoke)

            case let keyword?:
                throw WatParserError(
                    "unexpected component wast directive \(keyword)",
                    location: wastParser.parser.lexer.location()
                )
            case nil:
                throw WatParserError("unexpected eof", location: wastParser.parser.lexer.location())
            }
        }
    }

    // MARK: - ComponentDirective Parsing

    extension ComponentDirective {
        static func parse(wastParser: inout ComponentWastParser) throws(WatParserError) -> ComponentDirective {
            let location = wastParser.parser.lexer.location()
            try wastParser.parser.expectKeyword("component")
            let id = try wastParser.parser.takeId()
            let source = try ComponentSource.parse(wastParser: &wastParser, id: id)
            return ComponentDirective(source: source, id: id?.value, location: location)
        }
    }

    extension ComponentSource {
        static func parse(wastParser: inout ComponentWastParser, id: Name?) throws(WatParserError) -> ComponentSource {
            if let rawSource = try wastParser.parser.parseBinaryOrQuote() {
                try wastParser.parser.expect(.rightParen)
                switch rawSource {
                case .binary(let bytes): return .binary(bytes)
                case .quote(let bytes): return .quote(bytes)
                }
            }

            // Parse as text component using ComponentWatParser
            // Note: `(component $id?` has already been consumed, so we use parseComponentBody
            let componentParser = ComponentWatParser(features: wastParser.features)
            let componentDef = try componentParser.parseComponentBody(&wastParser.parser, id: id)
            return .text(componentDef)
        }
    }

    // MARK: - ComponentWastExecute Parsing

    extension ComponentWastExecute {
        static func parse(wastParser: inout ComponentWastParser) throws(WatParserError) -> ComponentWastExecute {
            let keyword = try wastParser.parser.peekKeyword()
            switch keyword {
            case "invoke":
                return .invoke(try ComponentWastInvoke.parse(wastParser: &wastParser))
            case "get":
                try wastParser.parser.consume()
                let component = try wastParser.parser.takeId()
                let exportName = try wastParser.parser.expectString()
                try wastParser.parser.expect(.rightParen)
                return .get(component: component?.value, exportName: exportName)
            case let keyword?:
                throw WatParserError(
                    "unexpected component wast execute \(keyword)",
                    location: wastParser.parser.lexer.location()
                )
            case nil:
                throw WatParserError("unexpected eof", location: wastParser.parser.lexer.location())
            }
        }
    }

    // MARK: - ComponentWastInvoke Parsing

    extension ComponentWastInvoke {
        static func parse(wastParser: inout ComponentWastParser) throws(WatParserError) -> ComponentWastInvoke {
            try wastParser.parser.expectKeyword("invoke")
            let component = try wastParser.parser.takeId()
            let name = try wastParser.parser.expectString()
            let args = try wastParser.argumentValues()
            try wastParser.parser.expect(.rightParen)
            return ComponentWastInvoke(component: component?.value, name: name, args: args)
        }
    }

#endif
