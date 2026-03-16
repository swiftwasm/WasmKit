import Foundation
import Testing
import WAT
import WasmParser
import WasmTypes

@testable import WAT

#if ComponentModel
    import WasmTools
#endif

@Suite
struct EncoderTests {

    // MARK: - Constants

    private static let wast2jsonFeatures = [
        "--enable-memory64",
        "--enable-tail-call",
        "--enable-threads",
        "--enable-annotations",
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
                // Validate UTF-8 encoding before attempting to parse as WAT text.
                // String(decoding:as:UTF8.self) silently replaces invalid bytes,
                // masking malformed UTF-8 that the spec expects to be rejected.
                guard let text = String(bytes: bytes, encoding: .utf8) else {
                    throw WatParserError("malformed UTF-8 encoding", location: nil)
                }
                _ = try wat2wasm(text)
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
        stats: inout CompatibilityTestStats,
        encodeOptions: EncodeOptions = .default,
        stripModuleNamePrefix: Bool = false
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
                // Check module name (strip "$" prefix when comparing against WasmTools)
                let actualName: String?
                if stripModuleNamePrefix {
                    actualName = watModule.moduleName?.nameValue
                } else {
                    actualName = watModule.id
                }
                Self.assertEqual(
                    actualName,
                    moduleFile.name,
                    description: "module name",
                    watModule: watModule,
                    wast: wast,
                    recordFail: recordFail
                )

                // Encode and compare module bytes
                let moduleBytes = try encodeModule(watModule: watModule, options: encodeOptions)
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

    private func encodeModule(watModule: ModuleDirective, options: EncodeOptions = .default) throws -> [UInt8] {
        switch watModule.source {
        case .text(var wat):
            // The WAST parser consumes the module $id before parsing the WAT body,
            // so inject it back into the Wat struct for the name section encoder.
            if options.nameSection, wat.id == nil, let moduleId = watModule.id {
                wat.id = .identifier(moduleId)
            }
            return try encode(module: &wat, options: options)
        case .binary(let bytes):
            return bytes
        case .quote(let watText):
            return try WAT.wat2wasm(String(decoding: watText, as: UTF8.self), options: options)
        }
    }

    // MARK: - Test Cases

    #if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
        @Test(
            arguments: Spectest.wastFiles(
                include: [],
                exclude: [
                    // Tested separately by annotationProposal() since wast2json (WABT) doesn't support the annotations proposal
                    "annotations.wast", "token.wast", "id.wast",
                    // Tested separately by dedicated tests since wast2json doesn't support assert_malformed_custom
                    "name_annot.wast", "custom_annot.wast",
                ])
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

    #if ComponentModel
        /// Test annotation proposal files using WasmTools as reference for binary comparison.
        /// WABT's wast2json doesn't support the annotations proposal, so WasmTools is used as fallback.
        @Test(
            arguments: Spectest.wastFiles(include: ["annotations.wast", "token.wast", "id.wast"])
        )
        func annotationProposal(wastFile: URL) throws {
            var stats = CompatibilityTestStats()
            try TestSupport.withTemporaryDirectory { tempDir, shouldRetain in
                let watModules: [ModuleDirective]
                do {
                    watModules = try parseWastFile(wast: wastFile, stats: &stats)
                } catch {
                    stats.failed.insert(wastFile.lastPathComponent)
                    shouldRetain = true
                    Self.record(wastFile: wastFile, error: error)
                    return
                }

                // Use WasmTools for binary comparison
                let wastContent = try Array(Data(contentsOf: wastFile))
                let (json, wasmFiles) = try wast2json(
                    wastContent: wastContent,
                    wastFileName: wastFile.lastPathComponent
                )

                // Write reference wasm files to temp dir, skipping text-form modules
                // (WasmTools stores "module quote" forms as raw text, not compiled Wasm)
                var moduleBinaryFiles: [(binary: URL, name: String?)] = []
                for command in json.commands where command.type == "module" {
                    guard command.moduleType != "text" else { continue }
                    guard let filename = command.filename, let bytes = wasmFiles[filename] else { continue }
                    let binaryURL = URL(fileURLWithPath: tempDir).appendingPathComponent(filename)
                    try Data(bytes).write(to: binaryURL)
                    moduleBinaryFiles.append((binary: binaryURL, name: command.name))
                }

                // Filter out quote modules from our parsed modules to match
                let binaryWatModules = watModules.filter {
                    switch $0.source {
                    case .quote: return false
                    default: return true
                    }
                }

                do {
                    try compareModules(
                        watModules: binaryWatModules,
                        moduleBinaryFiles: moduleBinaryFiles,
                        wast: wastFile,
                        tempDir: tempDir,
                        stats: &stats,
                        encodeOptions: EncodeOptions(nameSection: true),
                        stripModuleNamePrefix: true
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

    @Test
    func encodeNameSectionAllSubsections() throws {
        // Module exercising all 10 name subsections (0–9)
        let bytes = try wat2wasm(
            """
            (module $testmod
                (type $mytype (func (param i32) (result i32)))
                (import "env" "imported" (func $imported (param i32)))
                (table $mytable 1 funcref)
                (memory $mymem 1)
                (global $myglob i32 (i32.const 0))
                (func $myfunc (param $p i32) (local $l i32)
                    (block $myblock
                        nop
                    )
                )
                (elem $myelem (i32.const 0) func $myfunc)
                (data $mydata (i32.const 0) "hello")
            )
            """,
            options: EncodeOptions(nameSection: true)
        )

        // Extract the name custom section bytes
        var parser = WasmParser.Parser(bytes: bytes)
        var nameBytes: ArraySlice<UInt8>?
        while let payload = try parser.parseNext() {
            if case .customSection(let section) = payload, section.name == "name" {
                nameBytes = section.bytes
            }
        }
        let sectionBytes = try #require(Array(nameBytes ?? []))
        let nameParser = NameSectionParser(
            stream: StaticByteStream(bytes: sectionBytes)
        )
        let parsed = try nameParser.parseAll()
        #expect(parsed.count == 10)

        // Collect into a lookup by discriminator for readable assertions
        var moduleName: String?
        var functionNames: NameMap?
        var localNames: [UInt32: NameMap]?
        var labelNames: [UInt32: NameMap]?
        var typeNames: NameMap?
        var tableNames: NameMap?
        var memoryNames: NameMap?
        var globalNames: NameMap?
        var elemNames: NameMap?
        var dataNames: NameMap?
        for entry in parsed {
            switch entry {
            case .moduleName(let v): moduleName = v
            case .functions(let v): functionNames = v
            case .locals(let v): localNames = v
            case .labels(let v): labelNames = v
            case .types(let v): typeNames = v
            case .tables(let v): tableNames = v
            case .memories(let v): memoryNames = v
            case .globals(let v): globalNames = v
            case .elements(let v): elemNames = v
            case .dataSegments(let v): dataNames = v
            }
        }

        #expect(moduleName == "testmod")
        #expect(functionNames == [0: "imported", 1: "myfunc"])
        #expect(localNames == [1: [0: "p", 1: "l"]])
        #expect(labelNames == [1: [0: "myblock"]])
        #expect(try #require(typeNames).values.contains("mytype"))
        #expect(tableNames == [0: "mytable"])
        #expect(memoryNames == [0: "mymem"])
        #expect(globalNames == [0: "myglob"])
        #expect(elemNames == [0: "myelem"])
        #expect(dataNames == [0: "mydata"])
    }

    /// Helper to extract the module name from the name section of a compiled Wasm binary.
    private func extractModuleName(from bytes: [UInt8]) throws -> String? {
        var parser = WasmParser.Parser(bytes: bytes)
        var nameBytes: ArraySlice<UInt8>?
        while let payload = try parser.parseNext() {
            if case .customSection(let section) = payload, section.name == "name" {
                nameBytes = section.bytes
            }
        }
        guard let sectionBytes = nameBytes else { return nil }
        let nameParser = NameSectionParser(
            stream: StaticByteStream(bytes: Array(sectionBytes))
        )
        let parsed = try nameParser.parseAll()
        for entry in parsed {
            if case .moduleName(let name) = entry {
                return name
            }
        }
        return nil
    }

    @Test
    func encodeNameAnnotation() throws {
        // @name alone
        let bytes1 = try wat2wasm(
            #"(module (@name "Modül"))"#,
            options: EncodeOptions(nameSection: true)
        )
        #expect(try extractModuleName(from: bytes1) == "Modül")

        // @name with $id — @name takes precedence
        let bytes2 = try wat2wasm(
            #"(module $moduel (@name "Modül"))"#,
            options: EncodeOptions(nameSection: true)
        )
        #expect(try extractModuleName(from: bytes2) == "Modül")
    }

    @Test
    func nameAnnotationMalformed() throws {
        // Multiple @name annotations
        #expect(throws: (any Error).self) {
            _ = try wat2wasm(#"(module (@name "M1") (@name "M2"))"#)
        }

        // Misplaced @name after module fields
        #expect(throws: (any Error).self) {
            _ = try wat2wasm(#"(module (func) (@name "M"))"#)
        }

        // Misplaced @name inside a field
        #expect(throws: (any Error).self) {
            _ = try wat2wasm(#"(module (start $f (@name "M")) (func $f))"#)
        }
    }

    @Test
    func nameAnnotationWast() throws {
        let wastContent = """
            (module (@name "Modül"))
            (module $moduel (@name "Modül"))
            (assert_malformed_custom
              (module quote "(module (@name \\"M1\\") (@name \\"M2\\"))")
              "@name annotation: multiple module"
            )
            (assert_malformed_custom
              (module quote "(module (func) (@name \\"M\\"))")
              "misplaced @name annotation"
            )
            """
        var wast = try parseWAST(wastContent)
        var moduleCount = 0
        var assertCount = 0
        while let (directive, _) = try wast.nextDirective() {
            switch directive {
            case .module:
                moduleCount += 1
            case .assertMalformed(let module, _):
                assertCount += 1
                // Verify the quoted module actually fails to parse
                if case .quote(let bytes) = module.source {
                    if let text = String(bytes: bytes, encoding: .utf8) {
                        #expect(throws: (any Error).self) {
                            _ = try wat2wasm(text)
                        }
                    }
                }
            default:
                break
            }
        }
        #expect(moduleCount == 2)
        #expect(assertCount == 2)
    }

    /// Test `@custom` annotation parsing and encoding.
    /// wasm-tools doesn't support `assert_malformed_custom`, so we validate directly
    /// rather than comparing against reference binaries.
    @Test
    func customAnnotationWast() throws {
        let wastFile = try #require(Spectest.wastFiles(include: ["custom_annot.wast"]).first)
        // parseWastFile validates all assert_malformed_custom directives internally
        var stats = CompatibilityTestStats()
        let watModules = try parseWastFile(wast: wastFile, stats: &stats)
        #expect(stats.failed.isEmpty)

        // Verify that non-quote modules encode successfully
        var encodedCount = 0
        for watModule in watModules {
            if case .text(var wat) = watModule.source {
                _ = try wat.encode()
                encodedCount += 1
            }
        }
        #expect(encodedCount > 0)
    }

    // MARK: - @custom Binary Output Tests

    /// Find all custom sections (id=0) in a Wasm binary, returning (name, content) pairs.
    private func findCustomSections(in bytes: [UInt8]) throws -> [(name: String, content: [UInt8])] {
        var sections: [(name: String, content: [UInt8])] = []
        var offset = 8  // skip magic + version
        while offset < bytes.count {
            let sectionId = bytes[offset]
            offset += 1
            // Read section size as LEB128
            var size: Int = 0
            var shift = 0
            while offset < bytes.count {
                let byte = bytes[offset]
                offset += 1
                size |= Int(byte & 0x7F) << shift
                shift += 7
                if byte & 0x80 == 0 { break }
            }
            let sectionEnd = offset + size
            if sectionId == 0 {
                // Custom section: read name, rest is content
                var nameLen: Int = 0
                var nameShift = 0
                while offset < bytes.count {
                    let byte = bytes[offset]
                    offset += 1
                    nameLen |= Int(byte & 0x7F) << nameShift
                    nameShift += 7
                    if byte & 0x80 == 0 { break }
                }
                let name = String(decoding: bytes[offset..<(offset + nameLen)], as: UTF8.self)
                offset += nameLen
                let content = Array(bytes[offset..<sectionEnd])
                sections.append((name: name, content: content))
            }
            offset = sectionEnd
        }
        return sections
    }

    @Test
    func customAnnotationBasicEncoding() throws {
        // Verify custom section appears in binary output
        let bytes = try wat2wasm(#"(module (@custom "test-section" "hello"))"#)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 1)
        #expect(sections[0].name == "test-section")
        #expect(sections[0].content == Array("hello".utf8))
    }

    @Test
    func customAnnotationEmptyContent() throws {
        let bytes = try wat2wasm(#"(module (@custom "empty"))"#)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 1)
        #expect(sections[0].name == "empty")
        #expect(sections[0].content.isEmpty)
    }

    @Test
    func customAnnotationEmptyName() throws {
        let bytes = try wat2wasm(#"(module (@custom "" "data"))"#)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 1)
        #expect(sections[0].name == "")
        #expect(sections[0].content == Array("data".utf8))
    }

    @Test
    func customAnnotationMultipleStrings() throws {
        // Multiple string literals should be concatenated
        let bytes = try wat2wasm(#"(module (@custom "cat" "ab" "cd" "ef"))"#)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 1)
        #expect(sections[0].content == Array("abcdef".utf8))
    }

    @Test
    func customAnnotationOrdering() throws {
        // Multiple custom sections should preserve source order
        let bytes = try wat2wasm(
            """
            (module
                (@custom "first" "1")
                (@custom "second" "2")
                (@custom "third" "3")
            )
            """)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 3)
        #expect(sections[0].name == "first")
        #expect(sections[1].name == "second")
        #expect(sections[2].name == "third")
    }

    @Test
    func customAnnotationPlacement() throws {
        // Custom sections with placement directives should appear at the right positions
        // relative to standard sections in the binary.
        let bytes = try wat2wasm(
            """
            (module
                (type (func))
                (@custom "after-type" (after type) "AT")
                (@custom "before-func" (before func) "BF")
                (func (type 0))
                (@custom "after-global" (after global) "AG")
                (global i32 (i32.const 0))
                (@custom "unplaced" "UP")
            )
            """)
        let sections = try findCustomSections(in: bytes)
        // Verify all custom sections are present
        let names = sections.map(\.name)
        #expect(names.contains("after-type"))
        #expect(names.contains("before-func"))
        #expect(names.contains("after-global"))
        #expect(names.contains("unplaced"))

        // Verify ordering: after-type and before-func should both appear
        // between type section and function section, with after-type first
        let atIdx = try #require(names.firstIndex(of: "after-type"))
        let bfIdx = try #require(names.firstIndex(of: "before-func"))
        #expect(atIdx < bfIdx)
    }

    @Test
    func customAnnotationDuplicateNames() throws {
        // Multiple custom sections with the same name are valid
        let bytes = try wat2wasm(
            """
            (module
                (@custom "dup" "a")
                (@custom "dup" "b")
                (@custom "dup" "c")
            )
            """)
        let sections = try findCustomSections(in: bytes)
        #expect(sections.count == 3)
        #expect(sections.allSatisfy { $0.name == "dup" })
        #expect(sections[0].content == Array("a".utf8))
        #expect(sections[1].content == Array("b".utf8))
        #expect(sections[2].content == Array("c".utf8))
    }

    @Test
    func customAnnotationMalformedCases() throws {
        // Missing section name
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom))"#) }
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom 4))"#) }
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom bla))"#) }

        // Malformed placement
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom "x" here))"#) }
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom "x" (type)))"#) }
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom "x" (aft type)))"#) }
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (@custom "x" (before types)))"#) }

        // Misplaced inside module fields
        #expect(throws: (any Error).self) { _ = try wat2wasm(#"(module (func (@custom "x")))"#) }
    }
}
