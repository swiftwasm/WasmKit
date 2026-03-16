import Foundation
import Testing
import WASTRunner
import WAT
import WasmParser

@Suite
struct ParseOnlyTests {
    private static func simdWastFiles() throws -> [URL] {
        #if os(Android)
            return []
        #else
            return try FileManager.default.contentsOfDirectory(
                at: Spectest.testsuitePath,
                includingPropertiesForKeys: nil
            ).filter { url in
                url.pathExtension == "wast" && url.lastPathComponent.starts(with: "simd_")
                    && !UnsupportedSpectests.affectedFiles.contains(url.lastPathComponent)
            }
        #endif
    }

    /// Files at the top level of the testsuite with directives WasmKit cannot run yet. The spec
    /// tests skip those directives, so this decodes their modules instead.
    private static var unsupportedWastFiles: [URL] {
        #if os(Android)
            return []
        #else
            return UnsupportedSpectests.affectedFiles.filter { !$0.contains("/") }.map(Spectest.path)
        #endif
    }

    private func parseAllModulesInWast(_ source: String, features: WasmFeatureSet, skip: [Int: String] = [:]) throws {
        var wast = try parseWAST(source, features: features)
        while let (result, location) = wast.nextDirectiveResult() {
            if !skip.isEmpty, skip[location.computeLineAndColumn().line] != nil { continue }
            switch try result.get() {
            case .module(let module):
                try parseWasmBytes(TestSupport.encode(module.source, features: features), features: features)
            case .assertUnlinkable(let wat, _):
                try parseWasmBytes(TestSupport.encode(.text(wat), features: features), features: features)
            default:
                break
            }
        }
    }

    private func parseWasmBytes(_ bytes: [UInt8], features: WasmFeatureSet) throws {
        var parser = WasmParser.Parser(bytes: bytes, features: features)
        while let payload = try parser.parseNext() {
            guard case .codeSection(let codes) = payload else { continue }
            for code in codes {
                var expression = ExpressionParser(code: code)
                while try expression.parse() != nil {}
            }
        }
    }

    @Test(arguments: try ParseOnlyTests.simdWastFiles())
    func parseOnlySimdSpec(wastFile: URL) throws {
        let source = try String(contentsOf: wastFile, encoding: .utf8)
        var features = Spectest.deriveFeatureSet(wast: wastFile)
        features.insert(.simd)
        try parseAllModulesInWast(source, features: features)
    }

    @Test(arguments: ParseOnlyTests.unsupportedWastFiles)
    func parseOnlyUnsupportedSpec(wastFile: URL) throws {
        let source = try String(contentsOf: wastFile, encoding: .utf8)
        let skip = Spectest.skippedDirectives[wastFile.lastPathComponent] ?? [:]
        var features = Spectest.deriveFeatureSet(wast: wastFile)
        // Wasm 3.0 includes typed function references, which only some files get for wast2json.
        features.insert(.functionReferences)
        try parseAllModulesInWast(source, features: features, skip: skip)
    }
}
