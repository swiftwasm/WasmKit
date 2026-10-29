#if FileSystem
    import Foundation
    import Testing
    import WasmParser

    @Suite struct FileHandleStreamTests {
        @Test func readsBytesWithinInput() throws {
            let (first, range, last, end) = try withTemporaryFile(holding: [0x01, 0x02, 0x03, 0x04]) { path in
                // With a one-byte buffer the range read extends the buffer, and reading byte 3 refills it.
                let source = try FileHandleStreamSource(filePath: path, bufferLength: 1)
                let first = try source.readByte(at: 0)
                let range = try source.readBytes(from: 1, to: 3).map(Array.init)
                let last = try source.readByte(at: 3)
                let end = try source.readByte(at: 4)
                return (first, range, last, end)
            }
            #expect(first == 0x01)
            #expect(range == [0x02, 0x03])
            #expect(last == 0x04)
            #expect(end == nil)
        }

        @Test func readsRangesWithinBuffer() throws {
            let ranges = try withTemporaryFile(holding: [0x01, 0x02, 0x03, 0x04]) { path in
                // No range read below extends the buffer.
                let source = try FileHandleStreamSource(filePath: path, bufferLength: 4)
                return try [source.readBytes(from: 0, to: 2), source.readBytes(from: 2, to: 2), source.readBytes(from: 2, to: 4)]
                    .map { $0.map(Array.init) }
            }
            #expect(ranges == [[0x01, 0x02], [], [0x03, 0x04]])
        }

        // On 64-bit platforms `Int.max` crashes a source that allocates the requested length.
        @Test(arguments: [4, Int.max])
        func returnsNilForRangePastEndOfInput(endOffset: Int) throws {
            let bytes = try withTemporaryFile(holding: [0x01, 0x02, 0x03]) { path in
                // With a one-byte buffer the range read below is short but not empty.
                try FileHandleStreamSource(filePath: path, bufferLength: 1).readBytes(from: 0, to: endOffset)
            }
            #expect(bytes == nil)
        }

        @Test func throwsForMissingFile() throws {
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString)").path
            let error = try #require(throws: WasmParserError.self) {
                _ = try FileHandleStreamSource(filePath: path)
            }
            guard case .message(let message) = error.kind else {
                Issue.record("Expected a .message error, got \(error.kind)")
                return
            }
            #expect(message.text.hasPrefix("failed to open file \(path): "))
        }

        private func withTemporaryFile<T>(holding contents: [UInt8], _ body: (String) throws -> T) throws -> T {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("file-handle-stream-\(UUID().uuidString)")
            let result = Result {
                try Data(contents).write(to: file)
                return try body(file.path)
            }
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
            return try result.get()
        }
    }
#endif
