/// One section's kind and raw body bytes, read without parsing the body.
package struct RawSection: Sendable {
    package enum Kind: UInt8, Sendable {
        case custom = 0
        case type = 1
        case `import` = 2
        case function = 3
        case table = 4
        case memory = 5
        case global = 6
        case export = 7
        case start = 8
        case element = 9
        case code = 10
        case data = 11
        case dataCount = 12
        case tag = 13
    }

    package let kind: Kind
    package let body: ArraySlice<UInt8>
    /// The module offset of the body's first byte.
    package let offset: Int

    /// Runs `parse` on a parser over the body, then throws unless it consumed the whole
    /// body. Errors report module offsets rather than offsets within the body.
    package func parse<Result>(
        features: WasmFeatureSet,
        _ parse: (inout Parser<StaticByteStreamSource>) throws(WasmParserError) -> Result
    ) throws(WasmParserError) -> Result {
        var parser = Parser(bytes: body, features: features)
        do throws(WasmParserError) {
            let result = try parse(&parser)
            guard try parser.stream.hasReachedEnd() else {
                throw parser.makeError(
                    .sectionSizeMismatch(
                        sectionID: kind.rawValue, expected: offset + body.count, actual: offset + parser.offset
                    ))
            }
            return result
        } catch {
            var error = error
            error.location = error.location.map { $0 + offset }
            throw error
        }
    }
}

extension Parser {
    /// The next section, with its body unparsed, or `nil` at the end of the module.
    /// Checks the header, section IDs and section order as `parseNext()` does.
    package mutating func parseNextRawSection() throws(WasmParserError) -> RawSection? {
        switch nextParseTarget {
        case .header:
            try parseMagicNumber()
            _ = try parseVersion()
            self.nextParseTarget = .section
            fallthrough
        case .section:
            guard try !stream.hasReachedEnd() else { return nil }
            let sectionIDByte = try stream.consumeAny()
            let sectionSize: UInt32 = try parseUnsigned()
            let sectionStart = stream.currentIndex
            let body: ArraySlice<UInt8>
            do {
                body = try stream.consume(count: Int(sectionSize))
            } catch {
                if case .parserUnexpectedEnd = error.kind {
                    throw makeError(
                        .sectionSizeMismatch(
                            sectionID: sectionIDByte,
                            expected: sectionStart + Int(sectionSize),
                            actual: stream.currentIndex
                        ))
                }
                throw error
            }
            let order = try sectionOrder(id: sectionIDByte)
            guard let kind = RawSection.Kind(rawValue: sectionIDByte) else {
                throw makeError(.malformedSectionID(sectionIDByte))
            }
            if let order {
                try orderTracking.track(order: order, parser: self)
            }
            return RawSection(kind: kind, body: body, offset: sectionStart)
        }
    }
}
