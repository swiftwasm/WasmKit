#if FileSystem
    import Testing

    @testable import WasmParser

    @Suite struct FileIOTests {
        @Test(arguments: [50, 110])
        func readBytesContinuesAfterShortRead(maxLength: Int) throws {
            let input = (0..<100).map { UInt8($0) }
            var remaining = input[...]
            let bytes = try FileIO.readBytes(upToCount: maxLength) { buffer in
                let count = min(3, buffer.count, remaining.count)
                buffer.copyBytes(from: remaining.prefix(count))
                remaining.removeFirst(count)
                return count
            }
            #expect(bytes == Array(input.prefix(maxLength)))
        }

        @Test func readBytesReportsFailedRead() throws {
            var hasRead = false
            let error = try #require(throws: WasmParserError.self) {
                _ = try FileIO.readBytes(upToCount: 10) { buffer in
                    guard !hasRead else { return -5 }
                    hasRead = true
                    buffer.copyBytes(from: [0x01, 0x02, 0x03])
                    return 3
                }
            }
            guard case .message(let message) = error.kind else {
                Issue.record("Expected a .message error, got \(error.kind)")
                return
            }
            #expect(message.text.hasPrefix("I/O error: "))
        }
    }
#endif
