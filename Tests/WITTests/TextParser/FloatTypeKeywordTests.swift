import Testing

@testable import WIT

/// wasm-tools reads `float32` and `float64` as undefined type names.
@Suite
struct FloatTypeKeywordTests {

    private func parseType(_ text: String) throws -> TypeReprSyntax {
        var lexer = Lexer(cursor: .init(input: text))
        return try TypeReprSyntax.parse(lexer: &lexer)
    }

    @Test func f32ParsesAsFloatPrimitive() throws {
        guard case .float32 = try parseType("f32") else {
            Issue.record("f32 should parse as the .float32 primitive")
            return
        }
    }

    @Test func f64ParsesAsFloatPrimitive() throws {
        guard case .float64 = try parseType("f64") else {
            Issue.record("f64 should parse as the .float64 primitive")
            return
        }
    }

    @Test func legacyFloat32ParsesAsNameReference() throws {
        guard case .name(let id) = try parseType("float32") else {
            Issue.record("float32 should parse as a name reference, not a primitive")
            return
        }
        #expect(id.text == "float32")
    }

    @Test func legacyFloat64ParsesAsNameReference() throws {
        guard case .name(let id) = try parseType("float64") else {
            Issue.record("float64 should parse as a name reference, not a primitive")
            return
        }
        #expect(id.text == "float64")
    }
}
