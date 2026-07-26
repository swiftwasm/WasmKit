import WasmTypes

extension Parser {
    @usableFromInline
    package mutating func parseCodeEntry() throws(WasmParserError) -> Code {
        let features = self.features
        let size = try parseUnsigned() as UInt32
        let bodyStart = stream.currentIndex
        let localTypes = try parseVector { (s) throws(WasmParserError) -> (n: UInt32, type: ValueType) in
            let n: UInt32 = try s.parseUnsigned()
            let t = try s.parseValueType(features: features)
            return (n, t)
        }
        let totalLocals = localTypes.reduce(UInt64(0)) { $0 + UInt64($1.n) }
        guard totalLocals < limits.maxFunctionLocals else {
            throw makeError(.tooManyLocals(totalLocals, limit: limits.maxFunctionLocals))
        }
        let locals = localTypes.flatMap { (n: UInt32, type: ValueType) in
            return Array(repeating: type, count: Int(n))
        }
        let expressionStart = stream.currentIndex
        let expressionBytes = try stream.consume(
            count: Int(size) - (expressionStart - bodyStart)
        )
        return Code(
            locals: locals, expression: expressionBytes,
            offset: expressionStart, features: features
        )
    }

    @usableFromInline
    package mutating func parseDataSegmentEntry() throws(WasmParserError) -> DataSegment {
        let rawKind: UInt32 = try parseUnsigned()
        guard let kind = DataSegment.Kind(rawValue: rawKind) else {
            throw makeError(.malformedDataSegmentKind(rawKind))
        }
        switch kind {
        case .activeDefaultMemory:
            let offset = try parseConstExpression()
            let initializer = try stream.parseVectorBytes()
            return .active(.init(index: 0, offset: offset, initializer: initializer))

        case .passive:
            return try .passive(stream.parseVectorBytes())

        case .activeExplicitMemory:
            let index: UInt32 = try parseUnsigned()
            let offset = try parseConstExpression()
            let initializer = try stream.parseVectorBytes()
            return .active(.init(index: index, offset: offset, initializer: initializer))
        }
    }

    @usableFromInline
    package mutating func parseElementEntry() throws(WasmParserError) -> ElementSegment {
        let flag = try ElementSegment.Flag(rawValue: parseUnsigned())

        let type: ReferenceType
        let initializer: [ConstExpression]
        let mode: ElementSegment.Mode

        if flag.contains(.isPassiveOrDeclarative) {
            if flag.contains(.isDeclarative) {
                mode = .declarative
            } else {
                mode = .passive
            }
        } else {
            let table: TableIndex

            if flag.contains(.hasTableIndex) {
                table = try parseUnsigned()
            } else {
                table = 0
            }

            let offset = try parseConstExpression()
            mode = .active(table: table, offset: offset)
        }

        if flag.segmentHasRefType {
            let valueType = try stream.parseValueType(features: features)

            guard case .ref(let refType) = valueType else {
                throw makeError(.expectedRefType(actual: valueType))
            }

            type = refType
        } else {
            type = .funcRef
        }

        if flag.segmentHasElemKind {
            let elemKind = try parseUnsigned() as UInt32
            guard elemKind == 0x00 else {
                throw makeError(.unexpectedElementKind(expected: 0x00, actual: elemKind))
            }
        }

        // Both branches read a vector, but `parseConstExpression` is a `Parser`
        // method and cannot run against the `inout ByteStream` a vector-parsing
        // closure receives, so the count is read and looped over here.
        let initCount: UInt32 = try parseUnsigned()
        var expressions: [ConstExpression] = []
        if flag.contains(.usesExpressions) {
            for _ in 0..<initCount {
                expressions.append(try parseConstExpression())
            }
        } else {
            for _ in 0..<initCount {
                expressions.append(try [Instruction.refFunc(functionIndex: parseUnsigned() as UInt32)])
            }
        }
        initializer = expressions

        return ElementSegment(type: type, initializer: initializer, mode: mode)
    }

    /// Whether the parser's stream has reached its end. Wraps
    /// `stream.hasReachedEnd()` because `stream` itself is `@usableFromInline`
    /// internal.
    package func hasReachedEnd() throws(WasmParserError) -> Bool {
        try stream.hasReachedEnd()
    }
}
