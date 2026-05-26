import Foundation
import Testing
import WAT
import WasmParser
import WasmTypes

@Suite
struct SectionSkimTests {
    @Test func skimReturnsSectionsInOrderWithCorrectKinds() throws {
        let wat = """
            (module
              (type (func (param i32) (result i32)))
              (func (type 0) local.get 0)
              (memory 1)
              (data (i32.const 0) "hello"))
            """
        let binary = try wat2wasm(wat)
        var parser = WasmParser.Parser(bytes: binary)
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
        } catch let error as WasmParserError {
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
        } catch let error as WasmParserError {
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
        var sub = WasmParser.Parser(sectionBodyBytes: section!.body)
        #expect(throws: WasmParserError.self) { let _: UInt32 = try sub.parseUnsigned() }
    }

    /// When the declared section size exceeds the remaining file bytes,
    /// skim translates `parserUnexpectedEnd` from `consume(count:)` into a
    /// `sectionSizeMismatch`-shaped error so downstream pattern-matchers
    /// see the same contract `parseNext` throws.
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
        } catch let error as WasmParserError {
            guard case .message(let m) = error.kind,
                m.text.contains("Section size mismatch")
            else {
                Issue.record("Expected sectionSizeMismatch-shaped error, got: \(error)")
                return
            }
        }
    }

    /// Tag section (id 13) is accepted when `.exceptionHandling` is in the
    /// feature set. `WasmFeatureSet.default` includes `.exceptionHandling`.
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

    /// Counterpart: id 13 is rejected as malformed when `.exceptionHandling`
    /// is NOT in the feature set, matching `parseNext`'s gating.
    @Test func skimRejectsTagSectionWithoutFeature() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            13, 0x01, 0x00,
        ]
        var parser = WasmParser.Parser(bytes: bytes, features: [.referenceTypes])
        do {
            _ = try parser.parseNextRawSection()
            Issue.record("Expected malformedSectionID throw without EH feature")
        } catch let error as WasmParserError {
            guard case .message(let m) = error.kind, m.text.contains("malformed section id: 13") else {
                Issue.record("Wrong error: \(error)")
                return
            }
        }
    }
}
