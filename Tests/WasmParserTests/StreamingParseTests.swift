import Testing
import WasmTypes

@testable import WasmParser

@Suite
struct StreamingParseTests {
    @Test func codeEntriesDecodeLocalsAndExpressions() throws {
        // Code section body of `(func local.get 0)` and `(func (local i64 i64) local.get 0)`.
        let bytes: ArraySlice<UInt8> = [0x02, 0x04, 0x00, 0x20, 0x00, 0x0b, 0x06, 0x01, 0x02, 0x7e, 0x20, 0x00, 0x0b]

        var parser = WasmParser.Parser(bytes: bytes)
        let count: UInt32 = try parser.parseUnsigned()
        var codes: [Code] = []
        for _ in 0..<count { codes.append(try parser.parseCodeEntry()) }

        #expect(try parser.stream.hasReachedEnd())
        #expect(codes.map(\.locals) == [[], [.i64, .i64]])
        #expect(codes.map { Array($0.expression) } == [[0x20, 0x00, 0x0b], [0x20, 0x00, 0x0b]])
        #expect(codes.map(\.offset) == [3, 10])
    }

    @Test func dataEntriesDecodeEachSegmentKind() throws {
        // Kind 0 `(i32.const 0) "first"`, kind 1 `"passive"`, kind 2 in memory 1 `(i32.const 100) "third"`.
        let bytes: ArraySlice<UInt8> = [
            0x03,
            0x00, 0x41, 0x00, 0x0b, 0x05, 0x66, 0x69, 0x72, 0x73, 0x74,
            0x01, 0x07, 0x70, 0x61, 0x73, 0x73, 0x69, 0x76, 0x65,
            0x02, 0x01, 0x41, 0xe4, 0x00, 0x0b, 0x05, 0x74, 0x68, 0x69, 0x72, 0x64,
        ]

        var parser = WasmParser.Parser(bytes: bytes)
        let count: UInt32 = try parser.parseUnsigned()
        var segments: [DataSegment] = []
        for _ in 0..<count { segments.append(try parser.parseDataSegmentEntry()) }

        #expect(try parser.stream.hasReachedEnd())
        #expect(
            segments == [
                .active(.init(index: 0, offset: [.i32Const(value: 0), .end], initializer: Array("first".utf8)[...])),
                .passive(Array("passive".utf8)[...]),
                .active(.init(index: 1, offset: [.i32Const(value: 100), .end], initializer: Array("third".utf8)[...])),
            ])
    }

    @Test func elementEntriesDecodeIndexLists() throws {
        // Element section body of `(elem (i32.const 0) func 0)` and `(elem funcref (item ref.func 0))`,
        // which WasmKit assembles as an active and a passive function index list.
        let bytes: ArraySlice<UInt8> = [0x02, 0x00, 0x41, 0x00, 0x0b, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00]

        var parser = WasmParser.Parser(bytes: bytes)
        let count: UInt32 = try parser.parseUnsigned()
        var segments: [ElementSegment] = []
        for _ in 0..<count { segments.append(try parser.parseElementEntry()) }

        #expect(try parser.stream.hasReachedEnd())
        #expect(
            segments == [
                ElementSegment(
                    type: .funcRef, initializer: [[.refFunc(functionIndex: 0)]],
                    mode: .active(table: 0, offset: [.i32Const(value: 0), .end])),
                ElementSegment(type: .funcRef, initializer: [[.refFunc(functionIndex: 0)]], mode: .passive),
            ])
    }

    @Test func dataSegmentRejectsUnknownKind() throws {
        var parser = WasmParser.Parser(bytes: [0x03])
        let error = try #require(throws: WasmParserError.self) {
            _ = try parser.parseDataSegmentEntry()
        }
        guard case .message(let message) = error.kind else {
            Issue.record("Expected a .message error, got \(error.kind)")
            return
        }
        #expect(message.text == "Malformed data segment kind: 3")
    }
}
