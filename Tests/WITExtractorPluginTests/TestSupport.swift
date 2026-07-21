import Foundation

struct TestSupport {
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

        let path = String(decoding: template.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
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

struct ExtractResult {
    let witContents: String
    /// SwiftPM does not forward command-plugin stderr; diagnostics come via the output-mapping JSON.
    let diagnostics: String
}

/// `xcrun --find swift` honors the TOOLCHAINS env var.
private func hostSwiftExecutable() throws -> URL {
    if let override = ProcessInfo.processInfo.environment["WASMKIT_TEST_SWIFT"] {
        return URL(fileURLWithPath: override)
    }
    #if os(macOS)
        return URL(fileURLWithPath: try captureStdout("/usr/bin/xcrun", ["--find", "swift"]))
    #else
        return URL(fileURLWithPath: try captureStdout("/usr/bin/env", ["which", "swift"]))
    #endif
}

private func captureStdout(_ launchPath: String, _ arguments: [String]) throws -> String {
    // Single-line output: reading after waitUntilExit cannot fill the pipe and deadlock.
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw TestSupport.Error(
            description: "\(launchPath) \(arguments.joined(separator: " ")) failed (\(process.terminationStatus))")
    }
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}

private func fixtureURL(_ fixturePackage: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent(fixturePackage)
}

/// Writes output to a log file: a large build log would fill a pipe and deadlock waitUntilExit.
private func runSwift(_ swift: URL, _ arguments: [String], buildDir: String) throws {
    let logURL = URL(fileURLWithPath: buildDir).appendingPathComponent("swift.log")
    _ = FileManager.default.createFile(atPath: logURL.path, contents: nil)
    let logHandle = try FileHandle(forWritingTo: logURL)
    defer { try? logHandle.close() }
    let process = Process()
    process.executableURL = swift
    process.arguments = arguments
    process.standardOutput = logHandle
    process.standardError = logHandle
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let log = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
        throw TestSupport.Error(
            description: "swift \(arguments.joined(separator: " ")) failed (\(process.terminationStatus)):\n\(log)")
    }
}

func assertSwiftPackage(fixturePackage: String, _ trailingArguments: [String]) throws -> ExtractResult {
    #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
    #else
        let swift = try hostSwiftExecutable()
        return try TestSupport.withTemporaryDirectory { buildDir in
            let outputMappingPath = URL(fileURLWithPath: buildDir).appendingPathComponent("output-mapping.json").path
            let arguments =
                [
                    "package", "--package-path", fixtureURL(fixturePackage).path, "--scratch-path", buildDir,
                    "extract-wit", "--output-mapping", outputMappingPath,
                ] + trailingArguments
            try runSwift(swift, arguments, buildDir: buildDir)
            struct Output: Codable {
                let witOutputPath: String
                let swiftOutputPath: String
                let diagnostics: String?
            }
            let jsonOutput = try JSONDecoder().decode(
                Output.self, from: try Data(contentsOf: URL(fileURLWithPath: outputMappingPath)))
            return ExtractResult(
                witContents: try String(contentsOfFile: jsonOutput.witOutputPath, encoding: .utf8),
                diagnostics: jsonOutput.diagnostics ?? "")
        }
    #endif
}

func assertSwiftBuilds(fixturePackage: String) throws {
    #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
    #else
        let swift = try hostSwiftExecutable()
        try TestSupport.withTemporaryDirectory { buildDir in
            try runSwift(
                swift, ["build", "--package-path", fixtureURL(fixturePackage).path, "--scratch-path", buildDir],
                buildDir: buildDir)
        }
    #endif
}
