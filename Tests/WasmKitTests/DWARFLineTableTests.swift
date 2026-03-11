import Testing

@testable import WasmKit

private func encodeSLEB128(_ value: Int) -> [UInt8] {
    var bytes: [UInt8] = []
    var v = value
    var more = true
    while more {
        var byte = UInt8(v & 0x7F)
        v >>= 7
        if (v == 0 && byte & 0x40 == 0) || (v == -1 && byte & 0x40 != 0) {
            more = false
        } else {
            byte |= 0x80
        }
        bytes.append(byte)
    }
    return bytes
}

private func encodeULEB128(_ value: UInt) -> [UInt8] {
    var bytes: [UInt8] = []
    var v = value
    repeat {
        var byte = UInt8(v & 0x7F)
        v >>= 7
        if v != 0 { byte |= 0x80 }
        bytes.append(byte)
    } while v != 0
    return bytes
}

/// Compute a special opcode for a given address and line advance.
private func specialOpcode(
    addressAdvance: Int, lineAdvance: Int,
    opcodeBase: UInt8, lineRange: UInt8, lineBase: Int8
) -> UInt8? {
    let adjustedLineAdvance = lineAdvance - Int(lineBase)
    guard adjustedLineAdvance >= 0 && adjustedLineAdvance < Int(lineRange) else { return nil }
    let adjustedOpcode = addressAdvance * Int(lineRange) + adjustedLineAdvance
    let opcode = adjustedOpcode + Int(opcodeBase)
    guard opcode >= Int(opcodeBase) && opcode <= 255 else { return nil }
    return UInt8(opcode)
}

@Suite("DWARF Line Table Parser")
struct DWARFLineTableTests {

    // MARK: - Test helpers

    /// Builds a DWARF v4 .debug_line section from a builder closure that emits
    /// line number program opcodes into the provided byte array.
    private static func buildV4Section(
        lineBase: Int8 = -5,
        lineRange: UInt8 = 14,
        opcodeBase: UInt8 = 13,
        directories: [String] = ["/src"],
        files: [(name: String, dirIndex: UInt8)] = [("test.swift", 1)],
        program: (inout [UInt8], _ opcodeBase: UInt8, _ lineRange: UInt8, _ lineBase: Int8) -> Void
    ) -> [UInt8] {
        var bytes: [UInt8] = []

        let unitLengthOffset = bytes.count
        bytes.append(contentsOf: [0, 0, 0, 0]) // unit_length placeholder
        let afterUnitLength = bytes.count

        bytes.append(contentsOf: [4, 0]) // version: 4

        let prologueLengthOffset = bytes.count
        bytes.append(contentsOf: [0, 0, 0, 0]) // prologue_length placeholder
        let afterPrologueLength = bytes.count

        bytes.append(1) // minimum_instruction_length
        bytes.append(1) // maximum_operations_per_instruction
        bytes.append(1) // default_is_stmt
        bytes.append(UInt8(bitPattern: lineBase))
        bytes.append(lineRange)
        bytes.append(opcodeBase)

        // standard_opcode_lengths for opcodes 1..12
        bytes.append(contentsOf: [0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1])

        // Directories
        for dir in directories {
            bytes.append(contentsOf: Array(dir.utf8))
            bytes.append(0)
        }
        bytes.append(0) // end of directories

        // Files
        for file in files {
            bytes.append(contentsOf: Array(file.name.utf8))
            bytes.append(0)
            bytes.append(file.dirIndex) // dir_index
            bytes.append(0) // mod_time
            bytes.append(0) // length
        }
        bytes.append(0) // end of files

        // Patch prologue_length
        let prologueEnd = bytes.count
        let prologueLength = UInt32(prologueEnd - afterPrologueLength)
        bytes[prologueLengthOffset] = UInt8(prologueLength & 0xFF)
        bytes[prologueLengthOffset + 1] = UInt8((prologueLength >> 8) & 0xFF)
        bytes[prologueLengthOffset + 2] = UInt8((prologueLength >> 16) & 0xFF)
        bytes[prologueLengthOffset + 3] = UInt8((prologueLength >> 24) & 0xFF)

        // Emit the line number program
        program(&bytes, opcodeBase, lineRange, lineBase)

        // Patch unit_length
        let unitEnd = bytes.count
        let unitLength = UInt32(unitEnd - afterUnitLength)
        bytes[unitLengthOffset] = UInt8(unitLength & 0xFF)
        bytes[unitLengthOffset + 1] = UInt8((unitLength >> 8) & 0xFF)
        bytes[unitLengthOffset + 2] = UInt8((unitLength >> 16) & 0xFF)
        bytes[unitLengthOffset + 3] = UInt8((unitLength >> 24) & 0xFF)

        return bytes
    }

    /// Emit DW_LNE_set_address (extended opcode 2)
    private static func emitSetAddress(_ bytes: inout [UInt8], _ address: UInt32) {
        bytes.append(0) // extended opcode marker
        bytes.append(5) // length: 1 byte opcode + 4 byte address
        bytes.append(2) // DW_LNE_set_address
        bytes.append(UInt8(address & 0xFF))
        bytes.append(UInt8((address >> 8) & 0xFF))
        bytes.append(UInt8((address >> 16) & 0xFF))
        bytes.append(UInt8((address >> 24) & 0xFF))
    }

    /// Emit DW_LNE_end_sequence preceded by advancing the PC past the last instruction.
    /// In real DWARF, end_sequence marks the first address *not* in the sequence.
    private static func emitEndSequence(_ bytes: inout [UInt8], advancePC: UInt = 1) {
        // DW_LNS_advance_pc
        bytes.append(2)
        bytes.append(contentsOf: encodeULEB128(advancePC))
        // DW_LNE_end_sequence
        bytes.append(0)
        bytes.append(1)
        bytes.append(1)
    }

    // MARK: - Tests

    @Test func parsesBasicSequence() throws {
        let bytes = Self.buildV4Section { bytes, opcodeBase, lineRange, lineBase in
            // Set address to 0x100
            Self.emitSetAddress(&bytes, 0x100)

            // Advance line to 10 (from default 1, advance by 9)
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(9))

            // Copy -> emit row at 0x100, line 10
            bytes.append(1) // DW_LNS_copy

            // Special opcode: address +5, line +2
            bytes.append(specialOpcode(addressAdvance: 5, lineAdvance: 2, opcodeBase: opcodeBase, lineRange: lineRange, lineBase: lineBase)!)
            // -> 0x105, line 12

            // Special opcode: address +3, line +1
            bytes.append(specialOpcode(addressAdvance: 3, lineAdvance: 1, opcodeBase: opcodeBase, lineRange: lineRange, lineBase: lineBase)!)
            // -> 0x108, line 13

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))

        let loc1 = table.lookup(address: 0x100)
        #expect(loc1?.file == "/src/test.swift")
        #expect(loc1?.line == 10)

        let loc2 = table.lookup(address: 0x105)
        #expect(loc2?.line == 12)

        let loc3 = table.lookup(address: 0x108)
        #expect(loc3?.line == 13)
    }

    @Test func addressBetweenRowsResolvesToPreviousRow() throws {
        let bytes = Self.buildV4Section { bytes, opcodeBase, lineRange, lineBase in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(9))
            bytes.append(1) // DW_LNS_copy — row at 0x100, line 10

            bytes.append(specialOpcode(addressAdvance: 10, lineAdvance: 5, opcodeBase: opcodeBase, lineRange: lineRange, lineBase: lineBase)!)
            // -> 0x10A, line 15

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))

        // Address 0x103 is between 0x100 and 0x10A, should resolve to line 10
        let loc = table.lookup(address: 0x103)
        #expect(loc?.line == 10)
    }

    @Test func addressBeforeFirstEntryReturnsNil() throws {
        let bytes = Self.buildV4Section { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(9))
            bytes.append(1) // row at 0x100, line 10
            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        #expect(table.lookup(address: 0x50) == nil)
    }

    @Test func addressAfterEndSequenceReturnsNil() throws {
        let bytes = Self.buildV4Section { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(9))
            bytes.append(1) // row at 0x100, line 10
            Self.emitEndSequence(&bytes) // end_sequence at 0x100
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        // Well past the sequence
        #expect(table.lookup(address: 0x200) == nil)
    }

    @Test func columnTracking() throws {
        let bytes = Self.buildV4Section { bytes, opcodeBase, lineRange, lineBase in
            Self.emitSetAddress(&bytes, 0x200)
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(19)) // line 20
            bytes.append(5) // DW_LNS_set_column
            bytes.append(contentsOf: encodeULEB128(15)) // column 15
            bytes.append(1) // DW_LNS_copy — row at 0x200, line 20, column 15
            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        let loc = table.lookup(address: 0x200)
        #expect(loc?.line == 20)
        #expect(loc?.column == 15)
    }

    @Test func setFileSwitch() throws {
        let bytes = Self.buildV4Section(
            directories: ["/src"],
            files: [("alpha.swift", 1), ("beta.swift", 1)]
        ) { bytes, opcodeBase, lineRange, lineBase in
            Self.emitSetAddress(&bytes, 0x100)
            // File 1 (alpha.swift), line 5
            bytes.append(4) // DW_LNS_set_file
            bytes.append(contentsOf: encodeULEB128(1))
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(4))
            bytes.append(1) // copy -> 0x100, file 1, line 5

            // Switch to file 2 (beta.swift)
            bytes.append(2) // DW_LNS_advance_pc
            bytes.append(contentsOf: encodeULEB128(8))
            bytes.append(4) // DW_LNS_set_file
            bytes.append(contentsOf: encodeULEB128(2))
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(5)) // line 10
            bytes.append(1) // copy -> 0x108, file 2, line 10

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))

        let loc1 = table.lookup(address: 0x100)
        #expect(loc1?.file == "/src/alpha.swift")
        #expect(loc1?.line == 5)

        let loc2 = table.lookup(address: 0x108)
        #expect(loc2?.file == "/src/beta.swift")
        #expect(loc2?.line == 10)
    }

    @Test func constAddPc() throws {
        let bytes = Self.buildV4Section { bytes, opcodeBase, lineRange, lineBase in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(9))
            bytes.append(1) // row at 0x100, line 10

            // DW_LNS_const_add_pc: advance by (255 - opcode_base) / line_range
            // = (255 - 13) / 14 = 242 / 14 = 17
            bytes.append(8) // DW_LNS_const_add_pc

            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(5))
            bytes.append(1) // row at 0x111, line 15

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))

        let loc1 = table.lookup(address: 0x100)
        #expect(loc1?.line == 10)

        let loc2 = table.lookup(address: 0x111)
        #expect(loc2?.line == 15)
    }

    @Test func fixedAdvancePc() throws {
        let bytes = Self.buildV4Section { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(9))
            bytes.append(1) // row at 0x100, line 10

            // DW_LNS_fixed_advance_pc with 16-bit operand
            bytes.append(9) // DW_LNS_fixed_advance_pc
            bytes.append(0x00) // advance = 0x200 (little-endian)
            bytes.append(0x02)

            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(10))
            bytes.append(1) // row at 0x300, line 20

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        let loc = table.lookup(address: 0x300)
        #expect(loc?.line == 20)
    }

    @Test func multipleCompilationUnits() throws {
        // Build two separate units and concatenate them
        let unit1 = Self.buildV4Section(
            directories: ["/src"],
            files: [("a.swift", 1)]
        ) { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(4))
            bytes.append(1) // 0x100, line 5
            Self.emitEndSequence(&bytes)
        }

        let unit2 = Self.buildV4Section(
            directories: ["/lib"],
            files: [("b.swift", 1)]
        ) { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x500)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(29))
            bytes.append(1) // 0x500, line 30
            Self.emitEndSequence(&bytes)
        }

        var combined = unit1
        combined.append(contentsOf: unit2)

        let table = try DWARFLineTable(data: ArraySlice(combined))

        let loc1 = table.lookup(address: 0x100)
        #expect(loc1?.file == "/src/a.swift")
        #expect(loc1?.line == 5)

        let loc2 = table.lookup(address: 0x500)
        #expect(loc2?.file == "/lib/b.swift")
        #expect(loc2?.line == 30)
    }

    @Test func lineZeroSkipped() throws {
        // Line 0 means "no source mapping" — the lookup should skip it
        let bytes = Self.buildV4Section { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            // Line stays at default 1, then set to 0
            bytes.append(3) // DW_LNS_advance_line
            bytes.append(contentsOf: encodeSLEB128(-1)) // line = 0
            bytes.append(1) // copy row at 0x100, line 0

            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        // Line 0 should not be returned
        #expect(table.lookup(address: 0x100) == nil)
    }

    @Test func absolutePathIgnoresDirectory() throws {
        let bytes = Self.buildV4Section(
            directories: ["/should-be-ignored"],
            files: [("/absolute/path/file.swift", 1)]
        ) { bytes, _, _, _ in
            Self.emitSetAddress(&bytes, 0x100)
            bytes.append(3)
            bytes.append(contentsOf: encodeSLEB128(4))
            bytes.append(1) // 0x100, line 5
            Self.emitEndSequence(&bytes)
        }

        let table = try DWARFLineTable(data: ArraySlice(bytes))
        let loc = table.lookup(address: 0x100)
        #expect(loc?.file == "/absolute/path/file.swift")
    }

    @Test func unsupportedVersionThrows() throws {
        // Build bytes with version 3
        var bytes: [UInt8] = []
        bytes.append(contentsOf: [10, 0, 0, 0]) // unit_length = 10
        bytes.append(contentsOf: [3, 0]) // version: 3
        bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0]) // padding to fill

        #expect(throws: DWARFError.self) {
            try DWARFLineTable(data: ArraySlice(bytes))
        }
    }

    @Test func sourceLocationDescription() {
        let loc1 = DWARFLineTable.SourceLocation(file: "test.swift", line: 42, column: 10)
        #expect(loc1.description == "test.swift:42:10")

        let loc2 = DWARFLineTable.SourceLocation(file: "test.swift", line: 42, column: 0)
        #expect(loc2.description == "test.swift:42")
    }
}
