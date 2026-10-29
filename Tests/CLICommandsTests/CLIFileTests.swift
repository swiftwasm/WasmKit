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

    @Test func writeToDirectoryFailsToOpenPath() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let path = directory.appendingPathComponent("target").path
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false)
            let error = try #require(throws: CLIFile.Error.self) {
                try CLIFile.write(to: path) { handle in handle.write("text") }
            }
            #expect(error.description.hasPrefix("Failed to create file: \(path) ("))
            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["probe.txt", "target"])
        }
    }

    @Test func writeCreatesTemporaryFileInOutputDirectory() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let subdirectory = directory.appendingPathComponent("output")
            try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: false)
            // U+0301 joins the `/` before it into one `Character`.
            let path = subdirectory.path + "/\u{301}x.wat"
            try CLIFile.write(to: path) { handle in
                handle.write("text")
                let names = try FileManager.default.contentsOfDirectory(atPath: subdirectory.path)
                #expect(names.map { $0.hasPrefix("wasm2wat-") } == [true])
            }
            #expect(try String(contentsOfFile: path, encoding: .utf8) == "text")
            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["output", "probe.txt"])
        }
    }

    #if !os(Windows)
        @Test func writeGoesThroughSymlink() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let target = directory.appendingPathComponent("target.wat").path
                let link = directory.appendingPathComponent("link.wat").path
                try Data("previous".utf8).write(to: URL(fileURLWithPath: target))
                try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: target)
                try CLIFile.write(to: link) { handle in handle.write("text") }
                #expect(try FileManager.default.attributesOfItem(atPath: link)[.type] as? FileAttributeType == .typeSymbolicLink)
                #expect(try String(contentsOfFile: target, encoding: .utf8) == "text")
            }
        }

        @Test func writeReplacesDanglingSymlink() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let target = directory.appendingPathComponent("missing.wat").path
                let link = directory.appendingPathComponent("link.wat").path
                try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: target)
                try CLIFile.write(to: link) { handle in handle.write("text") }
                #expect(try FileManager.default.attributesOfItem(atPath: link)[.type] as? FileAttributeType == .typeRegular)
                #expect(try String(contentsOfFile: link, encoding: .utf8) == "text")
                #expect(!FileManager.default.fileExists(atPath: target))
            }
        }

        @Test func writeAcceptsLongestFileName() throws {
            try PreopenFixture.withProbeDirectory { directory in
                // 255 bytes, the most macOS and Linux allow in one file name.
                let name = String(repeating: "a", count: 251) + ".wat"
                let path = directory.appendingPathComponent(name).path
                try CLIFile.write(to: path) { handle in handle.write("text") }
                #expect(try String(contentsOfFile: path, encoding: .utf8) == "text")
                #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == [name, "probe.txt"])
            }
        }
    #endif

    #if os(Windows)
        @Test func temporaryFileOfDriveRelativeOutputStaysOnItsDrive() {
            #expect(CLIFile.directoryPrefix(of: "C:out.wat") == "C:")
        }
    #endif

    #if os(macOS) || os(Linux)
        @Test func writeGoesIntoNamedPipe() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let path = directory.appendingPathComponent("pipe").path
                try #require(mkfifo(path, 0o600) == 0)
                // With the read end open, opening the write end does not block.
                let readEnd = open(path, O_RDONLY | O_NONBLOCK)
                try #require(readEnd >= 0)
                let reader = FileHandle(fileDescriptor: readEnd, closeOnDealloc: true)
                try CLIFile.write(to: path) { handle in handle.write("text") }
                #expect(try reader.readToEnd() == Data("text".utf8))
                #expect(try FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType != .typeRegular)
            }
        }

        @Test(.enabled(if: geteuid() != 0, "root ignores directory permissions"))
        func writeInReadOnlyDirectoryNamesOutputPath() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let readOnly = directory.appendingPathComponent("read-only")
                try FileManager.default.createDirectory(at: readOnly, withIntermediateDirectories: false)
                try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: readOnly.path)
                let path = readOnly.appendingPathComponent("output.wat").path
                let error = #expect(throws: CLIFile.Error.self) {
                    try CLIFile.write(to: path) { handle in handle.write("text") }
                }
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnly.path)
                #expect(error?.description.hasPrefix("Failed to write \(path): Failed to create file: \(readOnly.path)/wasm2wat-") == true)
            }
        }

        @Test(.enabled(if: geteuid() != 0, "root ignores file permissions"))
        func writeRefusesReadOnlyOutput() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let path = directory.appendingPathComponent("output.wat").path
                try Data("previous".utf8).write(to: URL(fileURLWithPath: path))
                try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: path)
                let error = #expect(throws: CLIFile.Error.self) {
                    try CLIFile.write(to: path) { handle in handle.write("text") }
                }
                #expect(error?.description == "Failed to write file: \(path) (\(String(cString: strerror(EACCES))))")
                #expect(try String(contentsOfFile: path, encoding: .utf8) == "previous")
                #expect(try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int == 0o444)
                #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["output.wat", "probe.txt"])
            }
        }
    #endif

    #if os(macOS)
        @Test func writeRefusesImmutableOutput() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let path = directory.appendingPathComponent("output.wat").path
                try Data("previous".utf8).write(to: URL(fileURLWithPath: path))
                try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: path)
                let error = #expect(throws: CLIFile.Error.self) {
                    try CLIFile.write(to: path) { handle in handle.write("text") }
                }
                try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: path)
                #expect(error?.description == "Failed to write file: \(path) (\(String(cString: strerror(EPERM))))")
                #expect(try String(contentsOfFile: path, encoding: .utf8) == "previous")
                #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["output.wat", "probe.txt"])
            }
        }

        @Test(.enabled(if: geteuid() != 0, "root ignores ACL deny entries"))
        func failedRenameRemovesTemporaryFile() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let path = directory.appendingPathComponent("output.wat").path
                try Data("previous".utf8).write(to: URL(fileURLWithPath: path))
                // The file stays writable, but `rename` cannot replace a file whose ACL denies delete.
                try chmod(["+a", "user:\(NSUserName()) deny delete", path])
                let error = #expect(throws: CLIFile.Error.self) {
                    try CLIFile.write(to: path) { handle in handle.write("text") }
                }
                try chmod(["-N", path])
                #expect(error?.description == "Failed to replace file: \(path) (\(String(cString: strerror(EACCES))))")
                #expect(try String(contentsOfFile: path, encoding: .utf8) == "previous")
                #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["output.wat", "probe.txt"])
            }
        }

        private func chmod(_ arguments: [String]) throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/chmod")
            process.arguments = arguments
            try process.run()
            process.waitUntilExit()
            try #require(process.terminationStatus == 0)
        }
    #endif
}
