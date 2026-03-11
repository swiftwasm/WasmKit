/// A minimal DWARF debug info parser for resolving code addresses to source locations.
///
/// When `.debug_info`, `.debug_abbrev`, and `.debug_ranges` sections are available,
/// uses CU address ranges to determine which compilation unit owns each address,
/// ensuring correct file attribution even when multiple CUs cover overlapping ranges.
///
/// Reference: DWARF v4 spec §6.2, §7.5
public final class DWARFLineTable {

    /// A source location resolved from the line table.
    public struct SourceLocation: Sendable, CustomStringConvertible {
        public let file: String
        public let line: UInt
        public let column: UInt

        public var description: String {
            if column > 0 {
                return "\(file):\(line):\(column)"
            }
            return "\(file):\(line)"
        }
    }

    /// All DWARF sections needed for full resolution.
    public struct Sections {
        public let debugLine: ArraySlice<UInt8>
        public let debugInfo: ArraySlice<UInt8>?
        public let debugAbbrev: ArraySlice<UInt8>?
        public let debugRanges: ArraySlice<UInt8>?

        public init(
            debugLine: ArraySlice<UInt8>,
            debugInfo: ArraySlice<UInt8>? = nil,
            debugAbbrev: ArraySlice<UInt8>? = nil,
            debugRanges: ArraySlice<UInt8>? = nil
        ) {
            self.debugLine = debugLine
            self.debugInfo = debugInfo
            self.debugAbbrev = debugAbbrev
            self.debugRanges = debugRanges
        }
    }

    /// A per-CU line table with its own file table and sorted rows.
    private struct CULineTable {
        let files: [String]
        let rows: [Row]

        func lookup(address: UInt64) -> SourceLocation? {
            var lo = 0
            var hi = rows.count
            while lo < hi {
                let mid = lo + (hi - lo) / 2
                if rows[mid].address <= address {
                    lo = mid + 1
                } else {
                    hi = mid
                }
            }
            var index = lo - 1
            while index >= 0 {
                let row = rows[index]
                if row.isEndSequence {
                    if address >= row.address { return nil }
                    index -= 1
                    continue
                }
                if row.line == 0 {
                    index -= 1
                    continue
                }
                let fileIndex = Int(row.fileIndex)
                guard fileIndex >= 0 && fileIndex < files.count else { return nil }
                let file = files[fileIndex]
                if file.isEmpty { return nil }
                return SourceLocation(file: file, line: row.line, column: row.column)
            }
            return nil
        }
    }

    /// A single row emitted by the line number program state machine.
    private struct Row: Comparable {
        let address: UInt64
        let fileIndex: UInt
        let line: UInt
        let column: UInt
        let isEndSequence: Bool

        static func < (lhs: Row, rhs: Row) -> Bool {
            lhs.address < rhs.address
        }
    }

    /// CU address range → line table index mapping.
    /// Sorted by range start for binary search.
    private struct CURangeEntry: Comparable {
        let start: UInt64
        let end: UInt64
        let lineTableIndex: Int

        static func < (lhs: CURangeEntry, rhs: CURangeEntry) -> Bool {
            lhs.start < rhs.start
        }
    }

    /// Per-CU line tables, keyed by their offset in .debug_line.
    private var lineTablesByOffset: [Int: CULineTable] = [:]
    /// CU range entries for address → CU resolution. Sorted by start address.
    private var cuRanges: [CURangeEntry] = []
    /// Flat line tables indexed for cuRanges lookup.
    private var lineTables: [CULineTable] = []
    /// Fallback flat table when .debug_info is not available.
    private var fallbackTable: CULineTable?

    /// Initialize with all available DWARF sections for accurate CU-aware resolution.
    public init(sections: Sections) throws {
        let debugLine = sections.debugLine

        // Parse all line tables from .debug_line, keyed by their offset
        var cursor = Cursor(data: debugLine)
        while cursor.hasMore {
            let tableOffset = cursor.offset - debugLine.startIndex
            let (files, rows) = try Self.parseOneLineTable(&cursor)
            lineTablesByOffset[tableOffset] = CULineTable(files: files, rows: rows.sorted())
        }

        // If .debug_info is available, build CU → address range mappings
        if let debugInfo = sections.debugInfo,
           let debugAbbrev = sections.debugAbbrev
        {
            let cuEntries = try Self.parseCUEntries(
                debugInfo: debugInfo,
                debugAbbrev: debugAbbrev,
                debugRanges: sections.debugRanges
            )

            for entry in cuEntries {
                guard let lt = lineTablesByOffset[entry.stmtList] else { continue }
                let ltIndex = lineTables.count
                lineTables.append(lt)
                for range in entry.ranges {
                    cuRanges.append(CURangeEntry(start: range.start, end: range.end, lineTableIndex: ltIndex))
                }
            }
            cuRanges.sort()
        } else {
            // No .debug_info — merge all line tables into a flat fallback
            var allFiles: [String] = []
            var allRows: [Row] = []
            for (_, lt) in lineTablesByOffset.sorted(by: { $0.key < $1.key }) {
                let fileBase = allFiles.count
                allFiles.append(contentsOf: lt.files)
                for row in lt.rows {
                    allRows.append(Row(
                        address: row.address,
                        fileIndex: UInt(fileBase) + row.fileIndex,
                        line: row.line,
                        column: row.column,
                        isEndSequence: row.isEndSequence
                    ))
                }
            }
            fallbackTable = CULineTable(files: allFiles, rows: allRows.sorted())
        }
    }

    /// Convenience initializer for .debug_line only (no CU-aware resolution).
    public convenience init(data: ArraySlice<UInt8>) throws {
        try self.init(sections: Sections(debugLine: data))
    }

    /// Offset to subtract from file-level byte offsets to get DWARF code addresses.
    /// DWARF addresses in WASM are relative to the Code section content start,
    /// while Code.offset values are file-level byte offsets.
    public var codeSectionOffset: Int = 0

    /// Look up the source location for a given file-level code offset.
    /// Automatically adjusts for the code section base offset.
    public func lookup(fileOffset: Int) -> SourceLocation? {
        let dwarfAddress = fileOffset - codeSectionOffset
        guard dwarfAddress >= 0 else { return nil }
        return lookup(address: UInt64(dwarfAddress))
    }

    /// Look up the source location for a given code address.
    public func lookup(address: UInt64) -> SourceLocation? {
        // If we have CU ranges, find the owning CU
        if !cuRanges.isEmpty {
            // Binary search for the last range with start <= address
            var lo = 0
            var hi = cuRanges.count
            while lo < hi {
                let mid = lo + (hi - lo) / 2
                if cuRanges[mid].start <= address {
                    lo = mid + 1
                } else {
                    hi = mid
                }
            }
            // Check ranges in reverse order (prefer later/more-specific CUs)
            var index = lo - 1
            while index >= 0 && cuRanges[index].start <= address {
                let range = cuRanges[index]
                if address < range.end {
                    if let loc = lineTables[range.lineTableIndex].lookup(address: address) {
                        return loc
                    }
                }
                index -= 1
            }
            return nil
        }

        // Fallback: flat table
        return fallbackTable?.lookup(address: address)
    }

    // MARK: - Parse one line table from .debug_line

    private static func parseOneLineTable(_ cursor: inout Cursor) throws -> (files: [String], rows: [Row]) {
        let unitLength = try cursor.readU32()
        let unitEnd = cursor.offset + Int(unitLength)
        guard unitEnd <= cursor.data.endIndex else {
            throw DWARFError.unexpectedEnd
        }

        let version = try cursor.readU16()
        guard version == 4 || version == 5 else {
            throw DWARFError.unsupportedVersion(version)
        }

        if version == 5 {
            _ = try cursor.readU8() // address_size
            _ = try cursor.readU8() // segment_selector_size
        }

        let prologueLength = try cursor.readU32()
        let prologueEnd = cursor.offset + Int(prologueLength)

        let minInstructionLength = try cursor.readU8()
        if version >= 4 {
            _ = try cursor.readU8() // max_operations_per_instruction
        }
        let defaultIsStmt = try cursor.readU8() != 0
        let lineBase = Int8(bitPattern: try cursor.readU8())
        let lineRange = try cursor.readU8()
        let opcodeBase = try cursor.readU8()

        var standardOpcodeLengths: [UInt8] = []
        for _ in 1..<opcodeBase {
            standardOpcodeLengths.append(try cursor.readU8())
        }

        var files: [String]
        if version < 5 {
            var directories: [String] = [""]
            while true {
                let dir = try cursor.readNullTerminatedString()
                if dir.isEmpty { break }
                directories.append(dir)
            }
            files = [""]
            while true {
                let name = try cursor.readNullTerminatedString()
                if name.isEmpty { break }
                let dirIndex = try cursor.readULEB128()
                _ = try cursor.readULEB128() // mod_time
                _ = try cursor.readULEB128() // length
                let dir = dirIndex < directories.count ? directories[Int(dirIndex)] : ""
                if dir.isEmpty || name.hasPrefix("/") {
                    files.append(name)
                } else {
                    files.append(dir + "/" + name)
                }
            }
        } else {
            let (_, v5files) = try parseV5FileTable(&cursor)
            files = v5files
        }

        cursor.seek(to: prologueEnd)

        // Execute line number program
        var rows: [Row] = []
        var address: UInt64 = 0
        var file: UInt = 1
        var line: UInt = 1
        var column: UInt = 0
        var isStmt = defaultIsStmt

        while cursor.offset < unitEnd {
            let opcode = try cursor.readU8()

            if opcode == 0 {
                let length = try cursor.readULEB128()
                let extEnd = cursor.offset + Int(length)
                let extOpcode = try cursor.readU8()
                switch extOpcode {
                case 1: // DW_LNE_end_sequence
                    rows.append(Row(address: address, fileIndex: file, line: line, column: column, isEndSequence: true))
                    address = 0; file = 1; line = 1; column = 0; isStmt = defaultIsStmt
                case 2: // DW_LNE_set_address
                    if extEnd - cursor.offset >= 8 {
                        address = try cursor.readU64()
                    } else {
                        address = UInt64(try cursor.readU32())
                    }
                case 4: _ = try cursor.readULEB128() // DW_LNE_set_discriminator
                default: break
                }
                cursor.seek(to: extEnd)
            } else if opcode < opcodeBase {
                switch opcode {
                case 1: rows.append(Row(address: address, fileIndex: file, line: line, column: column, isEndSequence: false))
                case 2: address += UInt64(try cursor.readULEB128()) * UInt64(minInstructionLength)
                case 3: line = UInt(Int(line) + Int(try cursor.readSLEB128()))
                case 4: file = UInt(try cursor.readULEB128())
                case 5: column = UInt(try cursor.readULEB128())
                case 6: isStmt = !isStmt
                case 7: break
                case 8:
                    let adj = Int(255) - Int(opcodeBase)
                    address += UInt64(adj / Int(lineRange)) * UInt64(minInstructionLength)
                case 9: address += UInt64(try cursor.readU16())
                case 10, 11: break
                case 12: _ = try cursor.readULEB128()
                default:
                    let argCount = Int(opcode) - 1 < standardOpcodeLengths.count ? standardOpcodeLengths[Int(opcode) - 1] : 0
                    for _ in 0..<argCount { _ = try cursor.readULEB128() }
                }
            } else {
                let adjusted = Int(opcode) - Int(opcodeBase)
                address += UInt64(adjusted / Int(lineRange)) * UInt64(minInstructionLength)
                line = UInt(Int(line) + Int(lineBase) + (adjusted % Int(lineRange)))
                rows.append(Row(address: address, fileIndex: file, line: line, column: column, isEndSequence: false))
            }
        }

        cursor.seek(to: unitEnd)
        return (files, rows)
    }

    // MARK: - Parse .debug_info CU entries

    private struct CUEntry {
        let stmtList: Int
        let ranges: [(start: UInt64, end: UInt64)]
    }

    private static func parseCUEntries(
        debugInfo: ArraySlice<UInt8>,
        debugAbbrev: ArraySlice<UInt8>,
        debugRanges: ArraySlice<UInt8>?
    ) throws -> [CUEntry] {
        var cursor = Cursor(data: debugInfo)
        var results: [CUEntry] = []

        while cursor.hasMore {
            let unitLength = try cursor.readU32()
            let unitEnd = cursor.offset + Int(unitLength)
            guard unitEnd <= debugInfo.endIndex else { break }

            let version = try cursor.readU16()
            guard version == 4 || version == 5 else {
                cursor.seek(to: unitEnd)
                continue
            }

            let abbrevOffset: Int
            let addressSize: UInt8

            if version == 5 {
                _ = try cursor.readU8() // unit_type
                addressSize = try cursor.readU8()
                abbrevOffset = Int(try cursor.readU32())
            } else {
                abbrevOffset = Int(try cursor.readU32())
                addressSize = try cursor.readU8()
            }

            // Parse the abbreviation table for this CU
            let abbrevTable = try parseAbbrevTable(debugAbbrev: debugAbbrev, offset: abbrevOffset)

            // Read the first DIE (should be DW_TAG_compile_unit)
            let abbrevCode = try cursor.readULEB128()
            guard abbrevCode != 0, let abbrev = abbrevTable[UInt(abbrevCode)] else {
                cursor.seek(to: unitEnd)
                continue
            }

            // Extract attributes we care about
            var stmtList: Int?
            var lowPC: UInt64?
            var highPC: UInt64?
            var highPCIsOffset = false
            var rangesOffset: Int?

            for (attr, form) in abbrev.attributes {
                let value = try readAttributeValue(&cursor, form: form, addressSize: addressSize)
                switch attr {
                case 0x10: // DW_AT_stmt_list
                    stmtList = value.asInt
                case 0x11: // DW_AT_low_pc
                    lowPC = value.asUInt64
                case 0x12: // DW_AT_high_pc
                    highPC = value.asUInt64
                    highPCIsOffset = form == 0x0b || form == 0x05 || form == 0x06 || form == 0x07 || form == 0x0f // data forms
                case 0x55: // DW_AT_ranges
                    rangesOffset = value.asInt
                default:
                    break
                }
            }

            guard let stmtList else {
                cursor.seek(to: unitEnd)
                continue
            }

            var ranges: [(start: UInt64, end: UInt64)] = []

            if let rangesOffset, let debugRanges {
                // Parse .debug_ranges
                ranges = parseRangeList(debugRanges: debugRanges, offset: rangesOffset, addressSize: addressSize, baseAddress: lowPC ?? 0)
            } else if let lowPC, let highPC {
                let actualHigh = highPCIsOffset ? lowPC + highPC : highPC
                if actualHigh > lowPC {
                    ranges = [(start: lowPC, end: actualHigh)]
                }
            }

            if !ranges.isEmpty {
                results.append(CUEntry(stmtList: stmtList, ranges: ranges))
            }

            cursor.seek(to: unitEnd)
        }

        return results
    }

    // MARK: - Abbreviation table parsing

    private struct Abbreviation {
        let tag: UInt
        let attributes: [(attr: UInt, form: UInt)]
    }

    private static func parseAbbrevTable(debugAbbrev: ArraySlice<UInt8>, offset: Int) throws -> [UInt: Abbreviation] {
        var cursor = Cursor(data: debugAbbrev)
        cursor.seek(to: debugAbbrev.startIndex + offset)

        var table: [UInt: Abbreviation] = [:]

        while cursor.hasMore {
            let code = try cursor.readULEB128()
            if code == 0 { break }

            let tag = try cursor.readULEB128()
            _ = try cursor.readU8() // children flag

            var attributes: [(attr: UInt, form: UInt)] = []
            while true {
                let attr = try cursor.readULEB128()
                let form = try cursor.readULEB128()
                if attr == 0 && form == 0 { break }
                attributes.append((attr: UInt(attr), form: UInt(form)))
            }

            table[UInt(code)] = Abbreviation(tag: UInt(tag), attributes: attributes)
        }

        return table
    }

    // MARK: - Attribute value reading

    private enum AttributeValue {
        case uint64(UInt64)
        case int(Int)
        case skipped

        var asUInt64: UInt64? {
            if case .uint64(let v) = self { return v }
            if case .int(let v) = self { return UInt64(v) }
            return nil
        }

        var asInt: Int? {
            if case .int(let v) = self { return v }
            if case .uint64(let v) = self { return Int(v) }
            return nil
        }
    }

    private static func readAttributeValue(_ cursor: inout Cursor, form: UInt, addressSize: UInt8) throws -> AttributeValue {
        switch form {
        case 0x01: // DW_FORM_addr
            if addressSize == 8 { return .uint64(try cursor.readU64()) }
            return .uint64(UInt64(try cursor.readU32()))
        case 0x03: // DW_FORM_block2
            let len = try cursor.readU16()
            cursor.seek(to: cursor.offset + Int(len))
            return .skipped
        case 0x04: // DW_FORM_block4
            let len = try cursor.readU32()
            cursor.seek(to: cursor.offset + Int(len))
            return .skipped
        case 0x05: // DW_FORM_data2
            return .int(Int(try cursor.readU16()))
        case 0x06: // DW_FORM_data4
            return .int(Int(try cursor.readU32()))
        case 0x07: // DW_FORM_data8
            return .uint64(try cursor.readU64())
        case 0x08: // DW_FORM_string
            _ = try cursor.readNullTerminatedString()
            return .skipped
        case 0x09: // DW_FORM_block
            let len = try cursor.readULEB128()
            cursor.seek(to: cursor.offset + Int(len))
            return .skipped
        case 0x0a: // DW_FORM_block1
            let len = try cursor.readU8()
            cursor.seek(to: cursor.offset + Int(len))
            return .skipped
        case 0x0b: // DW_FORM_data1
            return .int(Int(try cursor.readU8()))
        case 0x0c: // DW_FORM_flag
            return .int(Int(try cursor.readU8()))
        case 0x0d: // DW_FORM_sdata
            return .int(Int(try cursor.readSLEB128()))
        case 0x0e: // DW_FORM_strp
            return .int(Int(try cursor.readU32()))
        case 0x0f: // DW_FORM_udata
            return .uint64(try cursor.readULEB128())
        case 0x10: // DW_FORM_ref_addr
            if addressSize == 8 { _ = try cursor.readU64() } else { _ = try cursor.readU32() }
            return .skipped
        case 0x11: // DW_FORM_ref1
            return .int(Int(try cursor.readU8()))
        case 0x12: // DW_FORM_ref2
            return .int(Int(try cursor.readU16()))
        case 0x13: // DW_FORM_ref4
            return .int(Int(try cursor.readU32()))
        case 0x14: // DW_FORM_ref8
            return .uint64(try cursor.readU64())
        case 0x15: // DW_FORM_ref_udata
            return .uint64(try cursor.readULEB128())
        case 0x17: // DW_FORM_sec_offset
            return .int(Int(try cursor.readU32()))
        case 0x18: // DW_FORM_exprloc
            let len = try cursor.readULEB128()
            cursor.seek(to: cursor.offset + Int(len))
            return .skipped
        case 0x19: // DW_FORM_flag_present
            return .int(1)
        case 0x20: // DW_FORM_ref_sig8
            _ = try cursor.readU64()
            return .skipped
        default:
            throw DWARFError.unsupportedForm(form)
        }
    }

    // MARK: - Range list parsing

    private static func parseRangeList(
        debugRanges: ArraySlice<UInt8>,
        offset: Int,
        addressSize: UInt8,
        baseAddress: UInt64
    ) -> [(start: UInt64, end: UInt64)] {
        var cursor = Cursor(data: debugRanges)
        cursor.seek(to: debugRanges.startIndex + offset)

        var ranges: [(start: UInt64, end: UInt64)] = []
        var base = baseAddress
        let maxAddr: UInt64 = addressSize == 8 ? UInt64.max : UInt64(UInt32.max)

        while cursor.hasMore {
            guard let start = try? (addressSize == 8 ? cursor.readU64() : UInt64(cursor.readU32())),
                  let end = try? (addressSize == 8 ? cursor.readU64() : UInt64(cursor.readU32()))
            else { break }

            if start == 0 && end == 0 { break } // End of list
            if start == maxAddr { // Base address selection
                base = end
                continue
            }
            ranges.append((start: base + start, end: base + end))
        }

        return ranges
    }

    // MARK: - DWARF v5 file table parsing

    private static func parseV5FileTable(_ cursor: inout Cursor) throws -> (directories: [String], files: [String]) {
        let dirFormatCount = try cursor.readU8()
        var dirFormats: [(content: UInt, form: UInt)] = []
        for _ in 0..<dirFormatCount {
            dirFormats.append((content: UInt(try cursor.readULEB128()), form: UInt(try cursor.readULEB128())))
        }
        let dirCount = try cursor.readULEB128()
        var directories: [String] = []
        for _ in 0..<dirCount {
            var dirPath = ""
            for format in dirFormats {
                let value = try readLineFormValue(&cursor, form: format.form)
                if format.content == 1 { dirPath = value }
            }
            directories.append(dirPath)
        }

        let fileFormatCount = try cursor.readU8()
        var fileFormats: [(content: UInt, form: UInt)] = []
        for _ in 0..<fileFormatCount {
            fileFormats.append((content: UInt(try cursor.readULEB128()), form: UInt(try cursor.readULEB128())))
        }
        let fileCount = try cursor.readULEB128()
        var files: [String] = []
        for _ in 0..<fileCount {
            var fileName = ""
            var dirIndex: UInt = 0
            for format in fileFormats {
                let value = try readLineFormValue(&cursor, form: format.form)
                switch format.content {
                case 1: fileName = value
                case 2: dirIndex = UInt(value) ?? 0
                default: break
                }
            }
            let dir = dirIndex < directories.count ? directories[Int(dirIndex)] : ""
            if dir.isEmpty || fileName.hasPrefix("/") {
                files.append(fileName)
            } else {
                files.append(dir + "/" + fileName)
            }
        }
        return (directories, files)
    }

    private static func readLineFormValue(_ cursor: inout Cursor, form: UInt) throws -> String {
        switch form {
        case 0x08: return try cursor.readNullTerminatedString()
        case 0x0e, 0x1f: _ = try cursor.readU32(); return ""
        case 0x0b: return String(try cursor.readU8())
        case 0x05: return String(try cursor.readU16())
        case 0x06: return String(try cursor.readU32())
        case 0x0f: return String(try cursor.readULEB128())
        default: throw DWARFError.unsupportedForm(form)
        }
    }
}

// MARK: - Errors

enum DWARFError: Error, CustomStringConvertible {
    case unexpectedEnd
    case unsupportedVersion(UInt16)
    case unsupportedForm(UInt)

    var description: String {
        switch self {
        case .unexpectedEnd:
            return "Unexpected end of DWARF data"
        case .unsupportedVersion(let v):
            return "Unsupported DWARF line table version: \(v)"
        case .unsupportedForm(let f):
            return "Unsupported DWARF form: 0x\(String(f, radix: 16))"
        }
    }
}

// MARK: - Binary cursor for reading DWARF data

private struct Cursor {
    let data: ArraySlice<UInt8>
    var offset: Int

    init(data: ArraySlice<UInt8>) {
        self.data = data
        self.offset = data.startIndex
    }

    var hasMore: Bool { offset < data.endIndex }

    mutating func seek(to position: Int) {
        offset = position
    }

    mutating func readU8() throws -> UInt8 {
        guard offset < data.endIndex else { throw DWARFError.unexpectedEnd }
        let value = data[offset]
        offset += 1
        return value
    }

    mutating func readU16() throws -> UInt16 {
        guard offset + 2 <= data.endIndex else { throw DWARFError.unexpectedEnd }
        let value = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        offset += 2
        return value
    }

    mutating func readU32() throws -> UInt32 {
        guard offset + 4 <= data.endIndex else { throw DWARFError.unexpectedEnd }
        let value = UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
        offset += 4
        return value
    }

    mutating func readU64() throws -> UInt64 {
        guard offset + 8 <= data.endIndex else { throw DWARFError.unexpectedEnd }
        let value = UInt64(data[offset])
            | (UInt64(data[offset + 1]) << 8)
            | (UInt64(data[offset + 2]) << 16)
            | (UInt64(data[offset + 3]) << 24)
            | (UInt64(data[offset + 4]) << 32)
            | (UInt64(data[offset + 5]) << 40)
            | (UInt64(data[offset + 6]) << 48)
            | (UInt64(data[offset + 7]) << 56)
        offset += 8
        return value
    }

    mutating func readULEB128() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            guard offset < data.endIndex else { throw DWARFError.unexpectedEnd }
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { break }
            shift += 7
        }
        return result
    }

    mutating func readSLEB128() throws -> Int64 {
        var result: Int64 = 0
        var shift: UInt64 = 0
        var byte: UInt8 = 0
        repeat {
            guard offset < data.endIndex else { throw DWARFError.unexpectedEnd }
            byte = data[offset]
            offset += 1
            result |= Int64(byte & 0x7F) << shift
            shift += 7
        } while byte & 0x80 != 0
        if shift < 64 && (byte & 0x40) != 0 {
            result |= -(1 << shift)
        }
        return result
    }

    mutating func readNullTerminatedString() throws -> String {
        let start = offset
        while offset < data.endIndex && data[offset] != 0 {
            offset += 1
        }
        guard offset < data.endIndex else { throw DWARFError.unexpectedEnd }
        let bytes = data[start..<offset]
        offset += 1
        return String(decoding: bytes, as: UTF8.self)
    }
}
