import Foundation
import Testing

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
            var cString = strerror(errno)!
            var bytes = [UInt8]()
            while cString.pointee != 0 {
                bytes.append(UInt8(cString.pointee))
                cString += 1
            }

            self.init(description: String(decoding: bytes, as: UTF8.self))
        }
    }

    static func withTemporaryDirectory<Result>(
        _ body: (String) throws -> Result
    ) throws -> Result {
        let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
        let templatePath = tempdir.appendingPathComponent("WasmKit.XXXXXX")
        var template = [UInt8](templatePath.path.utf8).map({ UInt8($0) }) + [UInt8(0)]

        #if os(Windows)
            if _mktemp_s(&template, template.count) != 0 {
                throw Error(errno: errno)
            }
            if _mkdir(template) != 0 {
                throw Error(errno: errno)
            }
        #else
            if mkdtemp(&template) == nil {
                #if os(Android)
                    throw Error(errno: __errno().pointee)
                #else
                    throw Error(errno: errno)
                #endif
            }
        #endif

        let path = String(decoding: template.dropLast(), as: UTF8.self)
        defer { _ = try? FileManager.default.removeItem(atPath: path) }
        return try body(path)
    }

    static func emitModule(
        _ swiftSource: String,
        moduleDir: URL,
        moduleName: String,
        config: Configuration
    ) throws {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            throw Error(description: "WITExtractor requires Foundation.Process")
        #else
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
        #endif
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
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            throw Error(description: "WITExtractor requires Foundation.Process")
        #else
            guard let config = Configuration.default else {
                throw Error(description: "Please create 'Tests/default.json'")
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

            #expect(output == expectedWIT)

            var lexer = Lexer(cursor: Lexer.Cursor(input: output))
            #expect(throws: Never.self, "Extracted WIT file is invalid") {
                try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
            }
        #endif
    }
}
