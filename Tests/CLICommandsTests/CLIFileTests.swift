import Foundation
import Testing

@testable import CLICommands

@Suite struct CLIFileTests {
    @Test func flushReportsWhyAnEarlierWriteFailed() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let path = directory.appendingPathComponent("empty").path
            #expect(FileManager.default.createFile(atPath: path, contents: nil))
            var handle = try CLIFile.openRead(path)
            handle.write("text")
            // Leaves errno at ENOENT.
            #expect(throws: CLIFile.Error.self) {
                _ = try CLIFile.openRead(directory.appendingPathComponent("missing").path)
            }
            let error = try #require(throws: CLIFile.Error.self) {
                try handle.flush()
            }
            #expect(error.description == "I/O error: \(String(cString: strerror(EBADF)))")
            try handle.close()
        }
    }
}
