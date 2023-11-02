import Foundation
import XCTest

@testable import WIT
@testable import WITExtractor

struct TestSupport {
    struct Configuration: Codable {
        let hostSwiftExecutablePath: URL
        let hostSdkRootPath: String?

        var digesterPath: URL {
            hostSwiftExecutablePath.deletingLastPathComponent().appendingPathComponent("swift-api-digester")
        }

        var hostSwiftFrontendPath: URL {
            hostSwiftExecutablePath.deletingLastPathComponent().appendingPathComponent("swift-frontend")
        }

        static let `default`: Configuration? = {
            let decoder = JSONDecoder()
            let defaultsPath = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()  // WITExtractorTests
                .deletingLastPathComponent()  // Tests
                .appendingPathComponent("default.json")
            guard let bytes = try? Data(contentsOf: defaultsPath) else { return nil }
            return try? decoder.decode(Configuration.self, from: bytes)
        }()
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

    static func withTemporaryDirectory<Result>(
        _ body: (String) throws -> Result
    ) throws -> Result {
        let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
        let templatePath = tempdir.appendingPathComponent("WasmKit.XXXXXX")
        var template = [UInt8](templatePath.path.utf8).map({ Int8($0) }) + [Int8(0)]

        if mkdtemp(&template) == nil {
            throw Error(errno: errno)
        }

        let path = String(cString: template)
        defer { _ = try? FileManager.default.removeItem(atPath: path) }
        return try body(path)
    }

    static func emitModule(
        _ swiftSource: String,
        moduleDir: URL,
        moduleName: String,
        config: Configuration
    ) throws {
        let process = Process()
        let stdinPipe = Pipe()
        process.launchPath = config.hostSwiftFrontendPath.path
        var arguments = [
            "-parse-as-library", "-module-name", moduleName,
            "-emit-module", "-", "-o", moduleDir.appendingPathComponent(moduleName + ".swiftmodule").path,
        ]
        if let sdkRoot = config.hostSdkRootPath {
            arguments.append(contentsOf: ["-sdk", sdkRoot])
        }
        process.arguments = arguments
        process.standardInput = stdinPipe
        try process.run()
        try stdinPipe.fileHandleForWriting.write(contentsOf: Data(swiftSource.utf8))
        try stdinPipe.fileHandleForWriting.close()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw TestSupport.Error(
                description: "Failed to execute \(([config.hostSwiftFrontendPath.path] + arguments).joined(separator: " "))"
            )
        }
    }

    static func assertTranslation(
        _ swiftSource: String,
        _ expectedWIT: String,
        _ namespace: String = "swift",
        _ packageName: String = "wasmkit",
        _ moduleName: String = "test",
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard let config = Configuration.default else {
            throw XCTSkip("Please create 'Tests/default.json'")
        }
        var digesterArgs: [String] = []
        if let sdkRoot = config.hostSdkRootPath {
            digesterArgs.append(contentsOf: ["-sdk", sdkRoot])
        }
        let output = try withTemporaryDirectory { moduleDir in

            try emitModule(
                swiftSource,
                moduleDir: URL(fileURLWithPath: moduleDir),
                moduleName: moduleName,
                config: config
            )

            digesterArgs.append(contentsOf: ["-I", moduleDir])
            let extractor = WITExtractor(
                namespace: namespace,
                packageName: packageName,
                digesterPath: config.digesterPath.path,
                extraDigesterArguments: digesterArgs
            )
            return try extractor.runWithoutHeader(moduleName: moduleName).witContents
        }

        XCTAssertEqual(output, expectedWIT, file: file, line: line)

        var lexer = Lexer(cursor: Lexer.Cursor(input: output))
        XCTAssertNoThrow(try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit"), "Extracted WIT file is invalid")
    }
}
