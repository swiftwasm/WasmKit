import Testing
import WAT
import WasmParser

@Suite
struct Wasm2watErrorTests {
    private static func messageText(_ error: WasmParserError) -> String? {
        guard case .message(let message) = error.kind else { return nil }
        return message.text
    }

    @Test func unprintableInstructionsThrowAtTheirOffset() throws {
        let binary = try wat2wasm("(module (func (result i32) i32.const 1 ref.i31 i31.get_s))", features: .all)
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary), features: .all)
        }
        #expect(Self.messageText(error) == "instruction not supported by wasm2wat")
        let location = try #require(error.location)
        #expect(Array(binary[location...].prefix(2)) == [0xFB, 0x1C])
    }

    @Test func undecodableInstructionsThrowAtTheirOffset() throws {
        let binary = try wat2wasm("(module (func (result i32) i32.const 1 ref.i31 i31.get_s))", features: .all)
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "Illegal opcode: [251]")
        let location = try #require(error.location)
        #expect(binary[location] == 0xFB)
    }

    @Test func functionsWithoutACodeSectionThrow() throws {
        // A type section and a function section declaring one function, and no code section.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02, 0x01, 0x00,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "function/code section length mismatch (function: 1, code: 0)")
    }

    @Test func codeEntryCountsDisagreeingWithTheFunctionSectionThrow() throws {
        // A function section declaring one function, and a code section declaring 2 entries but holding one.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02, 0x01, 0x00,
            0x0a, 0x04, 0x02, 0x02, 0x00, 0x0b,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "function/code section length mismatch (function: 1, code: 2)")
    }

    @Test func dataCountsWithoutADataSectionThrow() throws {
        // A data count section declaring 1 segment, and no data section.
        let binary: [UInt8] = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x0c, 0x01, 0x01]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "DataCount declared 1 but no data section present")
    }

    @Test func dataCountsDisagreeingWithTheDataSectionThrow() throws {
        // A data count section declaring 2 segments, and a data section with one empty passive segment.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x0c, 0x01, 0x02, 0x0b, 0x03, 0x01, 0x01, 0x00,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "DataCount section declares 2 data segments but data section has 1")
    }

    @Test(arguments: [
        [0x01, 0x03, 0x01, 0x5f, 0x00],  // (type (struct))
        [0x01, 0x06, 0x01, 0x50, 0x00, 0x60, 0x00, 0x00],  // (type (sub (func)))
        [0x01, 0x09, 0x01, 0x4e, 0x02, 0x60, 0x00, 0x00, 0x60, 0x00, 0x00],  // (rec (type (func)) (type (func)))
    ])
    func gcTypeDefinitionsThrow(typeSection: [UInt8]) throws {
        let binary: [UInt8] = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00] + typeSection
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary), features: .all)
        }
        #expect(Self.messageText(error) == "GC type definitions are not supported")
    }

    @Test func elseInAConstExpressionThrows() throws {
        // A global whose initializer is `else end`.
        let binary: [UInt8] = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x06, 0x05, 0x01, 0x7f, 0x00, 0x05, 0x0b]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "else outside an if")
        #expect(error.location == nil)
    }

    @Test func elseInsideABlockThrowsAtItsOffset() throws {
        // A function whose body is `block else end end`; the `else` is at offset 25.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02, 0x01, 0x00,
            0x0a, 0x08, 0x01, 0x06, 0x00, 0x02, 0x40, 0x05, 0x0b, 0x0b,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "else outside an if")
        #expect(error.location == 25)
    }

    @Test func secondElseInOneIfThrowsAtItsOffset() throws {
        // A function whose body is `i32.const 0 if else else end end`; the second `else` is at offset 28.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02, 0x01, 0x00,
            0x0a, 0x0b, 0x01, 0x09, 0x00, 0x41, 0x00, 0x04, 0x40, 0x05, 0x05, 0x0b, 0x0b,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "else outside an if")
        #expect(error.location == 28)
    }

    @Test func elseInsideABlockInsideAnIfThrowsAtItsOffset() throws {
        // A function whose body is `i32.const 0 if block else end end end`; the `else` is at offset 29.
        let binary: [UInt8] = [
            0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02, 0x01, 0x00,
            0x0a, 0x0d, 0x01, 0x0b, 0x00, 0x41, 0x00, 0x04, 0x40, 0x02, 0x40, 0x05, 0x0b, 0x0b, 0x0b,
        ]
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "else outside an if")
        #expect(error.location == 29)
    }

    @Test func theSmallestUnprintableAlignmentThrows() throws {
        var binary = try wat2wasm("(module (memory 1) (func i32.const 0 i32.load drop))")
        let load = try #require(binary.indices.first { binary[$0...].starts(with: [0x28, 0x02, 0x00]) })
        binary[load + 1] = 32
        let error = try #require(throws: WasmParserError.self) {
            _ = try wasm2wat(StaticByteStreamSource(bytes: binary))
        }
        #expect(Self.messageText(error) == "alignment 2^32 has no text form")
        #expect(error.location == load)
    }

    @Test func theLargestPrintableAlignmentRoundTrips() throws {
        var binary = try wat2wasm("(module (memory 1) (func i32.const 0 i32.load drop))")
        let load = try #require(binary.indices.first { binary[$0...].starts(with: [0x28, 0x02, 0x00]) })
        binary[load + 1] = 31
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        #expect(text.contains("i32.load align=2147483648"))
        #expect(try wat2wasm(text) == binary)
    }
}
