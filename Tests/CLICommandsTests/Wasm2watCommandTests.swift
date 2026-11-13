import ArgumentParser
import CLICommands
import CLITestSupport
import Foundation
import Testing
import WAT

@Suite struct Wasm2watCommandTests {
    static let multiMemoryModule = "(module (memory 1) (memory 1) (func (result i32) i32.const 0 i32.load 1))"
    static let multiMemoryText = """
        (module
          (type (;0;) (func (result i32)))
          (func (;0;) (type 0) (result i32)
            i32.const 0
            i32.load 1
          )
          (memory (;0;) 1)
          (memory (;1;) 1)
        )

        """

    @Test func decodesMultiMemoryWithoutFlags() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let input = directory.appendingPathComponent("multi-memory.wasm")
            let output = directory.appendingPathComponent("multi-memory.wat")
            try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
            let command = try Wasm2wat.parse([input.path, "-o", output.path])
            try command.run()
            #expect(try String(contentsOf: output, encoding: .utf8) == Self.multiMemoryText)
        }
    }

    @Test func replacesAnExistingOutputFile() throws {
        try PreopenFixture.withProbeDirectory { directory in
            let input = directory.appendingPathComponent("multi-memory.wasm")
            let output = directory.appendingPathComponent("multi-memory.wat")
            try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
            try Data("previous".utf8).write(to: output)
            try Wasm2wat.parse([input.path, "-o", output.path]).run()
            #expect(try String(contentsOf: output, encoding: .utf8) == Self.multiMemoryText)
            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted() == ["multi-memory.wasm", "multi-memory.wat", "probe.txt"])
        }
    }

    #if os(macOS) || os(Linux)
        @Test func writesToStandardOutputWithoutAnOutputPath() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let input = directory.appendingPathComponent("multi-memory.wasm")
                try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
                let result = try runCLI(["wasm2wat", input.path], in: directory)
                #expect(result.status == 0)
                #expect(result.standardError == "")
                #expect(result.standardOutput == Self.multiMemoryText)
            }
        }

        @Test func reportsAFailedWriteToStandardOutput() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let input = directory.appendingPathComponent("multi-memory.wasm")
                try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
                // A descriptor opened for reading makes every write to it fail with `EBADF`.
                let readOnly = try FileHandle(forReadingFrom: input)
                let result = try runCLI(["wasm2wat", input.path], in: directory, standardOutput: readOnly)
                try readOnly.close()
                #expect(result.status == EXIT_FAILURE)
                #expect(result.standardError.hasPrefix("Error: "))
            }
        }

        @Test func writesBareOutputNameInWorkingDirectory() throws {
            try PreopenFixture.withProbeDirectory { directory in
                let input = directory.appendingPathComponent("multi-memory.wasm")
                try Data(wat2wasm(Self.multiMemoryModule, features: .all)).write(to: input)
                let result = try runCLI(["wasm2wat", "multi-memory.wasm", "-o", "multi-memory.wat"], in: directory)
                #expect(result.status == 0)
                #expect(result.standardError == "")
                let output = directory.appendingPathComponent("multi-memory.wat")
                #expect(try String(contentsOf: output, encoding: .utf8) == Self.multiMemoryText)
                #expect(
                    try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
                        == ["multi-memory.wasm", "multi-memory.wat", "probe.txt", "stderr.txt", "stdout.txt"])
            }
        }

        private func runCLI(
            _ arguments: [String], in directory: URL, standardOutput: FileHandle? = nil
        ) throws -> (status: Int32, standardOutput: String, standardError: String) {
            // Files, since a pipe nobody reads blocks the child once it fills.
            let outputFile = directory.appendingPathComponent("stdout.txt")
            let errorFile = directory.appendingPathComponent("stderr.txt")
            try Data().write(to: outputFile)
            try Data().write(to: errorFile)
            let output = try FileHandle(forWritingTo: outputFile)
            let error = try FileHandle(forWritingTo: errorFile)
            let process = Process()
            process.executableURL = try wasmkitCLIExecutable()
            process.arguments = arguments
            process.currentDirectoryURL = directory
            process.standardOutput = standardOutput ?? output
            process.standardError = error
            try process.run()
            process.waitUntilExit()
            try output.close()
            try error.close()
            return (
                process.terminationStatus,
                try String(contentsOf: outputFile, encoding: .utf8),
                try String(contentsOf: errorFile, encoding: .utf8)
            )
        }
    #endif
}
