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
    private static func record(wastFile: URL, error: Error) {
        if let error = error as? WatParserError, let location = error.location {
            Issue.record(
                """
                --- \(wastFile.path):\(error.description) ---
                \(dumpWastFileContext(wastFile: wastFile, location: location))
                --- End of context ---
                """)
        } else {
            Issue.record("\(wastFile.path): unknown error: \(error)")
        }
    }

    // MARK: - WAST File Parsing

    private func parseWastFile(
        wast: URL,
        stats: inout CompatibilityTestStats
    ) throws -> [ModuleDirective] {
        func recordFail() {
            stats.failed.insert(wast.lastPathComponent)
        }

        var parser = WastParser(
            try String(contentsOf: wast, encoding: .utf8),
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
                    recordFail: recordFail
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
        tempDir: String,
        stats: inout CompatibilityTestStats
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
            stats.run += 1
            let expectedBytes = try Array(Data(contentsOf: moduleFile.binary))

            do {
                // Check module name
                Self.assertEqual(
                    watModule.id,
                    moduleFile.name,
                    description: "module name",
                    watModule: watModule,
                    wast: wast,
                    recordFail: recordFail
                )

                // Encode and compare module bytes
                let moduleBytes = try encodeModule(watModule: watModule)
                try Self.compareModuleBytes(
                    expected: expectedBytes,
                    actual: moduleBytes,
                    watModule: watModule,
                    wast: wast,
                    tempDir: tempDir,
                    recordFail: recordFail
                )
            } catch {
                recordFail()
                Self.recordError(error: error, watModule: watModule, wast: wast)
            }
        }
    }

    private static func compareModuleBytes(
        expected: [UInt8],
        actual: [UInt8],
        watModule: ModuleDirective,
        wast: URL,
        tempDir: String,
        recordFail: () -> Void
    ) throws {
        let (line, column) = watModule.location.computeLineAndColumn()

        // Check size first
        #expect(actual.count == expected.count)
        guard actual.count == expected.count else {
            recordFail()
            Self.saveBinariesAndRecord(
                expected: expected,
                actual: actual,
                description: "module size mismatch (expected: \(expected.count), actual: \(actual.count))",
                watModule: watModule,
                wast: wast,
                tempDir: tempDir,
                line: line,
                column: column
            )
            return
        }

        // Check bytes
        #expect(actual == expected)
        guard actual == expected else {
            recordFail()
            Self.saveBinariesAndRecord(
                expected: expected,
                actual: actual,
                description: "module bytes mismatch",
                watModule: watModule,
                wast: wast,
                tempDir: tempDir,
                line: line,
                column: column
            )
            return
        }
    }

    private static func assertEqual<T: Equatable>(
        _ lhs: T,
        _ rhs: T,
        description: String,
        watModule: ModuleDirective,
        wast: URL,
        recordFail: () -> Void,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(lhs == rhs, sourceLocation: sourceLocation)
        guard lhs == rhs else {
            recordFail()
            let (line, column) = watModule.location.computeLineAndColumn()
            Issue.record(
                """
                --- \(wast.path):\(line):\(column): \(description) mismatch (expected: \(rhs), actual: \(lhs)) ---
                \(Self.dumpWastFileContext(wastFile: wast, location: watModule.location))
                --- End of context ---
                """)
            return
        }
    }

    private static func saveBinariesAndRecord(
        expected: [UInt8],
        actual: [UInt8],
        description: String,
        watModule: ModuleDirective,
        wast: URL,
        tempDir: String,
        line: Int,
        column: Int
    ) {
        let moduleId = watModule.id ?? "module"
        let timestamp = Int(Date().timeIntervalSince1970)
        let expectedFile = URL(fileURLWithPath: tempDir).appendingPathComponent("expected-\(moduleId)-\(line)-\(timestamp).wasm")
        let actualFile = URL(fileURLWithPath: tempDir).appendingPathComponent("actual-\(moduleId)-\(line)-\(timestamp).wasm")

        do {
            try Data(expected).write(to: expectedFile)
            try Data(actual).write(to: actualFile)

            Issue.record(
                """
                --- \(wast.path):\(line):\(column): \(description) ---
                Expected binary: \(expectedFile.path)
                Actual binary: \(actualFile.path)
                \(Self.dumpWastFileContext(wastFile: wast, location: watModule.location))
                --- End of context ---
                """)
        } catch {
            Issue.record(
                """
                --- \(wast.path):\(line):\(column): \(description) ---
                Failed to save binary files: \(error)
                \(Self.dumpWastFileContext(wastFile: wast, location: watModule.location))
                --- End of context ---
                """)
        }
    }

    private static func recordError(error: Error, watModule: ModuleDirective, wast: URL) {
        let (line, column) = watModule.location.computeLineAndColumn()
        Issue.record(
            """
            --- \(wast.path):\(line):\(column): \(error) ---
            \(Self.dumpWastFileContext(wastFile: wast, location: watModule.location))
            --- End of context ---
            """)
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
                    Self.record(wastFile: wastFile, error: error)
                    return
                }

                let moduleBinaryFiles = try Spectest.moduleFiles(json: json)
                do {
                    try compareModules(
                        watModules: watModules,
                        moduleBinaryFiles: moduleBinaryFiles,
                        wast: wastFile,
                        tempDir: tempDir,
                        stats: &stats
                    )
                } catch {
                    stats.failed.insert(wastFile.lastPathComponent)
                    shouldRetain = true
                    Self.record(wastFile: wastFile, error: error)
                }

                if !stats.failed.isEmpty {
                    Issue.record("Failed test cases: \(stats.failed.sorted())")
                    shouldRetain = true
                }
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
            Issue.record("Expected functions name section")
            return
        }
        #expect(functionNames == [0: "foo", 2: "bar"])
    }
}
