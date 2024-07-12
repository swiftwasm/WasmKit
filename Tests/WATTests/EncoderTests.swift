import XCTest
import Foundation
import WasmParser

@testable import WAT

class EncoderTests: XCTestCase {

    struct CompatibilityTestStats {
        var run: Int = 0
        var failed: Set<String> = []
    }

    func checkWabtCompatibility(
        wast: URL, json: URL, stats: inout CompatibilityTestStats
    ) throws {
        func recordFail() {
            stats.failed.insert(wast.lastPathComponent)
        }
        func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(lhs, rhs, file: file, line: line)
            if lhs != rhs {
                recordFail()
            }
        }

        print("Checking\n  wast: \(wast.path)\n  json: \(json.path)")
        let moduleBinaryFiles = try Spectest.moduleFiles(json: json)
        var parser = WastParser(try String(contentsOf: wast))
        var watModules: [ModuleDirective] = []
        while let directive = try parser.nextDirective() {
            if case let .module(moduleDirective) = directive {
                watModules.append(moduleDirective)
            }
        }
        assertEqual(watModules.count, moduleBinaryFiles.count)
        if watModules.count != moduleBinaryFiles.count {
            recordFail()
        }
        for (watModule, (moduleBinaryFile, expectedName)) in zip(watModules, moduleBinaryFiles) {
            stats.run += 1
            let moduleBytes: [UInt8]
            let expectedBytes = try Array(Data(contentsOf: moduleBinaryFile))
            do {
                assertEqual(watModule.id, expectedName)
                switch watModule.source {
                case .text(var watModule):
                    moduleBytes = try encode(module: &watModule)
                case .binary(let bytes):
                    moduleBytes = bytes
                case .quote(let watText):
                    moduleBytes = try wat2wasm(String(decoding: watText, as: UTF8.self))
                }
            } catch {
                recordFail()
                XCTFail("Error while encoding \(moduleBinaryFile.lastPathComponent): \(error)")
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

    func testSpectest() throws {
        var stats = CompatibilityTestStats()
        let excluded: [String] = []
        for wastFile in Spectest.wastFiles(include: [], exclude: excluded) {
            let jsonFileName = wastFile.lastPathComponent.replacing(#/\.wast$/#, with: ".json")
            let json = Spectest.rootDirectory.appendingPathComponent("spectest")
                .appendingPathComponent(jsonFileName)
            do {
                try checkWabtCompatibility(wast: wastFile, json: json, stats: &stats)
            } catch {
                stats.failed.insert(wastFile.lastPathComponent)
                XCTFail("Error while checking \(wastFile.lastPathComponent): \(error)")
            }
        }
        print("Spectest compatibility: \(stats.run - stats.failed.count) / \(stats.run)")
        print("Failed test cases: \(stats.failed.sorted())")
    }
}
