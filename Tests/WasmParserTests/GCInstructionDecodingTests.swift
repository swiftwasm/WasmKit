import Testing
import WasmTypes

@testable import WasmParser

@Suite struct GCInstructionDecodingTests {
    private static func ref(_ heapType: AbstractHeapType, nullable: Bool) -> ReferenceType {
        ReferenceType(isNullable: nullable, heapType: .abstract(heapType))
    }

    private static func ref(_ typeIndex: UInt32, nullable: Bool) -> ReferenceType {
        ReferenceType(isNullable: nullable, heapType: .concrete(typeIndex: typeIndex))
    }

    private static func module(_ sections: [(id: UInt8, content: [UInt8])]) -> [UInt8] {
        var bytes: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]
        for section in sections {
            bytes += [section.id] + unsignedLEB128(section.content.count) + section.content
        }
        return bytes
    }

    private static func instructions(_ code: [UInt8], features: WasmFeatureSet) throws -> [Instruction]? {
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
            guard case .message(let message) = error.kind else { return error.description }
            return message.text
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

    @Test func decodesEveryInstruction() throws {
        let code: [UInt8] = [
            0xFB, 0x1C,  // ref.i31
            0xFB, 0x1D,  // i31.get_s
            0xFB, 0x1E,  // i31.get_u
            0xFB, 0x00, 0x03,  // struct.new 3
            0xFB, 0x01, 0x03,  // struct.new_default 3
            0xFB, 0x02, 0x03, 0x05,  // struct.get 3 5
            0xFB, 0x03, 0x03, 0x05,  // struct.get_s 3 5
            0xFB, 0x04, 0x03, 0x05,  // struct.get_u 3 5
            0xFB, 0x05, 0x03, 0x05,  // struct.set 3 5
            0xFB, 0x06, 0x03,  // array.new 3
            0xFB, 0x07, 0x03,  // array.new_default 3
            0xFB, 0x08, 0x03, 0x05,  // array.new_fixed 3 5
            0xFB, 0x0B, 0x03,  // array.get 3
            0xFB, 0x0C, 0x03,  // array.get_s 3
            0xFB, 0x0D, 0x03,  // array.get_u 3
            0xFB, 0x0E, 0x03,  // array.set 3
            0xFB, 0x0F,  // array.len
            0xD3,  // ref.eq
            0xFB, 0x1A,  // any.convert_extern
            0xFB, 0x1B,  // extern.convert_any
            0xFB, 0x09, 0x03, 0x05,  // array.new_data 3 5
            0xFB, 0x0A, 0x03, 0x05,  // array.new_elem 3 5
            0xFB, 0x10, 0x03,  // array.fill 3
            0xFB, 0x11, 0x03, 0x05,  // array.copy 3 5
            0xFB, 0x12, 0x03, 0x05,  // array.init_data 3 5
            0xFB, 0x13, 0x03, 0x05,  // array.init_elem 3 5
            0xFB, 0x14, 0x07,  // ref.test (ref 7)
            0xFB, 0x15, 0x07,  // ref.test (ref null 7)
            0xFB, 0x16, 0x07,  // ref.cast (ref 7)
            0xFB, 0x17, 0x07,  // ref.cast (ref null 7)
            0xFB, 0x18, 0x00, 0x00, 0x03, 0x05,  // br_on_cast 0 (ref 3) (ref 5)
            0xFB, 0x19, 0x03, 0x00, 0x03, 0x05,  // br_on_cast_fail 0 (ref null 3) (ref null 5)
        ]
        let expected: [Instruction] = [
            .refI31, .i31GetS, .i31GetU,
            .structNew(typeIndex: 3), .structNewDefault(typeIndex: 3),
            .structGet(typeIndex: 3, fieldIndex: 5), .structGetS(typeIndex: 3, fieldIndex: 5),
            .structGetU(typeIndex: 3, fieldIndex: 5), .structSet(typeIndex: 3, fieldIndex: 5),
            .arrayNew(typeIndex: 3), .arrayNewDefault(typeIndex: 3), .arrayNewFixed(typeIndex: 3, size: 5),
            .arrayGet(typeIndex: 3), .arrayGetS(typeIndex: 3), .arrayGetU(typeIndex: 3), .arraySet(typeIndex: 3),
            .arrayLen, .refEq, .anyConvertExtern, .externConvertAny,
            .arrayNewData(typeIndex: 3, dataIndex: 5), .arrayNewElem(typeIndex: 3, elemIndex: 5),
            .arrayFill(typeIndex: 3), .arrayCopy(destType: 3, srcType: 5),
            .arrayInitData(typeIndex: 3, dataIndex: 5), .arrayInitElem(typeIndex: 3, elemIndex: 5),
            .refTest(.refTest, type: .concrete(typeIndex: 7)), .refTest(.refTestNull, type: .concrete(typeIndex: 7)),
            .refCast(.refCast, type: .concrete(typeIndex: 7)), .refCast(.refCastNull, type: .concrete(typeIndex: 7)),
            .brOnCast(relativeDepth: 0, castFrom: Self.ref(3, nullable: false), castTo: Self.ref(5, nullable: false)),
            .brOnCastFail(relativeDepth: 0, castFrom: Self.ref(3, nullable: true), castTo: Self.ref(5, nullable: true)),
            .end,
        ]
        #expect(try Self.instructions(code, features: .gc) == expected)
    }

    @Test func decodesAbstractHeapTypesInCasts() throws {
        #expect(try Self.instructions([0xFB, 0x14, 0x6E], features: .gc) == [.refTest(.refTest, type: .abstract(.any)), .end])
        #expect(try Self.instructions([0xFB, 0x15, 0x6E], features: .gc) == [.refTest(.refTestNull, type: .abstract(.any)), .end])
        #expect(try Self.instructions([0xFB, 0x16, 0x6C], features: .gc) == [.refCast(.refCast, type: .abstract(.i31)), .end])
        #expect(try Self.instructions([0xFB, 0x17, 0x6C], features: .gc) == [.refCast(.refCastNull, type: .abstract(.i31)), .end])
    }

    @Test func decodesCastFlags() throws {
        // br_on_cast 0 anyref (ref eq)
        #expect(
            try Self.instructions([0xFB, 0x18, 0x01, 0x00, 0x6E, 0x6D], features: .gc) == [
                .brOnCast(relativeDepth: 0, castFrom: Self.ref(.any, nullable: true), castTo: Self.ref(.eq, nullable: false)), .end,
            ])
        // br_on_cast 0 (ref any) (ref null eq)
        #expect(
            try Self.instructions([0xFB, 0x18, 0x02, 0x00, 0x6E, 0x6D], features: .gc) == [
                .brOnCast(relativeDepth: 0, castFrom: Self.ref(.any, nullable: false), castTo: Self.ref(.eq, nullable: true)), .end,
            ])
        // br_on_cast_fail 0 (ref null any) (ref null eq)
        #expect(
            try Self.instructions([0xFB, 0x19, 0x03, 0x00, 0x6E, 0x6D], features: .gc) == [
                .brOnCastFail(relativeDepth: 0, castFrom: Self.ref(.any, nullable: true), castTo: Self.ref(.eq, nullable: true)), .end,
            ])
        // br_on_cast 2 structref (ref array)
        #expect(
            try Self.instructions([0xFB, 0x18, 0x01, 0x02, 0x6B, 0x6A], features: .gc) == [
                .brOnCast(relativeDepth: 2, castFrom: Self.ref(.structRef, nullable: true), castTo: Self.ref(.arrayRef, nullable: false)),
                .end,
            ])
    }

    @Test func rejectsWithoutGC() {
        #expect(Self.errorMessage { _ = try Self.instructions([0xD3], features: .default) } == "Illegal opcode: [211]")
        #expect(Self.errorMessage { _ = try Self.instructions([0xFB, 0x1C], features: .default) } == "Illegal opcode: [251]")
    }

    @Test func rejectsInConstantExpressionWithoutGC() throws {
        // (global i32 (i31.get_s (ref.i31 (i32.const 0))))
        let bytes = Self.module([(id: 6, content: [0x01, 0x7F, 0x00, 0x41, 0x00, 0xFB, 0x1C, 0xFB, 0x1D, 0x0B])])
        var parser = Parser(bytes: bytes, features: .default)
        #expect(Self.errorMessage { while try parser.parseNext() != nil {} } == "Illegal opcode: [251]")
        parser = Parser(bytes: bytes, features: .gc)
        while try parser.parseNext() != nil {}
    }

    @Test func rejectsUnknownCastFlags() {
        let message = Self.errorMessage { _ = try Self.instructions([0xFB, 0x18, 0x04, 0x00, 0x6E, 0x6D], features: .gc) }
        #expect(message == "Invalid cast flags: 4")
    }

    @Test func rejectsUnknownGCOpcode() {
        let message = Self.errorMessage { _ = try Self.instructions([0xFB, 0x1F], features: .gc) }
        #expect(message == "Illegal opcode: [251, 31]")
    }
}
