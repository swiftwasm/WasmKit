import Foundation
import Testing
import WAT
import WasmKit
import WasmParser

@testable import WASTRunner

@Suite
struct SpectestTests {
    static let projectDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let testsuite =
        projectDir
        .appendingPathComponent("Vendor/testsuite")
    /// Whether the default engine can back a shared memory here (requires mprotect: not ASan,
    /// not token threading, 64-bit macOS/Linux).
    static let sharedMemorySupported: Bool = {
        // A shared memory type only validates with the threads feature.
        var configuration = EngineConfiguration()
        configuration.features.insert(.threads)
        let store = Store(engine: Engine(configuration: configuration))
        return (try? Memory(store: store, type: MemoryType(min: 1, max: 1, shared: true))) != nil
    }()

    static var testPaths: [String] {
        return [
            // Wasm 3.0, which includes memory64, tail calls, exception handling, extended
            // constant expressions, relaxed SIMD, typed function references and multi-memory.
            Self.testsuite.path,
            Self.testsuite.appendingPathComponent("custom").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/memory64").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/function-references").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/fuel").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/gc").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/annotations").path,
        ]
    }

    /// The threads proposal tests declare shared memories, so they are skipped where one
    /// cannot be created. Token threading never has one, as it checks bounds in software.
    static var sharedMemoryTestPaths: [String] {
        guard sharedMemorySupported else { return [] }
        return [
            Self.testsuite.appendingPathComponent("proposals/threads").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory/threads").path,
        ]
    }

    /// Spec files with constructs wasm2wat does not print: custom sections from `@custom`
    /// annotations, and GC types.
    static let roundTripUnsupported =
        [
            "Tests/WasmKitTests/ExtraSuite/annotations/custom.wast",
            "Tests/WasmKitTests/ExtraSuite/annotations/custom_datacount.wast",
            "Vendor/testsuite/custom/branch_hint.wast",
            "Vendor/testsuite/custom/custom_annot.wast",
        ]
        + [
            "array.wast", "array_copy.wast", "array_fill.wast", "array_init_data.wast", "array_init_elem.wast",
            "array_new_data.wast", "array_new_elem.wast", "br_on_cast.wast", "br_on_cast_fail.wast", "extern.wast",
            "i31.wast", "ref_cast.wast", "ref_eq.wast", "ref_null.wast", "ref_test.wast", "struct.wast", "tag.wast",
            "table_init.wast", "table_init64.wast", "type-canon.wast", "type-equivalence.wast", "type-rec.wast",
            "type-subtyping.wast",
        ].map { "Vendor/testsuite/\($0)" }

    static func testCases(in paths: [String]) throws -> [TestCase] {
        var exclude = SpectestDiscovery(path: []).exclude
        exclude += UnsupportedSpectests.files.map { "Vendor/testsuite/\($0)" }
        return try SpectestDiscovery(path: paths, exclude: exclude).discover()
    }

    static func run(test: TestCase, configuration: EngineConfiguration) throws {
        let skip =
            UnsupportedSpectests.directives.first { test.path.hasSuffix("Vendor/testsuite/\($0.key)") }?.value ?? [:]
        try SpectestRunner(configuration: configuration)
            .run(test: test, reporter: NullSpectestProgressReporter(), skip: skip)
    }

    #if !os(Android)
        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestTests.testCases(in: SpectestTests.testPaths + SpectestTests.sharedMemoryTestPaths)
        )
        func run(test: TestCase) throws {
            try Self.run(test: test, configuration: EngineConfiguration())
        }

        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestTests.testCases(in: SpectestTests.testPaths)
        )
        func runWithTokenThreading(test: TestCase) throws {
            var defaultConfig = EngineConfiguration()
            guard defaultConfig.threadingModel != .token else { return }
            defaultConfig.threadingModel = .token
            // Sanity check that non-default threading models work.
            try Self.run(test: test, configuration: defaultConfig)
        }

        @Test(
            arguments: try SpectestDiscovery(
                path: SpectestTests.testPaths,
                exclude: SpectestDiscovery(path: []).exclude + SpectestTests.roundTripUnsupported
            ).discover()
        )
        func roundTrip(test: TestCase) throws {
            let data = try #require(FileManager.default.contents(atPath: test.path))
            let rootPath = URL(fileURLWithPath: test.path).deletingLastPathComponent().path
            let features = WASTRunContext.deriveFeatureSet(rootPath: rootPath)
            let names = EncodeOptions(nameSection: true)
            var content = try parseWAST(String(data: data, encoding: .utf8)!, features: features)

            while let (directive, _) = try content.nextDirective() {
                guard case .module(let moduleDirective) = directive else { continue }
                let binary: [UInt8]
                switch moduleDirective.source {
                case .text(let wat): binary = try wat.encode(options: names)
                case .binary:
                    // Binary modules may use non-canonical encodings (e.g. non-minimal LEB128).
                    continue
                case .quote(let text):
                    binary = try wat2wasm(String(decoding: text, as: UTF8.self), features: features, options: names)
                }

                let text = try wasm2wat(StaticByteStreamSource(bytes: binary), features: features)
                let binary2 = try wat2wasm(text, features: features, options: names)
                #expect(binary == binary2, "Round-trip mismatch in \(test.relativePath)")
            }
        }
    #endif
}
