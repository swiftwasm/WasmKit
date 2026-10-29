import Testing
import WasmTypes

@testable import WasmParser

/// The opcode after a prefix byte is a `u32` in LEB128, so every encoding of the same integer
/// decodes to the same instruction, up to the five bytes a `u32` may take.
@Suite struct PrefixedOpcodeDecodingTests {
    private static func module(_ sections: [(id: UInt8, content: [UInt8])]) -> [UInt8] {
        var bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]
        for section in sections {
            bytes += [section.id] + unsignedLEB128(section.content.count) + section.content
        }
        return bytes
    }

    private static func instructions(_ code: [UInt8], features: WasmFeatureSet = .default) throws -> [Instruction]? {
        let body: [UInt8] = [0x00] + code + [0x0B]
        let bytes = module([
            (id: 1, content: [0x01, 0x60, 0x00, 0x00]),
            (id: 3, content: [0x01, 0x00]),
            (id: 10, content: [0x01] + unsignedLEB128(body.count) + body),
        ])
        var parser = Parser(bytes: bytes, features: features)
        while let payload = try parser.parseNext() {
            guard case .codeSection(let codes) = payload else { continue }
            var expression = ExpressionParser(code: codes[0])
            var result: [Instruction] = []
            while let visit = try expression.parse() {
                result.append(visit.instruction)
            }
            return result
        }
        return nil
    }

    private static func errorMessage(_ body: () throws -> Void) -> String? {
        do {
            try body()
            return nil
        } catch let error as WasmParserError {
            switch error.kind {
            case .message(let message): return message.text
            case .leb(let error): return "\(error)"
            default: return error.description
            }
        } catch {
            return "\(error)"
        }
    }

    private static func unsignedLEB128(_ value: Int) -> [UInt8] {
        var value = UInt(value)
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(value & 0b0111_1111)
            value >>= 7
            if value != 0 {
                byte |= 0b1000_0000
            }
            bytes.append(byte)
        } while value != 0
        return bytes
    }

    @Test func decodesLongerEncodingsOfMiscellaneousOpcodes() throws {
        let code: [UInt8] = [
            0xFC, 0x80, 0x00,  // i32.trunc_sat_f32_s in two bytes
            0xFC, 0x87, 0x80, 0x80, 0x80, 0x00,  // i64.trunc_sat_f64_u in five bytes
            0xFC, 0x8B, 0x80, 0x00, 0x00,  // memory.fill 0 in three bytes
            0xFC, 0x10, 0x02,  // table.size 2 in its shortest encoding
        ]
        let expected: [Instruction] = [
            .conversion(.i32TruncSatF32S),
            .conversion(.i64TruncSatF64U),
            .memoryFill(memory: 0),
            .tableSize(table: 2),
            .end,
        ]
        #expect(try Self.instructions(code) == expected)
    }

    @Test func decodesLongerEncodingsOfVectorOpcodes() throws {
        let code: [UInt8] =
            [
                0xFD, 0x8C, 0x00,  // v128.const in two bytes
            ] + [UInt8](repeating: 0x2A, count: 16) + [
                0xFD, 0xFC, 0x01,  // i32x4.trunc_sat_f64x2_s_zero in its shortest encoding
                0xFD, 0xFD, 0x81, 0x80, 0x00,  // i32x4.trunc_sat_f64x2_u_zero in four bytes
            ]
        let expected: [Instruction] = [
            .v128Const(value: V128(bytes: [UInt8](repeating: 0x2A, count: 16))),
            .simd(.i32x4TruncSatF64X2SZero),
            .simd(.i32x4TruncSatF64X2UZero),
            .end,
        ]
        #expect(try Self.instructions(code) == expected)
    }

    @Test func decodesLongerEncodingsOfAtomicOpcodes() throws {
        let code: [UInt8] = [
            0xFE, 0x83, 0x00, 0x00,  // atomic.fence in two bytes, then its reserved zero
            0xFE, 0x9E, 0x80, 0x00, 0x02, 0x08,  // i32.atomic.rmw.add in three bytes
        ]
        let expected: [Instruction] = [
            .atomicFence,
            .i32AtomicRmwAdd(memarg: MemArg(offset: 8, align: 2)),
            .end,
        ]
        #expect(try Self.instructions(code, features: .threads) == expected)
    }

    @Test func decodesLongerEncodingsOfGarbageCollectionOpcodes() throws {
        // struct.new 3 in two bytes
        #expect(try Self.instructions([0xFB, 0x80, 0x00, 0x03], features: .gc) == [.structNew(typeIndex: 3), .end])
    }

    @Test func rejectsAnOpcodeLongerThanAU32() {
        // i64.trunc_sat_f64_u in six bytes
        let message = Self.errorMessage { _ = try Self.instructions([0xFC, 0x87, 0x80, 0x80, 0x80, 0x80, 0x00]) }
        #expect(message == "integerRepresentationTooLong")
    }

    @Test func reportsAnUnknownOpcodeInItsShortestEncoding() {
        #expect(Self.errorMessage { _ = try Self.instructions([0xFC, 0x7F]) } == "Illegal opcode: [252, 127]")
        #expect(Self.errorMessage { _ = try Self.instructions([0xFC, 0xFF, 0x80, 0x00]) } == "Illegal opcode: [252, 127]")
        #expect(Self.errorMessage { _ = try Self.instructions([0xFD, 0xFF, 0x7F]) } == "Illegal opcode: [253, 255, 127]")
    }

    @Test func rejectsAnAtomicFenceWithoutItsReservedZero() {
        let message = Self.errorMessage { _ = try Self.instructions([0xFE, 0x83, 0x00, 0x01], features: .threads) }
        #expect(message == "Illegal opcode: [254, 3]")
    }
}
