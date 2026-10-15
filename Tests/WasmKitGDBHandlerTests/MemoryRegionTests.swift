#if WasmDebuggingSupport

    import GDBRemoteProtocol
    import Testing
    import WAT

    @testable import WasmKitGDBHandler

    @Suite
    struct MemoryRegionTests {
        /// One page of linear memory, so the mapped region's size is a known 0x10000.
        static let wat = """
            (module
              (memory 1)
              (func (export "_start") (result i32)
                (i32.load8_u (i32.const 0))))
            """

        private static let pageSize = UInt64(0x1_0000)
        private let offset = DebuggerMemoryView.executableCodeOffset

        private func withModule(_ wat: String = MemoryRegionTests.wat, _ body: (WasmKitGDBHandler, Int) throws -> Void) throws {
            let moduleSize = try wat2wasm(wat).count
            try withHandler(debugging: wat) { try body($0, moduleSize) }
        }

        private func region(_ handler: WasmKitGDBHandler, at address: UInt64) throws -> [String: String] {
            let response = try handler.handle(
                command: .init(kind: .memoryRegionInfo, arguments: String(address, radix: 16)))
            guard case .keyValuePairs(let pairs) = response.kind else {
                Issue.record("expected memory region fields, got \(response.kind)")
                return [:]
            }
            return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
        }

        @Test
        func linearMemoryIsAReadWriteRange() throws {
            try withModule { handler, _ in
                let memory = try region(handler, at: 0)
                #expect(memory["start"] == "0")
                #expect(memory["size"] == String(Self.pageSize, radix: 16))
                #expect(memory["permissions"] == "rw")
                #expect(memory["name"] == HexEncoding.encode(Array("memory".utf8)))
            }
        }

        @Test
        func theModuleImageIsAReadExecuteRange() throws {
            try withModule { handler, moduleSize in
                let code = try region(handler, at: offset)
                #expect(code["start"] == String(offset, radix: 16))
                #expect(code["size"] == String(moduleSize, radix: 16))
                #expect(code["permissions"] == "rx")
                #expect(code["name"] == HexEncoding.encode(Array("module".utf8)))
            }
        }

        @Test
        func theGapBelowTheModuleImageReachesIt() throws {
            try withModule { handler, _ in
                let gap = try region(handler, at: Self.pageSize)
                #expect(gap["start"] == String(Self.pageSize, radix: 16))
                #expect(gap["size"] == String(offset - Self.pageSize, radix: 16))
                #expect(gap["permissions"] == nil)
            }
        }

        @Test
        func theRangeAboveTheModuleImageReachesTheEndOfTheAddressSpace() throws {
            try withModule { handler, moduleSize in
                let end = offset + UInt64(moduleSize)
                let top = try region(handler, at: end)
                #expect(top["start"] == String(end, radix: 16))
                #expect(top["size"] == String(UInt64.max - end, radix: 16))
                #expect(top["permissions"] == nil)
            }
        }

        @Test
        func theWalkCoversTheAddressSpaceWithoutOverlapping() throws {
            try withModule { handler, _ in
                var address = UInt64(0)
                var previousEnd: UInt64?
                var steps = 0
                while steps < 8 {
                    steps += 1
                    let fields = try region(handler, at: address)
                    let start = try #require(UInt64(fields["start"] ?? "", radix: 16))
                    let size = try #require(UInt64(fields["size"] ?? "", radix: 16))
                    #expect(start == previousEnd ?? 0)
                    previousEnd = start + size
                    if previousEnd == UInt64.max { break }
                    address = previousEnd!
                }
                #expect(previousEnd == UInt64.max)
                #expect(steps == 4)
            }
        }

        @Test
        func aModuleWithoutLinearMemoryMapsNothingAtZero() throws {
            let wat = """
                (module
                  (func (export "_start") (result i32)
                    (i32.const 0)))
                """
            try withModule(wat) { handler, _ in
                let bottom = try region(handler, at: 0)
                #expect(bottom["start"] == "0")
                #expect(bottom["size"] == String(offset, radix: 16))
                #expect(bottom["permissions"] == nil)
                #expect(bottom["name"] == nil)
            }
        }

        private func readReply(_ handler: WasmKitGDBHandler, at address: UInt64, length: UInt64) throws -> GDBTargetResponse.Kind {
            try handler.handle(
                command: .init(
                    kind: .readMemory,
                    arguments: "\(String(address, radix: 16)),\(String(length, radix: 16))")
            ).kind
        }

        @Test
        func readingAnUnmappedRangeIsRefused() throws {
            try withModule { handler, moduleSize in
                let unmapped: [UInt64] = [
                    Self.pageSize,  // Above linear memory, below the module image.
                    offset + UInt64(moduleSize) + 0x10,
                    0xc000_0000_0000_0000,
                ]
                for address in unmapped {
                    guard case .error = try readReply(handler, at: address, length: 4) else {
                        Issue.record("expected a refusal for \(String(address, radix: 16))")
                        continue
                    }
                }
            }
        }

        @Test
        func anEmptyReadOfAnUnmappedRangeIsEmpty() throws {
            try withModule { handler, moduleSize in
                for address in [Self.pageSize + 0x10, offset + UInt64(moduleSize) + 0x10] {
                    guard case .hexEncodedBinary(let bytes) = try readReply(handler, at: address, length: 0) else {
                        Issue.record("expected an empty read at \(String(address, radix: 16)) to be answered")
                        continue
                    }
                    #expect(bytes.isEmpty)
                }
            }
        }

        @Test
        func aReadCrossingTheEndOfLinearMemoryIsNarrowed() throws {
            try withModule { handler, _ in
                guard case .hexEncodedBinary(let bytes) = try readReply(handler, at: Self.pageSize - 4, length: 0x100) else {
                    Issue.record("expected memory contents")
                    return
                }
                #expect(bytes.count == 4)
            }
        }

        @Test
        func aQueryWithoutAnAddressReportsSupport() throws {
            try withModule { handler, _ in
                let response = try handler.handle(command: .init(kind: .memoryRegionInfo, arguments: ""))
                guard case .ok = response.kind else {
                    Issue.record("expected support to be reported, got \(response.kind)")
                    return
                }
            }
        }

        @Test
        func aQueryWithAMalformedAddressIsRefused() throws {
            try withModule { handler, _ in
                let response = try handler.handle(command: .init(kind: .memoryRegionInfo, arguments: "zz"))
                guard case .error = response.kind else {
                    Issue.record("expected a refusal, got \(response.kind)")
                    return
                }
            }
        }
    }

#endif
