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
    func testWASMParser_parseCustomSection() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [
            0, // Section ID
            0x17, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0x00, 0x61, 0x73, 0x6D, 0x00, 0x61, 0x73, 0x6D, // dummy content
        ])
        parser = WASMParser(stream: stream)
        let expected = CustomSection(name: "Web🌏Assembly", content: [0x00, 0x61, 0x73, 0x6D, 0x00, 0x61, 0x73, 0x6D])
        XCTAssertEqual(try parser.parseCustomSection(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [
            0, // Section ID
            0x01, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0x00, 0x61, 0x73, 0x6D, 0x00, 0x61, 0x73, 0x6D, // dummy content
        ])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseCustomSection()) { error in
            guard case WASMParserError.invalidSectionSize(1) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 18)
        }

        stream = StaticByteStream(bytes: [
            0, // Section ID
            0xFF, // size
            0x0F, 0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79, // name
            0x00, 0x61, 0x73, 0x6D, 0x00, 0x61, 0x73, 0x6D, // dummy content
        ])
        parser = WASMParser(stream: stream)
        XCTAssertThrowsError(_ = try parser.parseCustomSection()) { error in
            guard case Parser.Error<UInt8>.unexpectedEnd = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 26)
        }
    }
}

extension WASMParserTests {
    func testWASMParser_parseValueType() {
        var stream: StaticByteStream!
        var parser: WASMParser<StaticByteStream>!

        stream = StaticByteStream(bytes: [0x7F])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == Int32.self)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7E])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == Int64.self)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7D])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == Float32.self)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)

        stream = StaticByteStream(bytes: [0x7C])
        parser = WASMParser(stream: stream)
        XCTAssert(try parser.parseValueType() == Float64.self)
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
        let stream = StaticByteStream(bytes: [
            0x00, 0x61, 0x73, 0x6D, // _asm
            0x01, 0x00, 0x00, 0x00, // version
        ])
        let expected = Module()

        let parser = WASMParser(stream: stream)
        XCTAssertEqual(try parser.parseModule(), expected)
        XCTAssertEqual(parser.currentIndex, stream.bytes.count)
    }
}
