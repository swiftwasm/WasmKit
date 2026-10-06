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

        static let localWat = """
            (module
              (func (export "_start") (result i32)
                (local $outer i32)
                (local.set $outer (i32.const 42))
                (call $boom (i32.const 7)))
              (func $boom (param i32) (result i32)
                (unreachable))
            )
            """

        /// The trap leaves the stack in place, so the frames can still be read.
        @Test
        func aTrappedFrameStillAnswersALocalRead() throws {
            try withHandler(debugging: Self.localWat) { handler in
                _ = try handler.handle(command: .init(kind: .continue, arguments: ""))

                let read = try handler.handle(command: .init(kind: .wasmLocal, arguments: "0;0"))
                guard case .hexEncodedBinary(let bytes) = read.kind else {
                    Issue.record("expected the parameter after a trap, got \(read.kind)")
                    return
                }
                #expect(bytes.prefix(4).elementsEqual([7, 0, 0, 0]))
            }
        }

        @Test
        func anOuterTrappedFrameAnswersALocalRead() throws {
            try withHandler(debugging: Self.localWat) { handler in
                _ = try handler.handle(command: .init(kind: .continue, arguments: ""))

                let read = try handler.handle(command: .init(kind: .wasmLocal, arguments: "1;0"))
                guard case .hexEncodedBinary(let bytes) = read.kind else {
                    Issue.record("expected the caller's local after a trap, got \(read.kind)")
                    return
                }
                #expect(bytes.prefix(4).elementsEqual([42, 0, 0, 0]))
            }
        }

        @Test
        func anUnknownFrameAfterATrapIsRefused() throws {
            try withHandler(debugging: Self.localWat) { handler in
                _ = try handler.handle(command: .init(kind: .continue, arguments: ""))

                let read = try handler.handle(command: .init(kind: .wasmLocal, arguments: "9;0"))
                guard case .error = read.kind else {
                    Issue.record("expected an error reply for an unknown frame, got \(read.kind)")
                    return
                }
            }
        }

        @Test
        func anUnknownLocalAfterATrapIsRefusedWithoutLosingTheTarget() throws {
            try withHandler(debugging: Self.localWat) { handler in
                _ = try handler.handle(command: .init(kind: .continue, arguments: ""))

                let read = try handler.handle(command: .init(kind: .wasmLocal, arguments: "0;9"))
                guard case .error = read.kind else {
                    Issue.record("expected an error reply for an unknown local, got \(read.kind)")
                    return
                }

                let status = try handler.handle(command: .init(kind: .targetStatus, arguments: ""))
                guard case .keyValuePairs = status.kind else {
                    Issue.record("expected the target to still answer, got \(status.kind)")
                    return
                }
            }
        }
    }

#endif
