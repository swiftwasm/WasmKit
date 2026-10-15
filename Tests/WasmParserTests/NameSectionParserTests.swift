import Testing
import WasmParser

@Suite struct NameSectionParserTests {
    /// Function names (subsection 1) `[0: "f"]`, then tag names (subsection 11) `[0: "e"]`.
    static let functionAndTagNames: [UInt8] = [
        0x01, 0x04, 0x01, 0x00, 0x01, 0x66,
        0x0b, 0x04, 0x01, 0x00, 0x01, 0x65,
    ]

    @Test func tagNamesComeBackBesideTheOtherSubsections() throws {
        var parser = NameSectionParser(stream: StaticByteStreamSource(bytes: Self.functionAndTagNames))
        let parsed = try parser.parseAllIncludingTagNames()
        #expect(parsed.tagNames == [0: "e"])
        #expect(parsed.names.count == 1)
        guard case .functions(let functionNames) = try #require(parsed.names.first) else {
            Issue.record("Expected function names, got \(parsed.names)")
            return
        }
        #expect(functionNames == [0: "f"])
    }

    @Test func parseAllStillSkipsTagNames() throws {
        var parser = NameSectionParser(stream: StaticByteStreamSource(bytes: Self.functionAndTagNames))
        #expect(try parser.parseAll().count == 1)
    }
}
