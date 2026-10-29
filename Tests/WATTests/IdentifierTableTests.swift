import Testing

@testable import WAT

@Suite
struct IdentifierTableTests {
    @Test func idCharNamesAreBareAndOthersQuoted() {
        #expect(IdentifierTable.id(for: "a.b$c") == "$a.b$c")
        #expect(IdentifierTable.id(for: "a b") == #"$"a b""#)
        #expect(IdentifierTable.id(for: "é") == #"$"é""#)
        #expect(IdentifierTable.id(for: "") == nil)
    }

    @Test func laterDuplicatesAndEmptyNamesGetNoId() {
        let table = IdentifierTable(names: [2: "x", 0: "x", 1: "", 3: "y"])
        #expect(table[0] == "$x")
        #expect(table[2] == nil)
        #expect(table.reference(2) == "2")
        #expect(table.reference(3) == "$y")
        #expect(table.definition(3) == " $y")
        #expect(table.definition(1) == "")
        #expect(table.nameAnnotation(0) == "")
        #expect(table.nameAnnotation(1) == #" (@name "")"#)
        #expect(table.nameAnnotation(2) == #" (@name "x")"#)
    }

    @Test func canonicallyEquivalentNamesAreDuplicates() {
        let table = IdentifierTable(names: [0: "\u{e9}", 1: "e\u{301}"])
        #expect(table[0] != nil)
        #expect(table[1] == nil)
    }
}
