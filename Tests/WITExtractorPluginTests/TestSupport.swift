import Foundation

struct TestSupport {
    struct Configuration: Codable {
        let hostSwiftExecutablePath: URL
        let hostSdkRootPath: String?

        static let `default`: Configuration? = {
            let decoder = JSONDecoder()
            let defaultsPath = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()  // WITExtractorPluginTests
                .deletingLastPathComponent()  // Tests
                .appendingPathComponent("default.json")
            guard let bytes = try? Data(contentsOf: defaultsPath) else { return nil }
            return try? decoder.decode(Configuration.self, from: bytes)
        }()
    }

    static func withTemporaryDirectory<Result>(
        _ body: (String) throws -> Result
    ) throws -> Result {
        let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
        let templatePath = tempdir.appendingPathComponent("WasmKit.XXXXXX")
        var template = [UInt8](templatePath.path.utf8).map({ Int8($0) }) + [Int8(0)]

        if mkdtemp(&template) == nil {
            #if os(Android)
                throw Error(errno: __errno().pointee)
            #else
                throw Error(errno: errno)
            #endif
        }

        let path = String(cString: template)
        defer { _ = try? FileManager.default.removeItem(atPath: path) }
        return try body(path)
    }

    struct Error: Swift.Error, CustomStringConvertible {
        let description: String

        init(description: String) {
            self.description = description
        }

        init(errno: Int32) {
            self.init(description: String(cString: strerror(errno)))
        }
    }
}

func assertSwiftPackage(fixturePackage: String, _ trailingArguments: [String]) throws -> String {
    #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
    #else
        guard let config = TestSupport.Configuration.default else {
            fatalError("Please create 'Tests/default.json'")
        }
        func lossyUTF8(_ data: Data) -> String {
            String(decoding: data, as: UTF8.self)
        }

        func commandLine(_ executable: URL, _ arguments: [String]) -> String {
            ([executable.path] + arguments).joined(separator: " ")
        }

        func preview(_ string: String, limit: Int = 2_000) -> String {
            if string.count <= limit { return string }
            return String(string.prefix(limit)) + "\n… (truncated, total \(string.count) chars)"
        }

        let swiftExecutable = config.hostSwiftExecutablePath
        let packagePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(fixturePackage)

        return try TestSupport.withTemporaryDirectory { buildDir in
            var arguments = ["package", "--package-path", packagePath.path, "--scratch-path", buildDir]
            if let sdkRootPath = config.hostSdkRootPath {
                arguments += ["--sdk", sdkRootPath]
            }
            arguments += trailingArguments
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: swiftExecutable.path)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            try process.run()
            process.waitUntilExit()

            let stdoutBytes = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
            let stderrBytes = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()

            let command = commandLine(swiftExecutable, arguments)
            guard process.terminationStatus == 0 else {
                throw TestSupport.Error(
                    description: """
                    Failed to execute: \(command)
                    terminationStatus: \(process.terminationStatus)
                    stdout (lossy utf8, first 2000 chars):
                    \(preview(lossyUTF8(stdoutBytes)))
                    stderr (lossy utf8, first 2000 chars):
                    \(preview(lossyUTF8(stderrBytes)))
                    """
                )
            }
            struct Output: Codable {
                let witOutputPath: String
                let swiftOutputPath: String
            }
            let jsonOutput: Output
            do {
                jsonOutput = try JSONDecoder().decode(Output.self, from: stdoutBytes)
            } catch {
                throw TestSupport.Error(
                    description: """
                    Failed to decode JSON from swift stdout for: \(command)
                    decode error: \(error)
                    stdout (lossy utf8, first 2000 chars):
                    \(preview(lossyUTF8(stdoutBytes)))
                    stderr (lossy utf8, first 2000 chars):
                    \(preview(lossyUTF8(stderrBytes)))
                    """
                )
            }
            return try String(contentsOfFile: jsonOutput.witOutputPath)
        }
    #endif
}
