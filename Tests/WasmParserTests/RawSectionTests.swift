import Testing
import WasmParser

@Suite
struct RawSectionTests {
    /// `(module (type (func (param i32) (result i32))) (func (type 0) local.get 0) (memory 1)
    /// (data (i32.const 0) "hello"))`, assembled by WasmKit without a name section.
    static let typeFunctionMemoryCodeData: [UInt8] = [
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60, 0x01, 0x7f, 0x01, 0x7f,
        0x03, 0x02, 0x01, 0x00, 0x05, 0x03, 0x01, 0x00, 0x01, 0x0a, 0x06, 0x01, 0x04, 0x00, 0x20, 0x00,
        0x0b, 0x0b, 0x0b, 0x01, 0x00, 0x41, 0x00, 0x0b, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f,
    ]

    @Test func skimReturnsSectionsInOrderWithCorrectKinds() throws {
        var parser = WasmParser.Parser(bytes: Self.typeFunctionMemoryCodeData)
        var kinds: [RawSection.Kind] = []
        while let section = try parser.parseNextRawSection() {
            kinds.append(section.kind)
        }
        #expect(kinds == [.type, .function, .memory, .code, .data])
    }

    @Test func skimEmptyModule() throws {
        let bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]
        var parser = WasmParser.Parser(bytes: bytes)
        #expect(try parser.parseNextRawSection() == nil)
    }

    @Test func skimRejectsUnknownSectionID() throws {
        // magic + version + section id 99 (size 0)
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            99, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        do {
            _ = try parser.parseNextRawSection()
            Issue.record("Expected malformedSectionID throw")
        } catch let error {
            guard case .message(let m) = error.kind, m.text.contains("malformed section id: 99") else {
                Issue.record("Wrong error: \(error)")
                return
            }
        }
    }

    @Test func skimRejectsOutOfOrderSections() throws {
        // magic + version + memory(id 5, size 1, count 0) + type(id 1, size 1, count 0)
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x05, 0x01, 0x00,
            0x01, 0x01, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        _ = try parser.parseNextRawSection()  // memory: ok
        do {
            _ = try parser.parseNextRawSection()
            Issue.record("Expected sectionOrder throw")
        } catch let error {
            guard case .message(let m) = error.kind, m.text == "Sections in the module are out of order" else {
                Issue.record("Wrong error: \(error)")
                return
            }
        }
    }

    @Test func skimMultipleCustomSections() throws {
        // Two custom sections with a type section interleaved.
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x00, 0x07, 0x05, 0x65, 0x78, 0x74, 0x72, 0x61, 0x00,  // custom "extra"
            0x01, 0x01, 0x00,  // type, empty
            0x00, 0x05, 0x04, 0x6E, 0x61, 0x6D, 0x65,  // custom "name", empty
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        var kinds: [RawSection.Kind] = []
        while let section = try parser.parseNextRawSection() {
            kinds.append(section.kind)
        }
        #expect(kinds == [.custom, .type, .custom])
    }

    @Test func skimSectionWithDeclaredSizeZero() throws {
        // Type section with size 0. Skim returns successfully; deferred
        // sub-parser surfaces the malformed-content error.
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        let section = try parser.parseNextRawSection()
        #expect(section?.kind == .type)
        #expect(section?.body.count == 0)
        var sub = WasmParser.Parser(bytes: section!.body)
        #expect(throws: WasmParserError.self) { let _: UInt32 = try sub.parseUnsigned() }
    }

    /// `parseNext` reports a truncated section as a size mismatch too.
    @Test func skimTranslatesTruncatedSectionToSizeMismatch() throws {
        // magic + version + type section with declared size 100 but only 2 body bytes follow.
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x64, 0x00, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        do {
            _ = try parser.parseNextRawSection()
            Issue.record("Expected sectionSizeMismatch throw")
        } catch let error {
            guard case .message(let m) = error.kind,
                m.text.contains("Section size mismatch")
            else {
                Issue.record("Expected sectionSizeMismatch-shaped error, got: \(error)")
                return
            }
        }
    }

    /// `WasmFeatureSet.default` includes `.exceptionHandling`.
    @Test func skimAcceptsTagSectionID13() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            13, 0x01, 0x00,  // tag section, size 1, count 0
        ]
        var parser = WasmParser.Parser(bytes: bytes)
        let section = try parser.parseNextRawSection()
        #expect(section?.kind == .tag)
        #expect(Array(section!.body) == [0x00])
    }

    @Test func skimRejectsTagSectionWithoutFeature() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            13, 0x01, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes, features: [.referenceTypes])
        do {
            _ = try parser.parseNextRawSection()
            Issue.record("Expected malformedSectionID throw without EH feature")
        } catch let error {
            guard case .message(let m) = error.kind, m.text.contains("malformed section id: 13") else {
                Issue.record("Wrong error: \(error)")
                return
            }
        }
    }

    @Test func sectionsRecordTheModuleOffsetOfTheirBody() throws {
        var parser = WasmParser.Parser(bytes: Self.typeFunctionMemoryCodeData)
        var offsets: [Int] = []
        while let section = try parser.parseNextRawSection() {
            offsets.append(section.offset)
        }
        #expect(offsets == [10, 18, 22, 27, 35])
    }

    @Test func parseReportsErrorsAtModuleOffsets() throws {
        // A type section whose one entry has form 0x99 instead of 0x60.
        let bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x02, 0x01, 0x99]
        var parser = WasmParser.Parser(bytes: bytes)
        let section = try #require(try parser.parseNextRawSection())
        var bodyParser = WasmParser.Parser(bytes: section.body)
        let bodyError = try #require(throws: WasmParserError.self) {
            _ = try bodyParser.parseTypeSection()
        }
        let error = try #require(throws: WasmParserError.self) {
            _ = try section.parse(features: .default) { parser throws(WasmParserError) in
                try parser.parseTypeSection()
            }
        }
        let bodyLocation = try #require(bodyError.location)
        #expect(error.location == bodyLocation + 10)
    }

    @Test func parseRejectsBytesAfterTheParsedBody() throws {
        let bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x00, 0x00, 0xFF, 0xFF]
        var parser = WasmParser.Parser(bytes: bytes)
        let section = try #require(try parser.parseNextRawSection())
        let error = try #require(throws: WasmParserError.self) {
            _ = try section.parse(features: .default) { parser throws(WasmParserError) in
                try parser.parseTypeSection()
            }
        }
        guard case .message(let message) = error.kind else {
            Issue.record("Expected a .message error, got \(error.kind)")
            return
        }
        #expect(message.text == "Section size mismatch for section 1: expected 14 but got 11")
        #expect(error.location == 11)
    }

    @Test(arguments: [WasmFeatureSet.default, [.referenceTypes]])
    func skimRejectsTheSectionIDsParseNextRejects(features: WasmFeatureSet) {
        func isMalformedSectionID(_ error: WasmParserError, _ id: UInt8) -> Bool {
            guard case .message(let message) = error.kind else { return false }
            return message.text == "malformed section id: \(id)"
        }
        var rejectedBySkim: [UInt8] = []
        var rejectedByParseNext: [UInt8] = []
        for id in UInt8.min...UInt8.max {
            // One section with ID `id` and an empty body.
            let bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, id, 0x00]
            var skim = WasmParser.Parser(bytes: bytes, features: features)
            do throws(WasmParserError) {
                _ = try skim.parseNextRawSection()
            } catch {
                if isMalformedSectionID(error, id) { rejectedBySkim.append(id) }
            }
            var full = WasmParser.Parser(bytes: bytes, features: features)
            do throws(WasmParserError) {
                _ = try full.parseNext()
                _ = try full.parseNext()
            } catch {
                if isMalformedSectionID(error, id) { rejectedByParseNext.append(id) }
            }
        }
        #expect(rejectedBySkim == rejectedByParseNext)
        #expect(rejectedByParseNext.count == (features.contains(.exceptionHandling) ? 242 : 243))
    }
}
