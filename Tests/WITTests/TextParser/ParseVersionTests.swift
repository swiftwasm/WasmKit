import XCTest

@testable import WIT

class ParseVersionTests: XCTestCase {

    func parse(_ text: String) throws -> Version? {
        var lexer = Lexer(cursor: .init(input: text))
        return try Version.parse(lexer: &lexer)
    }

    func testParse() throws {
        do {
            let version = try XCTUnwrap(parse("1.0.0"))
            XCTAssertEqual(version.major, 1)
            XCTAssertEqual(version.minor, 0)
            XCTAssertEqual(version.patch, 0)
        }
        do {
            let version = try XCTUnwrap(parse("12.222.4444"))
            XCTAssertEqual(version.major, 12)
            XCTAssertEqual(version.minor, 222)
            XCTAssertEqual(version.patch, 4444)
        }
    }

    func testParseInvalid() throws {
        XCTAssertThrowsError(try parse("0.0.01"))
        XCTAssertThrowsError(try parse("0.0.x"))
        XCTAssertThrowsError(try parse("0.0.0-"))
        XCTAssertThrowsError(try parse("0.0.0-+"))
    }

    func testParsePrerelease() throws {
        do {
            let version = try XCTUnwrap(parse("1.0.0-alpha"))
            XCTAssertEqual(version.prerelease, "alpha")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0-alpha.1"))
            XCTAssertEqual(version.prerelease, "alpha.1")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0-0.3.7"))
            XCTAssertEqual(version.prerelease, "0.3.7")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0-x-y-z.--"))
            XCTAssertEqual(version.prerelease, "x-y-z.--")
        }
    }

    func testParseBuildMetadata() throws {
        do {
            let version = try XCTUnwrap(parse("1.0.0-alpha+001"))
            XCTAssertEqual(version.prerelease, "alpha")
            XCTAssertEqual(version.buildMetadata, "001")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0+20130313144700"))
            XCTAssertEqual(version.prerelease, nil)
            XCTAssertEqual(version.buildMetadata, "20130313144700")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0-beta+exp.sha.5114f85"))
            XCTAssertEqual(version.prerelease, "beta")
            XCTAssertEqual(version.buildMetadata, "exp.sha.5114f85")
        }
        do {
            let version = try XCTUnwrap(parse("1.0.0+21AF26D3----117B344092BD"))
            XCTAssertEqual(version.prerelease, nil)
            XCTAssertEqual(version.buildMetadata, "21AF26D3----117B344092BD")
        }
    }
}
