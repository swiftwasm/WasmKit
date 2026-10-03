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

    private func parseAllModulesInWast(_ source: String, features: WasmFeatureSet) throws {
        var wast = try parseWAST(source, features: features)
        while let (directive, _) = try wast.nextDirective() {
            switch directive {
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
        while (try parser.parseNext()) != nil {}
    }

    @Test(arguments: try ParseOnlyTests.simdWastFiles())
    func parseOnlySimdSpec(wastFile: URL) throws {
        let source = try String(contentsOf: wastFile, encoding: .utf8)
        var features = Spectest.deriveFeatureSet(wast: wastFile)
        features.insert(.simd)
        try parseAllModulesInWast(source, features: features)
    }
}
