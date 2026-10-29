import WasmTypes

extension Parser {
    @inlinable
    package mutating func parseCodeEntry() throws(WasmParserError) -> Code {
        let features = self.features
        let size = try parseUnsigned() as UInt32
        let bodyStart = stream.currentIndex
        let localTypes = try stream.parseVector { (s) throws(WasmParserError) -> (n: UInt32, type: ValueType) in
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
        // On 32-bit platforms `Int` cannot hold every declared size.
        guard let bodySize = Int(exactly: size) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: expressionStart)
        }
        let expressionBytes = try stream.consume(
            count: bodySize - (expressionStart - bodyStart)
        )
        return Code(
            locals: locals, expression: expressionBytes,
            offset: expressionStart, bodyOffset: bodyStart, features: features
        )
    }

    @inlinable
    package mutating func parseDataSegmentEntry() throws(WasmParserError) -> DataSegment {
        let kind: UInt32 = try parseUnsigned()
        switch kind {
        case 0:
            let offset = try parseConstExpression()
            let initializer = try stream.parseVectorBytes()
            return .active(.init(index: 0, offset: offset, initializer: initializer))

        case 1:
            return try .passive(stream.parseVectorBytes())

        case 2:
            let index: UInt32 = try parseUnsigned()
            let offset = try parseConstExpression()
            let initializer = try stream.parseVectorBytes()
            return .active(.init(index: index, offset: offset, initializer: initializer))
        default:
            throw makeError(.malformedDataSegmentKind(kind))
        }
    }

    @inlinable
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
        } else if features.contains(.functionReferences) && !flag.contains(.usesExpressions) {
            // A segment listing function indices only holds non-null functions.
            type = ReferenceType(isNullable: false, heapType: .funcRef)
        } else {
            type = .funcRef
        }

        if flag.segmentHasElemKind {
            // `elemkind` parsing as defined in the spec
            let elemKind = try parseUnsigned() as UInt32
            guard elemKind == 0x00 else {
                throw makeError(.unexpectedElementKind(expected: 0x00, actual: elemKind))
            }
        }

        if flag.contains(.usesExpressions) {
            let initCount: UInt32 = try parseUnsigned()
            var expressions: [ConstExpression] = []
            for _ in 0..<initCount {
                expressions.append(try parseConstExpression())
            }
            initializer = expressions
        } else {
            let initCount: UInt32 = try parseUnsigned()
            var expressions: [ConstExpression] = []
            for _ in 0..<initCount {
                expressions.append(try [Instruction.refFunc(functionIndex: parseUnsigned() as UInt32)])
            }
            initializer = expressions
        }

        return ElementSegment(type: type, initializer: initializer, mode: mode)
    }
}
