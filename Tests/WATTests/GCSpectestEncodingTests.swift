import Foundation
import Testing
import WAT
import WasmParser

#if ComponentModel
    import WasmTools
#endif

@Suite
struct GCSpectestEncodingTests {
    /// Files at the top level of the testsuite that use garbage collection.
    static var files: [String] {
        #if os(Android)
            return []
        #else
            return [
                "array.wast", "array_copy.wast", "array_fill.wast", "array_init_data.wast", "array_init_elem.wast",
                "array_new_data.wast", "array_new_elem.wast", "br_on_cast.wast", "br_on_cast_fail.wast", "extern.wast",
                "i31.wast", "ref_cast.wast", "ref_eq.wast", "ref_null.wast", "ref_test.wast", "struct.wast",
                "table_init.wast", "table_init64.wast", "tag.wast", "type-canon.wast", "type-equivalence.wast",
                "type-rec.wast", "type-subtyping.wast",
            ]
        #endif
    }

    /// GC instructions, and GC results of the script format, that WAT does not parse.
    private static let unparsedKeywords: Set<String> = [
        "struct.new", "struct.new_default", "struct.get", "struct.get_s", "struct.get_u", "struct.set",
        "array.new", "array.new_default", "array.new_fixed", "array.new_data", "array.new_elem", "array.get",
        "array.get_s", "array.get_u", "array.set", "array.len", "array.fill", "array.copy", "array.init_data",
        "array.init_elem", "ref.test", "ref.cast", "br_on_cast", "br_on_cast_fail", "any.convert_extern",
        "extern.convert_any", "ref.i31", "i31.get_s", "i31.get_u", "ref.eq",
        "ref.array", "ref.struct", "ref.host",
    ]

    /// Directives wasm-tools cannot parse, by the line they start on. Its text parser takes at most
    /// one supertype.
    private static let unparsedByWasmTools: [String: Set<Int>] = ["type-subtyping.wast": [954]]

    private enum Expectation {
        case valid, invalid, malformed
    }

    private static func isUnparsedKeyword(_ error: WatParserError) -> Bool {
        let prefix = "unknown instruction "
        return error.message.hasPrefix(prefix) && unparsedKeywords.contains(String(error.message.dropFirst(prefix.count)))
    }

    private static func isExpected(_ error: WatParserError, for expectation: Expectation) -> Bool {
        switch expectation {
        case .valid:
            return isUnparsedKeyword(error)
        case .invalid:
            // WAT rejects a reference to an element segment that does not exist.
            return isUnparsedKeyword(error) || error.message.hasPrefix("Invalid ElementDecl index ")
        case .malformed:
            return true
        }
    }

    private static func module(of directive: WASTDirective) -> (source: ModuleSource, expectation: Expectation)? {
        switch directive {
        case .module(let module):
            return (module.source, .valid)
        case .assertUnlinkable(let wat, _), .assertTrap(.wat(let wat), _):
            return (.text(wat), .valid)
        case .assertInvalid(let module, _):
            return (module.source, .invalid)
        case .assertMalformed(let module, _):
            return (module.source, .malformed)
        default:
            return nil
        }
    }

    private static func encodeAndDecode(_ source: ModuleSource, features: WasmFeatureSet) throws -> [UInt8] {
        let bytes = try TestSupport.encode(source, features: features)
        var parser = WasmParser.Parser(bytes: bytes, features: features)
        while let payload = try parser.parseNext() {
            guard case .codeSection(let codes) = payload else { continue }
            for code in codes {
                var expression = ExpressionParser(code: code)
                while try expression.parse() != nil {}
            }
        }
        return bytes
    }

    @Test(arguments: Self.files)
    func roundTripsAndMatchesWasmTools(file: String) throws {
        let url = Spectest.path(file)
        let source = try String(contentsOf: url, encoding: .utf8)
        var features = Spectest.deriveFeatureSet(wast: url)
        features.formUnion([.gc, .functionReferences])

        var wast = try parseWAST(source, features: features)
        var starts: [Int] = []
        var encoded: [(start: Int, bytes: [UInt8])] = []
        while let (result, location) = wast.nextDirectiveResult() {
            let start = location.computeLineAndColumn().line
            starts.append(start)
            let directive: WASTDirective
            switch result {
            case .success(let parsed):
                directive = parsed
            case .failure(let failure):
                if !Self.isUnparsedKeyword(failure.error) {
                    Issue.record("\(file):\(start): \(failure.error)")
                }
                continue
            }
            guard let (module, expectation) = Self.module(of: directive) else { continue }
            do {
                let bytes = try Self.encodeAndDecode(module, features: features)
                switch (expectation, module) {
                case (.malformed, _):
                    Issue.record("\(file):\(start): a malformed module encoded and decoded")
                case (_, .binary):
                    break
                default:
                    encoded.append((start, bytes))
                }
            } catch let error as WatParserError {
                if !Self.isExpected(error, for: expectation) {
                    Issue.record("\(file):\(start): \(error)")
                }
            } catch {
                if expectation != .malformed {
                    Issue.record("\(file):\(start): \(error)")
                }
            }
        }
        #if ComponentModel
            if !encoded.isEmpty {
                try Self.expectWasmToolsEncoding(of: encoded, starts: starts, file: file, source: source)
            }
        #endif
    }

    #if ComponentModel
        private static func expectWasmToolsEncoding(
            of encoded: [(start: Int, bytes: [UInt8])], starts: [Int], file: String, source: String
        ) throws {
            let unparsed = unparsedByWasmTools[file] ?? []
            var lines = source.split(separator: "\n", omittingEmptySubsequences: false)
            for start in unparsed {
                try #require(starts.contains(start), "\(file):\(start) in unparsedByWasmTools does not start a directive")
                let end = starts.first { $0 > start } ?? lines.count + 1
                for index in (start - 1)..<(end - 1) {
                    lines[index] = ""
                }
            }
            let (json, wasmFiles) = try wast2json(wastContent: Array(lines.joined(separator: "\n").utf8), wastFileName: file)
            for module in encoded where !unparsed.contains(module.start) {
                let end = starts.first { $0 > module.start } ?? Int.max
                let filenames = json.commands.filter { (module.start..<end).contains($0.line) }
                    .compactMap(\.filename).filter { $0.hasSuffix(".wasm") }
                guard filenames.count == 1, let reference = wasmFiles[filenames[0]] else {
                    Issue.record("\(file):\(module.start): wasm-tools wrote \(filenames.count) modules for this directive")
                    continue
                }
                let actual = try comparedSections(module.bytes)
                let expected = try comparedSections(reference)
                let differing = Set(actual.keys).union(expected.keys).filter { actual[$0] != expected[$0] }.sorted()
                #expect(differing.isEmpty, "\(file):\(module.start): sections \(differing) differ from wasm-tools")
            }
        }

        private static func comparedSections(_ bytes: [UInt8]) throws -> [UInt8: [UInt8]] {
            var sections: [UInt8: [UInt8]] = [:]
            // WAT picks a different element segment form from wasm-tools.
            for section in try TestSupport.sections(in: bytes) where section.id != 0 && section.id != 9 {
                sections[section.id] = Array(bytes[section.content])
            }
            return sections
        }
    #endif
}
