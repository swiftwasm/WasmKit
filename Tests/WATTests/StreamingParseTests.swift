import Foundation
import Testing
import WAT
import WasmParser
import WasmTypes

@Suite
struct StreamingParseTests {
    /// Helper: produces `RawSection.body` for the matching section kind
    /// in the given Wasm binary.
    private static func sectionBytes(kind: RawSection.Kind, in binary: [UInt8]) throws -> ArraySlice<UInt8> {
        var parser = WasmParser.Parser(bytes: binary)
        while let section = try parser.parseNextRawSection() {
            if section.kind == kind { return section.body }
        }
        Issue.record("Section kind \(kind) not found")
        return []
    }

    @Test func codeEntryMatchesVector() throws {
        let wat = """
            (module (func (param i32) (result i32) local.get 0)
                    (func (param i64) (result i64) local.get 0))
            """
        let binary = try wat2wasm(wat)
        let sectionBytes = try Self.sectionBytes(kind: .code, in: binary)

        var p1 = WasmParser.Parser(sectionBodyBytes: sectionBytes)
        let viaVector = try p1.parseCodeSection()

        var p2 = WasmParser.Parser(sectionBodyBytes: sectionBytes)
        let count: UInt32 = try p2.parseUnsigned()
        var viaEntry: [Code] = []
        for _ in 0..<count { viaEntry.append(try p2.parseCodeEntry()) }

        #expect(viaVector == viaEntry)
        // `Code: Equatable` only compares (locals, expression), not offset.
        // Verify offset preservation explicitly: it's load-bearing for
        // ExpressionParser-driven instruction-offset reporting.
        for i in 0..<viaVector.count {
            #expect(viaVector[i].offset == viaEntry[i].offset)
        }
    }

    @Test func dataEntryMatchesVector() throws {
        let wat = """
            (module (memory 1)
                    (data (i32.const 0) "first")
                    (data "passive")
                    (data (memory 0) (i32.const 100) "third"))
            """
        let binary = try wat2wasm(wat)
        let bytes = try Self.sectionBytes(kind: .data, in: binary)

        var p1 = WasmParser.Parser(sectionBodyBytes: bytes)
        let viaVector = try p1.parseDataSection()

        var p2 = WasmParser.Parser(sectionBodyBytes: bytes)
        let count: UInt32 = try p2.parseUnsigned()
        var viaEntry: [DataSegment] = []
        for _ in 0..<count { viaEntry.append(try p2.parseDataSegmentEntry()) }

        #expect(viaVector == viaEntry)
    }

    @Test func elementEntryMatchesVector() throws {
        let wat = """
            (module
              (table 4 funcref)
              (func)
              (elem (i32.const 0) func 0)
              (elem funcref (item ref.func 0)))
            """
        let binary = try wat2wasm(wat)
        let bytes = try Self.sectionBytes(kind: .element, in: binary)

        var p1 = WasmParser.Parser(sectionBodyBytes: bytes)
        let viaVector = try p1.parseElementSection()

        var p2 = WasmParser.Parser(sectionBodyBytes: bytes)
        let count: UInt32 = try p2.parseUnsigned()
        var viaEntry: [ElementSegment] = []
        for _ in 0..<count { viaEntry.append(try p2.parseElementEntry()) }

        #expect(viaVector == viaEntry)
    }
}
