import Foundation
import XCTest

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
        throw XCTSkip("WITExtractor does not support platforms where Foundation.Process is unavailable")
    #else
        guard let config = TestSupport.Configuration.default else {
            throw XCTSkip("Please create 'Tests/default.json'")
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
            let process = Process()
            process.executableURL = URL(fileURLWithPath: swiftExecutable.path)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw TestSupport.Error(
                    description: "Failed to execute \(([swiftExecutable.path] + arguments).joined(separator: " "))"
                )
            }
            guard let stdoutBytes = try stdoutPipe.fileHandleForReading.readToEnd() else { return "" }
            struct Output: Codable {
                let witOutputPath: String
                let swiftOutputPath: String
            }
            let jsonOutput = try JSONDecoder().decode(Output.self, from: stdoutBytes)
            return try String(contentsOfFile: jsonOutput.witOutputPath)
        }
    #endif
}
