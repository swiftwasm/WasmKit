import Foundation
import Testing
import WasmParser

@testable import WAT

#if ComponentModel
    import WasmTools
#endif

@Suite
struct EncoderTests {

    // MARK: - Constants

    // Memory64, tail calls, extended constant expressions and exceptions are
    // enabled by default since wabt 1.0.42, which also removed their flags.
    private static let wast2jsonFeatures = [
        "--enable-threads"
    ]

    /// Files whose output wast2json cannot produce or encodes differently.
    private static let excludedFiles: [String] = [
        // WAT does not parse custom annotations.
        "annotations.wast",
        // wast2json 1.0.42 cannot parse these: an `exnref` result, and a global read from a table
        // initializer. wasm-tools encodes them differently from wabt, whose choices WAT follows: it
        // keeps an empty `else`, and writes `(elem funcref ...)` in a form that leaves it nullable.
        "try_table.wast", "elem.wast",
        // wast2json writes no value type for a relaxed-SIMD `either` result.
        "i16x8_relaxed_q15mulr_s.wast", "i8x16_relaxed_swizzle.wast", "relaxed_dot_product.wast",
        "relaxed_laneselect.wast", "relaxed_madd_nmadd.wast", "relaxed_min_max.wast",
        // Written before Wasm 3.0 made text-format limits u64; the top-level memory.wast
        // expects an out-of-range limit to fail validation instead.
        "proposals/threads/memory.wast",
    ]

    /// Files with GC types, which wast2json 1.0.42 cannot parse, so they are compared with
    /// wasm-tools instead.
    private static let wasmToolsFiles: Set<String> = [
        "array.wast", "array_copy.wast", "array_fill.wast", "array_init_data.wast", "array_init_elem.wast",
        "array_new_data.wast", "array_new_elem.wast", "br_on_cast.wast", "br_on_cast_fail.wast", "extern.wast",
        "i31.wast", "ref_cast.wast", "ref_eq.wast", "ref_null.wast", "ref_test.wast", "struct.wast", "tag.wast",
        "type-canon.wast", "type-equivalence.wast", "type-rec.wast", "type-subtyping.wast",
    ]

    // MARK: - Supporting Types

    /// A module that the reference tool encoded.
    struct ReferenceModule {
        let name: String?
        /// `nil` for a module the tool wrote out as text.
        let bytes: [UInt8]?
    }

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

    /// The module directives in `wast`, and the line every directive starts on.
    private func parseWastFile(
        wast: URL,
        stats: inout CompatibilityTestStats
    ) throws -> (modules: [ModuleDirective], starts: [Int]) {
        func recordFail() {
            stats.failed.insert(wast.lastPathComponent)
        }

        var script = try parseWAST(
            try String(contentsOf: wast, encoding: .utf8),
            features: Spectest.deriveFeatureSet(wast: wast)
        )
        let skip = Self.skippedDirectives(in: wast)
        var watModules: [ModuleDirective] = []
        var starts: [Int] = []

        while let (result, location) = script.nextDirectiveResult() {
            let line = location.computeLineAndColumn().line
            starts.append(line)
            guard skip[line] == nil else { continue }
            switch try result.get() {
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
        return (watModules, starts)
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
        case .text(let wat):
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

    private static func skippedDirectives(in wast: URL) -> [Int: String] {
        Spectest.isTopLevel(wast) ? Spectest.skippedDirectives[wast.lastPathComponent] ?? [:] : [:]
    }

    // MARK: - Module Comparison

    private func compareModules(
        watModules: [ModuleDirective],
        referenceModules: [ReferenceModule],
        usesWasmTools: Bool,
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

        assertEqual(watModules.count, referenceModules.count)

        for (watModule, moduleFile) in zip(watModules, referenceModules) {
            // wasm-tools writes a quoted module out as text.
            guard let expectedBytes = moduleFile.bytes else { continue }
            stats.run += 1

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

                if usesWasmTools {
                    // wasm-tools always writes a name section.
                    let moduleBytes = try TestSupport.encode(watModule.source, options: EncodeOptions(nameSection: true))
                    if try Self.wasmToolsParts(of: moduleBytes) != Self.wasmToolsParts(of: expectedBytes) {
                        recordFail()
                        let (line, column) = watModule.location.computeLineAndColumn()
                        Self.saveBinariesAndRecord(
                            expected: expectedBytes, actual: moduleBytes, description: "module differs from wasm-tools",
                            watModule: watModule, wast: wast, tempDir: tempDir, line: line, column: column)
                    }
                    continue
                }

                // Encode and compare module bytes
                let moduleBytes = try TestSupport.encode(watModule.source)
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

    /// A part of a module compared with wasm-tools.
    private enum WasmToolsPart: Equatable {
        case section(id: UInt8, content: ArraySlice<UInt8>)
        /// wasm-tools picks other element segment forms than wabt, whose choices WAT follows, so
        /// segments are compared decoded.
        case elements([ElementSegment])
        case nameSubsection(id: UInt8, content: ArraySlice<UInt8>)
    }

    /// The parts of `bytes` that WAT and wasm-tools encode alike.
    private static func wasmToolsParts(of bytes: [UInt8]) throws -> [WasmToolsPart] {
        var parts: [WasmToolsPart] = []
        for (id, content) in try sections(of: bytes[8...]) {
            switch id {
            case 9:
                var parser = WasmParser.Parser(bytes: bytes, features: .all)
                while let payload = try parser.parseNext() {
                    if case .elementSection(let elements) = payload {
                        parts.append(.elements(elements))
                    }
                }
            case 0 where content.starts(with: [4] + Array("name".utf8)):
                // WAT does not write module (0) or tag (11) names yet.
                for (id, subsection) in try sections(of: content.dropFirst(5)) where id != 0 && id != 11 {
                    parts.append(.nameSubsection(id: id, content: subsection))
                }
            default:
                parts.append(.section(id: id, content: content))
            }
        }
        return parts
    }

    /// The id and content of each section, or name subsection, in `bytes`.
    private static func sections(of bytes: ArraySlice<UInt8>) throws -> [(id: UInt8, content: ArraySlice<UInt8>)] {
        var sections: [(id: UInt8, content: ArraySlice<UInt8>)] = []
        var index = bytes.startIndex
        while index < bytes.endIndex {
            let id = bytes[index]
            index += 1
            var size = 0
            var shift = 0
            while true {
                let byte = bytes[index]
                index += 1
                size |= Int(byte & 0x7F) << shift
                shift += 7
                if byte < 0x80 { break }
            }
            sections.append((id, bytes[index..<(index + size)]))
            index += size
        }
        return sections
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

    // MARK: - Test Cases

    #if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
        @Test(
            arguments: Spectest.wastFiles(include: [], exclude: Self.excludedFiles)
        )
        func spectest(wastFile: URL) throws {
            var stats = CompatibilityTestStats()
            try TestSupport.withTemporaryDirectory { tempDir, shouldRetain in
                let watModules: [ModuleDirective]
                let starts: [Int]
                do {
                    (watModules, starts) = try parseWastFile(wast: wastFile, stats: &stats)
                } catch {
                    stats.failed.insert(wastFile.lastPathComponent)
                    shouldRetain = true
                    Self.record(wastFile: wastFile, error: error)
                    return
                }

                let usesWasmTools = Self.usesWasmTools(wastFile)
                guard
                    let referenceModules = try usesWasmTools
                        ? wasmToolsModules(wastFile: wastFile, starts: starts)
                        : wast2jsonModules(wastFile: wastFile, starts: starts, tempDir: tempDir)
                else {
                    return  // Skip the test if the reference tool is not available
                }
                do {
                    try compareModules(
                        watModules: watModules,
                        referenceModules: referenceModules,
                        usesWasmTools: usesWasmTools,
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

        private static func usesWasmTools(_ wastFile: URL) -> Bool {
            wastFile.deletingLastPathComponent().lastPathComponent == "gc"
                || (Spectest.isTopLevel(wastFile) && wasmToolsFiles.contains(wastFile.lastPathComponent))
        }

        /// The script in `wastFile` with the directives starting on `leftOut` blanked, keeping the
        /// line numbers. `starts` is the line every directive in the file starts on.
        private static func script(of wastFile: URL, leavingOut leftOut: [Int], starts: [Int]) throws -> String {
            var lines = try String(contentsOf: wastFile, encoding: .utf8).split(separator: "\n", omittingEmptySubsequences: false)
            for start in leftOut {
                let end = starts.first { $0 > start } ?? lines.count + 1
                for index in (start - 1)..<(end - 1) {
                    lines[index] = ""
                }
            }
            return lines.joined(separator: "\n")
        }

        /// The modules wast2json writes for `wastFile`, or `nil` if it is not in PATH.
        private func wast2jsonModules(wastFile: URL, starts: [Int], tempDir: String) throws -> [ReferenceModule]? {
            guard let wast2json = TestSupport.lookupExecutable("wast2json") else { return nil }
            var input = wastFile
            let skipped = Array(Self.skippedDirectives(in: wastFile).keys)
            if !skipped.isEmpty {
                input = URL(fileURLWithPath: tempDir).appendingPathComponent(wastFile.lastPathComponent)
                try Self.script(of: wastFile, leavingOut: skipped, starts: starts).write(to: input, atomically: true, encoding: .utf8)
            }
            let json = makeJsonPath(from: wastFile, in: tempDir)
            try runWast2Json(wast2json: wast2json, wastFile: input, json: json)
            return try Spectest.moduleFiles(json: json).map {
                ReferenceModule(name: $0.name, bytes: try Array(Data(contentsOf: $0.binary)))
            }
        }

        /// The modules wasm-tools writes for `wastFile`, or `nil` without the ComponentModel trait,
        /// which runs it. `starts` is the line every directive in the file starts on.
        private func wasmToolsModules(wastFile: URL, starts: [Int]) throws -> [ReferenceModule]? {
            #if ComponentModel
                let leftOut =
                    Array(Self.skippedDirectives(in: wastFile).keys)
                    + (Spectest.unparsedByWasmTools[wastFile.lastPathComponent] ?? [:]).keys
                let script = try Self.script(of: wastFile, leavingOut: leftOut, starts: starts)
                let (json, wasmFiles) = try wast2json(wastContent: Array(script.utf8), wastFileName: wastFile.lastPathComponent)
                return json.commands.filter { $0.type == "module" }.map {
                    // wasm-tools names a module without its `$`, and writes a quoted module out as text.
                    ReferenceModule(
                        name: $0.name.map { "$" + $0 },
                        bytes: $0.filename.flatMap { $0.hasSuffix(".wasm") ? wasmFiles[$0] : nil })
                }
            #else
                return nil
            #endif
        }

        // MARK: - Test Helpers

        private func makeJsonPath(from wastFile: URL, in tempDir: String) -> URL {
            let jsonFileName = wastFile.deletingPathExtension().lastPathComponent + ".json"
            return URL(fileURLWithPath: tempDir).appendingPathComponent(jsonFileName)
        }

        private func runWast2Json(wast2json: URL, wastFile: URL, json: URL) throws {
            var arguments = [wastFile.path]
            arguments.append(contentsOf: Self.wast2jsonFeatures)
            // With function references enabled, wast2json writes element segments as
            // expressions rather than function indices, so only the files that need it get it.
            if Spectest.usesFunctionReferences(wastFile) {
                arguments.append("--enable-function-references")
            }
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
        var nameParser = NameSectionParser(
            stream: StaticByteStreamSource(bytes: nameSection?.bytes ?? [])
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
        let sectionBytes = Array(nameBytes ?? [])
        var nameParser = NameSectionParser(
            stream: StaticByteStreamSource(bytes: sectionBytes)
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
}
