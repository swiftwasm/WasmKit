import Foundation
import Testing
import WasmParser

@testable import WAT

@Suite
struct EncoderTests {

    // MARK: - Constants

    private static let wast2jsonFeatures = [
        "--enable-memory64",
        "--enable-tail-call",
        "--enable-threads",
    ]

    // MARK: - Supporting Types

    struct CompatibilityTestStats {
        var run: Int = 0
        var failed: Set<String> = []
    }

    // MARK: - Error Diagnostics

    /// Prints the relevant section of the WAST file around the error line
    private static func dumpWastFileContext(wastFile: URL, location: Location, contextLines: Int = 3) -> String {
        guard let wastContent = try? String(contentsOf: wastFile, encoding: .utf8) else {
            return ""
        }
        let lines = wastContent.components(separatedBy: .newlines)
        let (line, _) = location.computeLineAndColumn()
        let startLine = max(1, line - contextLines)
        let endLine = min(lines.count, line + contextLines)

        var context = ""
        for i in (startLine - 1)..<endLine {
            let lineNum = i + 1
            let prefix = lineNum == line ? ">>> " : "    "
            let lineContent = i < lines.count ? lines[i] : ""
            context += "\(prefix)\(String(format: "%4d", lineNum)): \(lineContent)\n"
        }
        return context
    }

    /// Prints WAST file context if error contains line number information
    private static func printErrorContext(wastFile: URL, error: Error) {
        if let error = error as? WatParserError, let location = error.location {
            print("--- \(wastFile.path):\(error.description) ---")
            print(dumpWastFileContext(wastFile: wastFile, location: location))
            print("--- End of context ---\n")
        }
    }

    // MARK: - Compatibility Checking

    func checkWabtCompatibility(
        wast: URL, json: URL, stats parentStats: inout CompatibilityTestStats,
    ) throws {
        var stats = parentStats
        defer { parentStats = stats }

        let watModules = try parseWastFile(wast: wast, stats: &stats)
        guard FileManager.default.fileExists(atPath: json.path) else {
            print("Skipping binary comparison because the oracle file (\(json.path)) does not exist.")
            return
        }

        let moduleBinaryFiles = try Spectest.moduleFiles(json: json)
        try compareModules(
            watModules: watModules,
            moduleBinaryFiles: moduleBinaryFiles,
            wast: wast,
            stats: &stats,
        )
    }

    // MARK: - WAST File Parsing

    private func parseWastFile(
        wast: URL,
        stats: inout CompatibilityTestStats,
    ) throws -> [ModuleDirective] {
        func recordFail() {
            stats.failed.insert(wast.lastPathComponent)
        }

        var parser = WastParser(
            try String(contentsOf: wast),
            features: Spectest.deriveFeatureSet(wast: wast)
        )
        var watModules: [ModuleDirective] = []

        while let directive = try parser.nextDirective() {
            switch directive {
            case .module(let moduleDirective):
                watModules.append(moduleDirective)
            case .assertMalformed(let module, let message):
                try validateMalformedModule(
                    module: module,
                    message: message,
                    wast: wast,
                    recordFail: recordFail,
                )
            default:
                break
            }
        }
        return watModules
    }

    private func validateMalformedModule(
        module: ModuleDirective,
        message: String,
        wast: URL,
        recordFail: () -> Void
    ) throws {
        let diagnostic: () -> Comment = {
            let (line, column) = module.location.computeLineAndColumn()
            return "\(wast.path):\(line):\(column) should be malformed: \(message)\n\(Self.dumpWastFileContext(wastFile: wast, location: module.location))"
        }

        switch module.source {
        case .text(var wat):
            #expect(throws: (any Error).self, diagnostic()) {
                _ = try wat.encode()
                recordFail()
            }
        case .quote(let bytes):
            #expect(throws: (any Error).self, diagnostic()) {
                _ = try wat2wasm(String(decoding: bytes, as: UTF8.self))
                recordFail()
            }
        case .binary:
            break
        }
    }

    // MARK: - Module Comparison

    private func compareModules(
        watModules: [ModuleDirective],
        moduleBinaryFiles: [(binary: URL, name: String?)],
        wast: URL,
        stats: inout CompatibilityTestStats,
    ) throws {
        func recordFail() {
            stats.failed.insert(wast.lastPathComponent)
        }

        func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, sourceLocation: SourceLocation = #_sourceLocation) {
            #expect(lhs == rhs, sourceLocation: sourceLocation)
            if lhs != rhs {
                recordFail()
            }
        }

        assertEqual(watModules.count, moduleBinaryFiles.count)

        for (watModule, moduleFile) in zip(watModules, moduleBinaryFiles) {
            let moduleBinaryFile = moduleFile.binary
            let expectedName = moduleFile.name
            stats.run += 1
            let expectedBytes = try Array(Data(contentsOf: moduleBinaryFile))

            do {
                assertEqual(watModule.id, expectedName)
                let moduleBytes = try encodeModule(watModule: watModule)
                assertEqual(moduleBytes.count, expectedBytes.count)
                if moduleBytes.count == expectedBytes.count {
                    assertEqual(moduleBytes, expectedBytes)
                }
            } catch {
                recordFail()
                Self.printErrorContext(wastFile: wast, error: error)
            }
        }
    }

    // MARK: - Module Encoding

    private func encodeModule(watModule: ModuleDirective) throws -> [UInt8] {
        switch watModule.source {
        case .text(var watModule):
            return try encode(module: &watModule, options: .default)
        case .binary(let bytes):
            return bytes
        case .quote(let watText):
            return try wat2wasm(String(decoding: watText, as: UTF8.self))
        }
    }

    private func describeModuleSource(_ source: ModuleSource) -> String {
        switch source {
        case .text: return "text WAT module"
        case .binary: return "binary module"
        case .quote: return "quoted WAT text"
        }
    }

    // MARK: - Test Cases

    #if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
        @Test(
            arguments: Spectest.wastFiles(include: [], exclude: [])
        )
        func spectest(wastFile: URL) throws {
            guard let wast2json = TestSupport.lookupExecutable("wast2json") else {
                return  // Skip the test if wast2json is not found in PATH
            }

            var stats = CompatibilityTestStats()
            try TestSupport.withTemporaryDirectory { tempDir, shouldRetain in
                let json = makeJsonPath(from: wastFile, in: tempDir)
                try runWast2Json(wast2json: wast2json, wastFile: wastFile, json: json)

                let watModules: [ModuleDirective]

                do {
                    watModules = try parseWastFile(wast: wastFile, stats: &stats)
                } catch {
                    stats.failed.insert(wastFile.lastPathComponent)
                    shouldRetain = true
                    Self.printErrorContext(wastFile: wastFile, error: error)
                    return
                }

                let moduleBinaryFiles = try Spectest.moduleFiles(json: json)
                try compareModules(
                    watModules: watModules,
                    moduleBinaryFiles: moduleBinaryFiles,
                    wast: wastFile,
                    stats: &stats,
                )
            }

            if !stats.failed.isEmpty {
                #expect((false), "Failed test cases: \(stats.failed.sorted())")
            }
        }

        // MARK: - Test Helpers

        private func makeJsonPath(from wastFile: URL, in tempDir: String) -> URL {
            let jsonFileName = wastFile.deletingPathExtension().lastPathComponent + ".json"
            return URL(fileURLWithPath: tempDir).appendingPathComponent(jsonFileName)
        }

        private func runWast2Json(wast2json: URL, wastFile: URL, json: URL) throws {
            var arguments = [wastFile.path]
            arguments.append(contentsOf: Self.wast2jsonFeatures)
            arguments.append(contentsOf: ["-o", json.path])

            let process = try Process.run(wast2json, arguments: arguments)
            process.waitUntilExit()
        }
    #endif

    @Test
    func encodeNameSection() throws {
        let bytes = try wat2wasm(
            """
            (module
                (func $foo)
                (func)
                (func $bar)
            )
            """,
            options: EncodeOptions(nameSection: true)
        )

        var parser = WasmParser.Parser(bytes: bytes)
        var customSections: [CustomSection] = []
        while let payload = try parser.parseNext() {
            guard case .customSection(let section) = payload else {
                continue
            }
            customSections.append(section)
        }
        let nameSection = customSections.first(where: { $0.name == "name" })
        let nameParser = NameSectionParser(
            stream: StaticByteStream(bytes: nameSection?.bytes ?? [])
        )
        let names = try nameParser.parseAll()
        #expect(names.count == 1)
        guard case .functions(let functionNames) = try #require(names.first) else {
            #expect((false), "Expected functions name section")
            return
        }
        #expect(functionNames == [0: "foo", 2: "bar"])
    }
}
