import Foundation
import Testing
import WasmParser

@testable import WAT

@Suite
struct EncoderTests {

    struct CompatibilityTestStats {
        var run: Int = 0
        var failed: Set<String> = []
    }

    func checkWabtCompatibility(
        wast: URL, json: URL, stats parentStats: inout CompatibilityTestStats,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        var stats = parentStats
        defer { parentStats = stats }
        func recordFail(wasmBinaryName: String? = nil) {
            stats.failed.insert(wasmBinaryName ?? wast.lastPathComponent)
        }
        func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, sourceLocation: SourceLocation = #_sourceLocation) {
            #expect(lhs == rhs, sourceLocation: sourceLocation)
            if lhs != rhs {
                recordFail()
            }
        }

        var parser = WastParser(try String(contentsOf: wast), features: Spectest.deriveFeatureSet(wast: wast))
        var watModules: [ModuleDirective] = []

        while let directive = try parser.nextDirective() {
            switch directive {
            case .module(let moduleDirective):
                watModules.append(moduleDirective)
            case .assertMalformed(let module, let message):
                let diagnostic: () -> Comment = {
                    let (line, column) = module.location.computeLineAndColumn()
                    return "\(wast.path):\(line):\(column) should be malformed: \(message)"
                }
                switch module.source {
                case .text(var wat):
                    #expect(throws: (any Error).self, diagnostic(), sourceLocation: sourceLocation) {
                        _ = try wat.encode()
                        recordFail()
                    }
                case .quote(let bytes):
                    #expect(throws: (any Error).self, diagnostic(), sourceLocation: sourceLocation) {
                        _ = try wat2wasm(String(decoding: bytes, as: UTF8.self))
                        recordFail()
                    }
                case .binary: break
                }
            default: break
            }
        }
        guard FileManager.default.fileExists(atPath: json.path) else {
            print("Skipping binary comparison because the oracle file (\(json.path)) does not exist.")
            return
        }
        let moduleBinaryFiles = try Spectest.moduleFiles(json: json)
        assertEqual(watModules.count, moduleBinaryFiles.count)

        for (watModule, (moduleBinaryFile, expectedName)) in zip(watModules, moduleBinaryFiles) {
            func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, sourceLocation: SourceLocation = #_sourceLocation) {
                #expect(lhs == rhs, sourceLocation: sourceLocation)
                if lhs != rhs {
                    recordFail(wasmBinaryName: moduleBinaryFile.lastPathComponent)
                }
            }
            stats.run += 1
            let moduleBytes: [UInt8]
            let expectedBytes = try Array(Data(contentsOf: moduleBinaryFile))
            do {
                assertEqual(watModule.id, expectedName)
                switch watModule.source {
                case .text(var watModule):
                    moduleBytes = try encode(module: &watModule, options: .default)
                case .binary(let bytes):
                    moduleBytes = bytes
                case .quote(let watText):
                    moduleBytes = try wat2wasm(String(decoding: watText, as: UTF8.self))
                }
            } catch {
                recordFail()
                #expect((false), "Error while encoding \(moduleBinaryFile.lastPathComponent): \(error)")
                return
            }
            if moduleBytes != expectedBytes {
                recordFail()
            }
            assertEqual(moduleBytes.count, expectedBytes.count)
            if moduleBytes.count == expectedBytes.count {
                assertEqual(moduleBytes, expectedBytes)
            }
        }
    }

    #if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
        @Test(
            arguments: Spectest.wastFiles(include: ["const.wast"], exclude: [])
        )
        func spectest(wastFile: URL) throws {
            guard let wast2json = TestSupport.lookupExecutable("wast2json") else {
                return  // Skip the test if wast2json is not found in PATH
            }

            var stats = CompatibilityTestStats()
            try TestSupport.withTemporaryDirectory { tempDir, shouldRetain in
                let jsonFileName = wastFile.deletingPathExtension().lastPathComponent + ".json"
                let json = URL(fileURLWithPath: tempDir).appendingPathComponent(jsonFileName)

                let wast2jsonProcess = try Process.run(
                    wast2json,
                    arguments: [
                        wastFile.path,
                        "--enable-memory64",
                        "--enable-tail-call",
                        "-o", json.path,
                    ]
                )
                wast2jsonProcess.waitUntilExit()

                do {
                    try checkWabtCompatibility(wast: wastFile, json: json, stats: &stats)
                } catch {
                    stats.failed.insert(wastFile.lastPathComponent)
                    shouldRetain = true
                    #expect((false), "Error while checking compatibility between \(wastFile) and \(json.path): \(error)")
                }
            }

            if !stats.failed.isEmpty {
                #expect((false), "Failed test cases: \(stats.failed.sorted())")
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
            #expect((false), "Expected functions name section")
            return
        }
        #expect(functionNames == [0: "foo", 2: "bar"])
    }

    @Test
    func encodeFloat() throws {
        let wat = """
            (module
              (type (;0;) (func (result f32)))
              (export "f" (func 0))
              (func (;0;) (type 0) (result f32)
                f32.const 0x1.p-149
              )
            )
            """

        let module = try wat2wasm(wat)

        #expect(
            module == [
                0x0, 0x61, 0x73, 0x6d, 0x1, 0x0, 0x0, 0x0, 0x1, 0x5, 0x1, 0x60, 0x0, 0x1, 0x7d, 0x3, 0x2, 0x1,
                0x0, 0x7, 0x5, 0x1, 0x1, 0x66, 0x0, 0x0, 0xa, 0x9, 0x1, 0x7, 0x0, 0x43, 0x1, 0x0, 0x0, 0x0, 0xb,
            ])
    }
}
