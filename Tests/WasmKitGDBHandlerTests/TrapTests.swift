#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Testing
    import WAT

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    @Suite
    struct TrapTests {
        static let wat = """
            (module
              (func (export "_start") (result i32)
                (call $boom))
              (func $boom (result i32)
                (unreachable))
            )
            """

        @Test
        func aTrapIsReportedAsAnException() throws {
            try withHandler(debugging: Self.wat) { handler in
                let response = try handler.handle(command: .init(kind: .continue, arguments: ""))
                guard case .keyValuePairs(let pairs) = response.kind else {
                    Issue.record("expected a stop reply for the trap, got \(response.kind)")
                    return
                }
                let fields = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
                #expect(fields["reason"] == "exception")
                let description = try #require(HexEncoding.decode(fields["description"] ?? ""))
                #expect(String(decoding: description, as: UTF8.self) == "Trap: unreachable")
            }
        }

        /// A host resumes after every stop it is told about.
        @Test
        func resumingAfterATrapReportsItAgain() throws {
            try withHandler(debugging: Self.wat) { handler in
                let first = try handler.handle(command: .init(kind: .continue, arguments: ""))
                let again = try handler.handle(command: .init(kind: .continue, arguments: ""))
                guard case .keyValuePairs(let firstPairs) = first.kind,
                    case .keyValuePairs(let againPairs) = again.kind
                else {
                    Issue.record("expected stop replies, got \(first.kind) and \(again.kind)")
                    return
                }
                #expect(
                    Dictionary(firstPairs, uniquingKeysWith: { a, _ in a })
                        == Dictionary(againPairs, uniquingKeysWith: { a, _ in a }))
            }
        }

        @Test
        func aTrapReportsACallStack() throws {
            try withHandler(debugging: Self.wat) { handler in
                _ = try handler.handle(command: .init(kind: .continue, arguments: ""))
                let response = try handler.handle(command: .init(kind: .wasmCallStack, arguments: "1"))
                guard case .hexEncodedBinary(let bytes) = response.kind else {
                    Issue.record("expected a call stack, got \(response.kind)")
                    return
                }
                #expect(!bytes.isEmpty)
                #expect(bytes.count % 8 == 0)
            }
        }
    }

#endif
