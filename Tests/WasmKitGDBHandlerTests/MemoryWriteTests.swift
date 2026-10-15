#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Testing
    import WAT
    import WasmKitWASI

    @testable import WasmKit
    @testable import WasmKitGDBHandler

    @Suite
    struct MemoryWriteTests {
        /// Exits with byte 0 to observe guest memory directly.
        static let wat = """
            (module
              (memory 1)
              (data (i32.const 0) "hello")
              (func (export "_start") (result i32)
                (i32.load8_u (i32.const 0))))
            """

        private func write(_ handler: WasmKitGDBHandler, at address: UInt64, _ bytes: [UInt8]) throws -> GDBTargetResponse.Kind {
            try handler.handle(
                command: .init(
                    kind: .writeMemory,
                    arguments: "\(String(address, radix: 16)),\(String(bytes.count, radix: 16)):\(HexEncoding.encode(bytes))"
                )
            ).kind
        }

        private func read(_ handler: WasmKitGDBHandler, at address: UInt64, count: Int) throws -> [UInt8] {
            let response = try handler.handle(
                command: .init(
                    kind: .readMemory,
                    arguments: "\(String(address, radix: 16)),\(String(count, radix: 16))"
                )
            )
            guard case .hexEncodedBinary(let bytes) = response.kind else { return [] }
            return bytes
        }

        private func isOK(_ kind: GDBTargetResponse.Kind) -> Bool {
            if case .ok = kind { return true }
            return false
        }

        private func isRefusal(_ kind: GDBTargetResponse.Kind) -> Bool {
            if case .error = kind { return true }
            return false
        }

        @Test
        func writtenBytesReadBack() throws {
            try withHandler(debugging: Self.wat) { handler in
                let accepted = try self.write(handler, at: 1, [0x41, 0x42])
                #expect(self.isOK(accepted))

                let readBack = try self.read(handler, at: 0, count: 5)
                #expect(readBack == Array("hABlo".utf8))
            }
        }

        @Test
        func theGuestSeesAWrittenByte() throws {
            try withHandler(debugging: Self.wat) { handler in
                let accepted = try self.write(handler, at: 0, [0x5a])
                #expect(self.isOK(accepted))

                guard case .string(let reply) = try handler.handle(command: .init(kind: .continue, arguments: "")).kind else {
                    Issue.record("resuming did not report an exit")
                    return
                }
                #expect(reply == "W5a")
            }
        }

        @Test
        func writingToTheCodeAddressRangeIsRefused() throws {
            try withHandler(debugging: Self.wat) { handler in
                let refused = try self.write(handler, at: DebuggerMemoryView.executableCodeOffset, [0x00])
                #expect(self.isRefusal(refused))
            }
        }

        @Test
        func aRefusedWriteLeavesTheTargetUsable() throws {
            try withHandler(debugging: Self.wat) { handler in
                let refused = try self.write(handler, at: 1 << 40, [0x00])
                #expect(self.isRefusal(refused))

                let accepted = try self.write(handler, at: 0, [0x48])
                #expect(self.isOK(accepted))

                let readBack = try self.read(handler, at: 0, count: 1)
                #expect(readBack == [0x48])
            }
        }

        @Test
        func aLengthDisagreeingWithThePayloadIsRefused() throws {
            try withHandler(debugging: Self.wat) { handler in
                let response = try handler.handle(command: .init(kind: .writeMemory, arguments: "0,4:4142"))
                #expect(self.isRefusal(response.kind))

                let unchanged = try self.read(handler, at: 0, count: 1)
                #expect(unchanged == [0x68])
            }
        }

        @Test
        func aLengthThatOverflowsTheAddressSpaceIsNarrowed() throws {
            try withHandler(debugging: Self.wat) { handler in
                let response = try handler.handle(command: .init(kind: .readMemory, arguments: "0,ffffffffffffffff"))
                guard case .hexEncodedBinary(let bytes) = response.kind else {
                    Issue.record("expected memory contents, got \(response.kind)")
                    return
                }
                #expect(bytes.count == 0x1_0000)
            }
        }
    }

#endif
