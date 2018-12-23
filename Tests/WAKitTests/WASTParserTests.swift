import Parser
@testable import WAKit
import XCTest

final class WASMParserTests: XCTestCase {
    func testWASMParser() {
        let stream = StaticByteStream(bytes: [1, 2, 3])
        let parser = WASMParser(stream: stream)
        XCTAssertEqual(parser.stream, stream)
        XCTAssertEqual(parser.currentIndex, 0)
    }
}

extension WASMParserTests {
    func testWASMParser_parseUnsigned() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x03])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseUnsigned(bits: 8), 3)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x83, 0x00])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseUnsigned(bits: 16), 3)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x83])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseUnsigned(bits: 8)) { error in
            guard case Parser.Error<UInt8>.unexpectedEnd = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 1)
        }

        stream = StaticByteStream(bytes: [0x83, 0x10])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseUnsigned(bits: 8)) { error in
            guard case Parser.Error<UInt8>.unexpected(0x10, nil) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 1)
        }
    }

    func testWASMParser_parseSigned() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x7E])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseSigned(bits: 8), -2)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0xFE, 0x7F])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseSigned(bits: 8), -2)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0xFE, 0xFF, 0x7F])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseSigned(bits: 16), -2)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x83])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseSigned(bits: 8)) { error in
            guard case Parser.Error<UInt8>.unexpectedEnd = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 1)
        }

        stream = StaticByteStream(bytes: [0x83, 0x3E])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseSigned(bits: 8)) { error in
            guard case Parser.Error<UInt8>.unexpected(0x3E, nil) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 1)
        }

        stream = StaticByteStream(bytes: [0xFF, 0x7B])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseSigned(bits: 8)) { error in
            guard case Parser.Error<UInt8>.unexpected(0x7B, nil) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 1)
        }
    }
}

extension WASMParserTests {
    func testWASMParser_parseName() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79,
        ])

        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseName(), "Web🌏Assembly")
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x02, 0xDF, 0xFF])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseName()) { error in
            guard case let WASMParserError.invalidUnicode(unicode) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(unicode, [0xDF, 0xFF])
            XCTAssertEqual(stream.currentIndex, 3)
        }
    }
}

extension WASMParserTests {
    func testWASMParser_parseValueType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x7F])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == .i32)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7E])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == .i64)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7D])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == .f32)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7C])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == .f64)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7B])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseValueType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x7B, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x7C ... 0x7F))
            XCTAssertEqual(stream.currentIndex, 0)
        }
    }

    func testWASMParser_parseResultType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x40])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseResultType() == [])
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7E])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseResultType() == [.i64])
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7B])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseValueType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x7B, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x7C ... 0x7F))
            XCTAssertEqual(stream.currentIndex, 0)
        }
    }

    func testWASMParser_parseFunctionType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x60, 0x00, 0x00])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseFunctionType() == FunctionType(parameters: [], results: []))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x60, 0x01, 0x7E, 0x01, 0x7D])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseFunctionType() == FunctionType(parameters: [.i64], results: [.f32]))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseLimits() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x00, 0x01])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseLimits(), Limits(min: 1, max: nil))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x01, 0x02, 0x03])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseLimits(), Limits(min: 2, max: 3))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x02])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseLimits()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x02, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x00 ... 0x01))
            XCTAssertEqual(stream.currentIndex, 0)
        }
    }

    func testWASMParser_parseMemoryType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x00, 0x01])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseMemoryType(), Limits(min: 1, max: nil))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x01, 0x02, 0x03])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseMemoryType(), Limits(min: 2, max: 3))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x02])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseMemoryType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x02, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x00 ... 0x01))
            XCTAssertEqual(stream.currentIndex, 0)
        }
    }

    func testWASMParser_parseTableType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x70, 0x00, 0x01])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseTableType(), TableType(elementType: .any, limits: Limits(min: 1, max: nil)))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x70, 0x01, 0x02, 0x03])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseTableType(), TableType(elementType: .any, limits: Limits(min: 2, max: 3)))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x70, 0x02])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseTableType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x02, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x00 ... 0x01))
            XCTAssertEqual(stream.currentIndex, 1)
        }
    }

    func testWASMParser_parseGlobalType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x7F, 0x00])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseGlobalType(), GlobalType(mutability: .constant, valueType: .i32))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7F, 0x01])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseGlobalType(), GlobalType(mutability: .variable, valueType: .i32))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7B])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseGlobalType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x7B, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x7C ... 0x7F))
            XCTAssertEqual(stream.currentIndex, 0)
        }

        stream = StaticByteStream(bytes: [0x7F, 0x02])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(try parser.parseGlobalType()) { error in
            guard case let Parser.Error<UInt8>.unexpected(0x02, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(expected, Set(0x00 ... 0x01))
            XCTAssertEqual(stream.currentIndex, 1)
        }
    }
}

extension WASMParserTests {
    func testWASMParser_parseExpression() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x01, 0x0B])
        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseExpression(), Expression(instructions: [
            ControlInstruction.nop,
            PseudoInstruction.end,
        ]))
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }
}

extension WASMParserTests {
    func testWASMParser_parseCustomSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0, // section ID
            0x17, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF0, 0xEF, // dummy content
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.custom(name: "Web🌏Assembly", bytes: [0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF0, 0xEF])
        XCTAssertEqual(try parser.parseCustomSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [
            0, // section ID
            0x01, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF0, 0xEF, // dummy content
        ])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseCustomSection()) { error in
            guard case WASMParserError.invalidSectionSize(1) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 18)
        }

        stream = StaticByteStream(bytes: [
            0, // section ID
            0xFF, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF0, 0xEF, // dummy content
        ])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseCustomSection()) { error in
            guard case Parser.Error<UInt8>.unexpectedEnd = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 26)
        }
    }

    func testWASMParser_parseTypeSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x01, // section ID
            0x0B, // size
            0x02, // vector length
            0x60, 0x01, 0x7F, 0x01, 0x7E, // function type
            0x60, 0x01, 0x7D, 0x01, 0x7C, // function type
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.type([
            FunctionType(parameters: [.i32], results: [.i64]),
            FunctionType(parameters: [.f32], results: [.f64]),
        ])
        XCTAssertEqual(try parser.parseTypeSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseImportSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x02, // section ID
            0x0D, // size
            0x02, // vector length
            0x01, 0x61, // module name
            0x01, 0x62, // import name
            0x00, 0x12, // import descriptor (function)
            0x01, 0x63, // module name
            0x01, 0x64, // import name
            0x00, 0x34, // import descriptor (function)
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.import([
            Import(module: "a", name: "b", descripter: .function(18)),
            Import(module: "c", name: "d", descripter: .function(52)),
        ])
        XCTAssertEqual(try parser.parseImportSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseFunctionSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x03, // section ID
            0x03, // size
            0x02, // vector length
            0x01, 0x02, // function indices
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.function([0x01, 0x02])
        XCTAssertEqual(try parser.parseFunctionSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseTableSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x04, // section ID
            0x08, // size
            0x02, // vector length
            0x70, // element type
            0x00, 0x12, // limits
            0x70, // element type
            0x01, 0x34, 0x56, // limits
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.table([
            Table(type: TableType(elementType: .any, limits: Limits(min: 18, max: nil))),
            Table(type: TableType(elementType: .any, limits: Limits(min: 52, max: 86))),
        ])
        XCTAssertEqual(try parser.parseTableSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseMemorySection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x05, // section ID
            0x06, // size
            0x02, // vector length
            0x00, 0x12, // limits
            0x01, 0x34, 0x56, // limits
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.memory([
            Memory(type: MemoryType(min: 18, max: nil)),
            Memory(type: MemoryType(min: 52, max: 86)),
        ])
        XCTAssertEqual(try parser.parseMemorySection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseGlobalSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x06, // section ID
            0x07, // size
            0x02, // vector length
            0x7F, // value type
            0x00, // mutability.constant
            0x0B, // expression end
            0x7E, // value type
            0x01, // mutability.variable
            0x0B, // expression end
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.global([
            Global(
                type: GlobalType(mutability: .constant, valueType: .i32),
                initializer: Expression(instructions: [PseudoInstruction.end])
            ),
            Global(
                type: GlobalType(mutability: .variable, valueType: .i64),
                initializer: Expression(instructions: [PseudoInstruction.end])
            ),
        ])

        XCTAssertEqual(try parser.parseGlobalSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseExportSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x07, // section ID
            0x05, // size
            0x01, // vector length
            0x01, 0x61, // name
            0x00, 0x12, // export descriptor
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.export([
            Export(name: "a", descriptor: .function(18)),
        ])
        XCTAssertEqual(try parser.parseExportSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseStartSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x08, // section ID
            0x01, // size
            0x12, // function index
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.start(18)
        XCTAssertEqual(try parser.parseStartSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseElementSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x09, // section ID
            0x09, // size
            0x02, // vector length
            0x12, // table index
            0x0B, // expression end
            0x01, // vector length
            0x34, // function index
            0x56, // table index
            0x0B, // expression end
            0x01, // vector length
            0x78, // function index
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.element([
            Element(table: 18, offset: Expression(instructions: [PseudoInstruction.end]), initializer: [52]),
            Element(table: 86, offset: Expression(instructions: [PseudoInstruction.end]), initializer: [120]),
        ])
        XCTAssertEqual(try parser.parseElementSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseCodeSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x0A, // section ID
            0x0D, // content size
            0x02, // vector length (code)
            0x04, // code size
            0x01, // vector length (locals)
            0x03, // n
            0x7F, // Int32
            0x0B, // expression end
            0x06, // code size
            0x02, // vector length (locals)
            0x01, // n
            0x7E, // Int64
            0x02, // n
            0x7D, // Float32
            0x0B, // expression end
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.code([
            Code(
                locals: [.i32, .i32, .i32],
                expression: Expression(instructions: [PseudoInstruction.end])
            ),
            Code(
                locals: [.i64, .f32, .f32],
                expression: Expression(instructions: [PseudoInstruction.end])
            ),
        ])
        XCTAssertEqual(try parser.parseCodeSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseDataSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x0B, // section ID
            0x0D, // content size
            0x02, // vector length
            0x12, // memory index
            0x0B, // expression end
            0x04, // vector length (bytes)
            0x01, 0x02, 0x03, 0x04, // bytes
            0x34, // memory index
            0x0B, // expression end
            0x02, // vector length (bytes)
            0x05, 0x06, // bytes
        ])
        parser = WASMParser(stream: stream)
        let expected = Section.data([
            Data(
                data: 18,
                offset: Expression(instructions: [PseudoInstruction.end]),
                initializer: [0x01, 0x02, 0x03, 0x04]
            ),
            Data(
                data: 52,
                offset: Expression(instructions: [PseudoInstruction.end]),
                initializer: [0x05, 0x06]
            ),
        ])
        XCTAssertEqual(try parser.parseDataSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }
}

extension WASMParserTests {
    func testWASMParser_parseMagicNumbers() {
        let stream = StaticByteStream(bytes: [0x00, 0x61, 0x73, 0x6D])
        let parser = WASMParser(stream: stream)
        XCTAssertNoThrow(try parser.parseMagicNumbers())
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseVersion() {
        let stream = StaticByteStream(bytes: [0x01, 0x00, 0x00, 0x00])
        let parser = WASMParser(stream: stream)
        XCTAssertNoThrow(try parser.parseVersion())
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }

    func testWASMParser_parseModule() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0x00, 0x61, 0x73, 0x6D, // _asm
            0x01, 0x00, 0x00, 0x00, // version
        ])

        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseModule(), Module())
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [
            0x00, 0x61, 0x73, 0x6D, // _asm
            0x01, 0x00, 0x00, 0x00, // version
            0x00, // section ID
            0x18, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF0, 0xEF, // bytes
        ])

        parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseModule(), Module())
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
            0x01, 0x7F, 0x01, 0x7F, 0x03, 0x03, 0x02, 0x00, 0x00, 0x04, 0x04, 0x01,
            0x70, 0x00, 0x00, 0x05, 0x03, 0x01, 0x00, 0x02, 0x07, 0x1B, 0x03, 0x06,
            0x6D, 0x65, 0x6D, 0x6F, 0x72, 0x79, 0x02, 0x00, 0x03, 0x66, 0x69, 0x62,
            0x00, 0x00, 0x08, 0x66, 0x69, 0x62, 0x5F, 0x6D, 0x65, 0x6D, 0x6F, 0x00,
            0x01, 0x09, 0x01, 0x00, 0x0A, 0x9F, 0x02, 0x02, 0x5D, 0x01, 0x01, 0x7F,
            0x41, 0x00, 0x41, 0x00, 0x28, 0x02, 0x04, 0x41, 0x10, 0x6B, 0x22, 0x01,
            0x36, 0x02, 0x04, 0x20, 0x01, 0x20, 0x00, 0x36, 0x02, 0x08, 0x02, 0x40,
            0x02, 0x40, 0x20, 0x00, 0x41, 0x01, 0x4A, 0x0D, 0x00, 0x20, 0x01, 0x41,
            0x01, 0x36, 0x02, 0x0C, 0x0C, 0x01, 0x0B, 0x20, 0x01, 0x20, 0x01, 0x28,
            0x02, 0x08, 0x41, 0x7F, 0x6A, 0x10, 0x00, 0x20, 0x01, 0x28, 0x02, 0x08,
            0x41, 0x7E, 0x6A, 0x10, 0x00, 0x6A, 0x36, 0x02, 0x0C, 0x0B, 0x20, 0x01,
            0x28, 0x02, 0x0C, 0x21, 0x00, 0x41, 0x00, 0x20, 0x01, 0x41, 0x10, 0x6A,
            0x36, 0x02, 0x04, 0x20, 0x00, 0x0B, 0xBE, 0x01, 0x01, 0x03, 0x7F, 0x41,
            0x00, 0x28, 0x02, 0x04, 0x41, 0x20, 0x6B, 0x22, 0x02, 0x22, 0x03, 0x20,
            0x00, 0x36, 0x02, 0x18, 0x02, 0x40, 0x20, 0x00, 0x41, 0x01, 0x4A, 0x0D,
            0x00, 0x20, 0x03, 0x41, 0x01, 0x36, 0x02, 0x1C, 0x20, 0x03, 0x28, 0x02,
            0x1C, 0x0F, 0x0B, 0x20, 0x03, 0x28, 0x02, 0x18, 0x21, 0x00, 0x20, 0x03,
            0x20, 0x02, 0x36, 0x02, 0x10, 0x20, 0x02, 0x20, 0x00, 0x41, 0x02, 0x74,
            0x41, 0x0F, 0x6A, 0x41, 0x70, 0x71, 0x6B, 0x22, 0x01, 0x1A, 0x20, 0x01,
            0x42, 0x81, 0x80, 0x80, 0x80, 0x10, 0x37, 0x03, 0x00, 0x20, 0x03, 0x41,
            0x02, 0x36, 0x02, 0x0C, 0x02, 0x40, 0x03, 0x40, 0x20, 0x03, 0x28, 0x02,
            0x0C, 0x20, 0x03, 0x28, 0x02, 0x18, 0x4E, 0x0D, 0x01, 0x20, 0x01, 0x20,
            0x03, 0x28, 0x02, 0x0C, 0x22, 0x02, 0x41, 0x02, 0x74, 0x6A, 0x22, 0x00,
            0x20, 0x00, 0x41, 0x7C, 0x6A, 0x28, 0x02, 0x00, 0x20, 0x00, 0x41, 0x78,
            0x6A, 0x28, 0x02, 0x00, 0x6A, 0x36, 0x02, 0x00, 0x20, 0x03, 0x20, 0x02,
            0x41, 0x01, 0x6A, 0x36, 0x02, 0x0C, 0x0C, 0x00, 0x0B, 0x00, 0x0B, 0x20,
            0x03, 0x20, 0x01, 0x20, 0x03, 0x28, 0x02, 0x18, 0x41, 0x02, 0x74, 0x6A,
            0x28, 0x02, 0x00, 0x36, 0x02, 0x1C, 0x20, 0x03, 0x28, 0x02, 0x10, 0x1A,
            0x20, 0x03, 0x28, 0x02, 0x1C, 0x0B, 0x0B, 0x0A, 0x01, 0x00, 0x41, 0x04,
            0x0B, 0x04, 0x10, 0x00, 0x01, 0x00,
        ])
        parser = WASMParser(stream: stream)

        XCTAssertEqual(try parser.parseModule(), Module(
            types: [
                FunctionType(parameters: [.i32], results: [.i32]),
            ],
            functions: [
                Function(
                    type: 0,
                    locals: [.i32],
                    body: Expression(instructions: [
                        NumericInstruction.const(.i32(0)), NumericInstruction.const(.i32(0)),
                        MemoryInstruction.load(.i32, .init(min: 2, max: 4)), NumericInstruction.const(.i32(16)),
                        NumericInstruction.sub(.i32), VariableInstruction.teeLocal(1),
                        MemoryInstruction.store(.i32, .init(min: 2, max: 4)), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(0), MemoryInstruction.store(.i32, .init(min: 2, max: 8)),
                        ControlInstruction.block([], Expression(instructions: [
                            ControlInstruction.block([], Expression(instructions: [
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(1)),
                                NumericInstruction.gtS(.i32), ControlInstruction.brIf(0),
                                VariableInstruction.getLocal(1), NumericInstruction.const(.i32(1)),
                                MemoryInstruction.store(.i32, .init(min: 2, max: 12)), ControlInstruction.br(1),
                                PseudoInstruction.end,
                            ])),
                            VariableInstruction.getLocal(1), VariableInstruction.getLocal(1),
                            MemoryInstruction.load(.i32, .init(min: 2, max: 8)), NumericInstruction.const(.i32(-1)),
                            NumericInstruction.add(.i32), ControlInstruction.call(0),
                            VariableInstruction.getLocal(1), MemoryInstruction.load(.i32, .init(min: 2, max: 8)),
                            NumericInstruction.const(.i32(-2)), NumericInstruction.add(.i32),
                            ControlInstruction.call(0), NumericInstruction.add(.i32),
                            MemoryInstruction.store(.i32, .init(min: 2, max: 12)), PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(1), MemoryInstruction.load(.i32, .init(min: 2, max: 12)),
                        VariableInstruction.setLocal(0), NumericInstruction.const(.i32(0)),
                        VariableInstruction.getLocal(1), NumericInstruction.const(.i32(16)),
                        NumericInstruction.add(.i32), MemoryInstruction.store(.i32, .init(min: 2, max: 4)),
                        VariableInstruction.getLocal(0), PseudoInstruction.end,
                    ])
                ),
                Function(
                    type: 0,
                    locals: [.i32, .i32, .i32],
                    body: Expression(instructions: [
                        NumericInstruction.const(.i32(0)), MemoryInstruction.load(.i32, .init(min: 2, max: 4)),
                        NumericInstruction.const(.i32(32)), NumericInstruction.sub(.i32),
                        VariableInstruction.teeLocal(2), VariableInstruction.teeLocal(3),
                        VariableInstruction.getLocal(0), MemoryInstruction.store(.i32, .init(min: 2, max: 24)),
                        ControlInstruction.block([], Expression(instructions: [
                            VariableInstruction.getLocal(0), NumericInstruction.const(.i32(1)),
                            NumericInstruction.gtS(.i32), ControlInstruction.brIf(0),
                            VariableInstruction.getLocal(3), NumericInstruction.const(.i32(1)),
                            MemoryInstruction.store(.i32, .init(min: 2, max: 28)), VariableInstruction.getLocal(3),
                            MemoryInstruction.load(.i32, .init(min: 2, max: 28)), ControlInstruction.return,
                            PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, .init(min: 2, max: 24)),
                        VariableInstruction.setLocal(0), VariableInstruction.getLocal(3),
                        VariableInstruction.getLocal(2), MemoryInstruction.store(.i32, .init(min: 2, max: 16)),
                        VariableInstruction.getLocal(2), VariableInstruction.getLocal(0),
                        NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                        NumericInstruction.const(.i32(15)), NumericInstruction.add(.i32),
                        NumericInstruction.const(.i32(-16)), NumericInstruction.add(.i32),
                        NumericInstruction.sub(.i32), VariableInstruction.teeLocal(1),
                        ParametricInstruction.drop, VariableInstruction.getLocal(1),
                        NumericInstruction.const(.i64(4_294_967_297)), MemoryInstruction.store(.i64, .init(min: 3, max: 0)),
                        VariableInstruction.getLocal(3), NumericInstruction.const(.i32(2)),
                        MemoryInstruction.store(.i32, .init(min: 2, max: 12)),
                        ControlInstruction.block([], Expression(instructions: [
                            ControlInstruction.loop([], Expression(instructions: [
                                VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, .init(min: 2, max: 12)),
                                VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, .init(min: 2, max: 24)),
                                NumericInstruction.geS(.i32), ControlInstruction.brIf(1),
                                VariableInstruction.getLocal(1), VariableInstruction.getLocal(3),
                                MemoryInstruction.load(.i32, .init(min: 2, max: 12)), VariableInstruction.teeLocal(2),
                                NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                                NumericInstruction.add(.i32), VariableInstruction.teeLocal(0),
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(-4)),
                                NumericInstruction.add(.i32), MemoryInstruction.load(.i32, .init(min: 2, max: 0)),
                                VariableInstruction.getLocal(0), NumericInstruction.const(.i32(-8)),
                                NumericInstruction.add(.i32), MemoryInstruction.load(.i32, .init(min: 2, max: 0)),
                                NumericInstruction.add(.i32), MemoryInstruction.store(.i32, .init(min: 2, max: 0)),
                                VariableInstruction.getLocal(3), VariableInstruction.getLocal(2),
                                NumericInstruction.const(.i32(1)), NumericInstruction.add(.i32),
                                MemoryInstruction.store(.i32, .init(min: 2, max: 12)), ControlInstruction.br(0),
                                PseudoInstruction.end,
                            ])),
                            ControlInstruction.unreachable, PseudoInstruction.end,
                        ])),
                        VariableInstruction.getLocal(3), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, .init(min: 2, max: 24)),
                        NumericInstruction.const(.i32(2)), NumericInstruction.shl(.i32),
                        NumericInstruction.add(.i32), MemoryInstruction.load(.i32, .init(min: 2, max: 0)),
                        MemoryInstruction.store(.i32, .init(min: 2, max: 28)), VariableInstruction.getLocal(3),
                        MemoryInstruction.load(.i32, .init(min: 2, max: 16)), ParametricInstruction.drop,
                        VariableInstruction.getLocal(3), MemoryInstruction.load(.i32, .init(min: 2, max: 28)),
                        PseudoInstruction.end,
                    ])
                ),
            ],
            tables: [
                Table(type: TableType(elementType: FunctionType.any, limits: Limits(min: 0, max: nil))),
            ],
            memories: [
                Memory(type: Limits(min: 2, max: nil)),
            ],
            globals: [],
            elements: [],
            data: [
                Data(
                    data: 0,
                    offset: Expression(instructions: [NumericInstruction.const(.i32(4)), PseudoInstruction.end]),
                    initializer: [16, 0, 1, 0]
                ),
            ],
            start: nil,
            imports: [],
            exports: [
                Export(name: "memory", descriptor: ExportDescriptor.memory(0)),
                Export(name: "fib", descriptor: ExportDescriptor.function(0)),
                Export(name: "fib_memo", descriptor: ExportDescriptor.function(1)),
            ]
        ))

        XCTAssertEqual(stream.currentIndex, stream.bytes.endIndex)
    }
}
