import Testing

@testable import WIT

@Suite
struct ParseVersionTests {

    func parse(_ text: String) throws -> Version? {
        var lexer = Lexer(cursor: .init(input: text))
        return try Version.parse(lexer: &lexer)
    }

    @Test func parse() throws {
        do {
            let version = try #require(try parse("1.0.0"))
            #expect(version.major == 1)
            #expect(version.minor == 0)
            #expect(version.patch == 0)
        }
        do {
            let version = try #require(try parse("12.222.4444"))
            #expect(version.major == 12)
            #expect(version.minor == 222)
            #expect(version.patch == 4444)
        }
    }

    @Test func parseInvalid() throws {
        #expect(throws: (any Error).self) {
            try parse("0.0.01")
        }
        #expect(throws: (any Error).self) {
            try parse("0.0.x")
        }
        #expect(throws: (any Error).self) {
            try parse("0.0.0-")
        }
        #expect(throws: (any Error).self) {
            try parse("0.0.0-+")
        }
    }

    @Test func parsePrerelease() throws {
        do {
            let version = try #require(try parse("1.0.0-alpha"))
            #expect(version.prerelease == "alpha")
        }
        do {
            let version = try #require(try parse("1.0.0-alpha.1"))
            #expect(version.prerelease == "alpha.1")
        }
        do {
            let version = try #require(try parse("1.0.0-0.3.7"))
            #expect(version.prerelease == "0.3.7")
        }
        do {
            let version = try #require(try parse("1.0.0-x-y-z.--"))
            #expect(version.prerelease == "x-y-z.--")
        }
    }

    @Test func parseBuildMetadata() throws {
        do {
            let version = try #require(try parse("1.0.0-alpha+001"))
            #expect(version.prerelease == "alpha")
            #expect(version.buildMetadata == "001")
        }
        do {
            let version = try #require(try parse("1.0.0+20130313144700"))
            #expect(version.prerelease == nil)
            #expect(version.buildMetadata == "20130313144700")
        }
        do {
            let version = try #require(try parse("1.0.0-beta+exp.sha.5114f85"))
            #expect(version.prerelease == "beta")
            #expect(version.buildMetadata == "exp.sha.5114f85")
        }
        do {
            let version = try #require(try parse("1.0.0+21AF26D3----117B344092BD"))
            #expect(version.prerelease == nil)
            #expect(version.buildMetadata == "21AF26D3----117B344092BD")
        }
    }
}
