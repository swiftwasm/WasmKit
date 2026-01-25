import Foundation
import Testing
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
            }
        #endif
    }

    private func parseAllModulesInWast(_ source: String, features: WasmFeatureSet) throws {
        var wast = try parseWAST(source, features: features)
        while let (directive, _) = try wast.nextDirective() {
            switch directive {
            case .module(let module):
                try parseModuleSource(module.source, features: features)
            case .assertUnlinkable(let wat, _):
                var wat = wat
                let bytes = try wat.encode(options: .default)
                try parseWasmBytes(bytes, features: features)
            default:
                break
            }
        }
    }

    private func parseModuleSource(_ moduleSource: ModuleSource, features: WasmFeatureSet) throws {
        let bytes: [UInt8]
        switch moduleSource {
        case .binary(let b):
            bytes = b
        case .quote(let text):
            bytes = try wat2wasm(String(decoding: text, as: UTF8.self), features: features)
        case .text(var wat):
            bytes = try wat.encode(options: .default)
        }
        try parseWasmBytes(bytes, features: features)
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
