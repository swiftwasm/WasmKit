import WasmTypes

extension Parser {
    /// Parses one function-body encoding from the code section: a
    /// size-in-bytes prefix, the locals-declaration vector, and the raw
    /// expression bytes (including the trailing `end`). The returned
    /// `Code.expression` is an `ArraySlice` of the parser's stream;
    /// `Code.offset` is the absolute parent-buffer index where the
    /// expression begins.
    @usableFromInline
    package func parseCodeEntry() throws(WasmParserError) -> Code {
        let size = try parseUnsigned() as UInt32
        let bodyStart = stream.currentIndex
        let localTypes = try parseVector { () throws(WasmParserError) -> (n: UInt32, type: ValueType) in
            let n: UInt32 = try parseUnsigned()
            let t = try parseValueType()
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

    /// Parses one data segment from the data section. Three encoding
    /// kinds (0/1/2) are supported: active-into-memory-0, passive,
    /// active-into-explicit-memory-index.
    @usableFromInline
    package mutating func parseDataSegmentEntry() throws(WasmParserError) -> DataSegment {
        let kind: UInt32 = try parseUnsigned()
        switch kind {
        case 0:
            let offset = try parseConstExpression()
            let initializer = try parseVectorBytes()
            return .active(.init(index: 0, offset: offset, initializer: initializer))

        case 1:
            return try .passive(parseVectorBytes())

        case 2:
            let index: UInt32 = try parseUnsigned()
            let offset = try parseConstExpression()
            let initializer = try parseVectorBytes()
            return .active(.init(index: index, offset: offset, initializer: initializer))
        default:
            throw makeError(.malformedDataSegmentKind(kind))
        }
    }

    /// Parses one element segment from the element section. The flag byte
    /// encoding determines mode (active/passive/declarative), reference
    /// type, and initializer shape.
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
            let valueType = try parseValueType()

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

        if flag.contains(.usesExpressions) {
            initializer = try parseVector { () throws(WasmParserError) in try parseConstExpression() }
        } else {
            initializer = try parseVector { () throws(WasmParserError) in
                try [Instruction.refFunc(functionIndex: parseUnsigned() as UInt32)]
            }
        }

        return ElementSegment(type: type, initializer: initializer, mode: mode)
    }

    /// Whether the parser's stream has reached its end. Wraps
    /// `stream.hasReachedEnd()` because `stream` itself is `@usableFromInline`
    /// internal.
    package func hasReachedEnd() throws(WasmParserError) -> Bool {
        try stream.hasReachedEnd()
    }
}
