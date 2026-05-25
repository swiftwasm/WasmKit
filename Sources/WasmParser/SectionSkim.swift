/// A skim-mode result describing one section's kind and raw byte range,
/// without parsing the section body.
package struct RawSection: Sendable {
    /// Wasm spec section IDs lifted to a typed enum so consumers can
    /// switch exhaustively. The raw value matches the binary-format
    /// section ID byte. Cases are listed in spec order.
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
}

extension Parser where Stream == StaticByteStream {
    /// Sub-parser over a single section's body bytes. The new parser is
    /// positioned at the start of the section body; magic + version
    /// are NOT expected. Calling `parseNextRawSection` on a sub-parser
    /// is undefined behaviour.
    package init(sectionBodyBytes: ArraySlice<UInt8>, features: WasmFeatureSet = .default) {
        self.init(stream: StaticByteStream(bytes: Array(sectionBodyBytes)), features: features)
        self.nextParseTarget = .section
    }
}

extension Parser {
    /// Skim-parse the next section header: read its ID byte and size, slice
    /// off the body, and return both as a `RawSection` without parsing
    /// the body. Magic + version are consumed on the first call.
    /// Order tracking is enforced. Unknown section IDs and id 13 without
    /// `.exceptionHandling` in the feature set throw `malformedSectionID`,
    /// matching `parseNext`.
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
                    throw makeError(.sectionSizeMismatch(
                        sectionID: sectionIDByte,
                        expected: sectionStart + Int(sectionSize),
                        actual: stream.currentIndex
                    ))
                }
                throw error
            }
            guard let kind = RawSection.Kind(rawValue: sectionIDByte) else {
                throw makeError(.malformedSectionID(sectionIDByte))
            }
            if kind == .tag, !features.contains(.exceptionHandling) {
                throw makeError(.malformedSectionID(sectionIDByte))
            }
            let order: OrderTracking.Order?
            switch kind {
            case .custom:    order = nil
            case .type:      order = .type
            case .`import`:  order = ._import
            case .function:  order = .function
            case .table:     order = .table
            case .memory:    order = .memory
            case .global:    order = .global
            case .export:    order = .export
            case .start:     order = .start
            case .element:   order = .element
            case .code:      order = .code
            case .data:      order = .data
            case .dataCount: order = .dataCount
            case .tag:       order = .tag
            }
            if let order = order {
                try orderTracking.track(order: order, parser: self)
            }
            return RawSection(kind: kind, body: body)
        }
    }
}
