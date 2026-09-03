#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Testing
    import WAT

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    @Suite
    struct ExitTests {
        /// Asking WASI to exit is the only way a guest ends with a status of its own choosing, and
        /// it is the way a C `main` returning nonzero gets there.
        static let wat = """
            (module
              (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))
              (memory (export "memory") 1)
              (func (export "_start")
                (call $proc_exit (i32.const 75))
                (unreachable))
            )
            """

        /// The reply a `c` produced, or nil where it was not the plain string an exit is reported as.
        private func continueGuest(_ handler: WasmKitGDBHandler) throws -> String? {
            guard case .string(let reply) = try handler.handle(command: .init(kind: .continue, arguments: "")).kind
            else { return nil }
            return reply
        }

        /// An exit reaches the target as an error thrown out of a host call. Letting it escape drops
        /// the connection, so a host sees the guest vanish rather than the status it ended with.
        @Test
        func anExitIsReportedWithItsStatus() throws {
            try withHandler(debugging: Self.wat) { handler in
                let reply = try self.continueGuest(handler)
                #expect(reply == "W4b")
            }
        }

        /// A host resumes after every stop it is told about, including the last one.
        @Test
        func resumingAfterAnExitReportsItAgain() throws {
            try withHandler(debugging: Self.wat) { handler in
                let first = try self.continueGuest(handler)
                let again = try self.continueGuest(handler)
                #expect(again == first)
            }
        }
    }

#endif
