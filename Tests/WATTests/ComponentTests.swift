#if ComponentModel
    import ComponentModel
    import Foundation
    import SystemPackage
    import Testing
    import WasmKit
    import WasmKitWASI
    import WasmParser
    import WasmTools

    @testable import WAT

    @Suite
    struct ComponentTests {

        // MARK: - Test Suite Enumeration

        static let vendorPath: URL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // WATTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // Root
            .appendingPathComponent("Vendor")

        static func componentWastFiles(include: [String] = [], exclude: [String] = [], excludePaths: [String] = []) -> [URL] {
            let componentModelTestPath = vendorPath.appendingPathComponent("component-model/test")

            guard FileManager.default.fileExists(atPath: componentModelTestPath.path) else {
                return []
            }

            let searchPaths = [
                componentModelTestPath.appendingPathComponent("wasm-tools"),
                componentModelTestPath.appendingPathComponent("wasmtime"),
            ]

            let result: [URL] = searchPaths.flatMap {
                (try? FileManager.default.contentsOfDirectory(
                    at: $0,
                    includingPropertiesForKeys: nil
                )) ?? []
            }.compactMap { filePath in
                guard filePath.pathExtension == "wast" else {
                    return nil
                }
                for excludePath in excludePaths {
                    if filePath.path.hasSuffix(excludePath) {
                        return nil
                    }
                }
                if !include.isEmpty {
                    guard include.contains(filePath.lastPathComponent) else { return nil }
                } else {
                    guard !exclude.contains(filePath.lastPathComponent) else { return nil }
                }
                return filePath
            }

            return result
        }

        // MARK: - Encoding Tests

        @Test(
            arguments: componentWastFiles(
                include: [
                    "empty.wast",
                    "simple.wast",
                    "types.wast",
                    "link.wast",
                    "inline-exports.wast",
                    "nested-modules.wast",
                    "definedtypes.wast",
                    "fused.wast",
                ],
                excludePaths: []
            )
        )
        func componentModelSpectest(wastFile: URL) throws {
            let wastContent = try String(contentsOf: wastFile, encoding: .utf8)

            // Try to run wast2json for encoding validation (may fail for files with component assert_return)
            var moduleCommands: [Wast2JSONCommand] = []
            var wasmFiles: [String: [UInt8]] = [:]
            do {
                let (jsonOutput, files) = try wast2json(
                    wastContent: Array(wastContent.utf8),
                    wastFileName: wastFile.lastPathComponent
                )
                moduleCommands = jsonOutput.commands.filter { $0.type == "module" && $0.moduleType == "binary" }
                wasmFiles = files
            } catch {
                // wast2json doesn't support component model values in assert_return - that's ok
                // We'll still run assert_return execution below when it's supported.
            }

            // Parse WAST file and collect component directives by line number
            var componentsByLine: [Int: ComponentWatParser.ComponentDef] = [:]
            var wast = try parseComponentWAST(wastContent, features: .default)

            while true {
                do {
                    guard let (directive, location) = try wast.nextDirective() else { break }
                    let line = location.computeLineAndColumn().line

                    switch directive {
                    case .component(let comp):
                        if case .text(let componentDef) = comp.source {
                            componentsByLine[line] = componentDef
                        }

                    case .assertReturn, .assertTrap, .assertInvalid, .assertMalformed, .register, .invoke:
                        // TODO: Not implemented yet
                        continue
                    }
                } catch {
                    // Skip directives that fail to parse (e.g., assert_invalid with unsupported syntax)
                    wast.skipCurrentDirective()
                    continue
                }
            }

            // Validate binary encoding against wasm-tools reference
            for command in moduleCommands {
                guard let filename = command.filename else { continue }

                guard let component = componentsByLine[command.line] else {
                    Issue.record("\(wastFile.lastPathComponent):\(command.line): Component not found at line")
                    continue
                }

                var encoder = ComponentEncoder()
                let actualBytes: [UInt8]
                do {
                    actualBytes = try encoder.encode(component, options: .init(nameSection: true))
                } catch {
                    Issue.record("\(wastFile.lastPathComponent):\(command.line): Encode failed: \(error)")
                    continue
                }

                // Get expected bytes from memory (extracted by wast2json)
                guard let expectedBytes = wasmFiles[filename] else {
                    Issue.record("\(wastFile.lastPathComponent):\(command.line): Expected file not found: \(filename)")
                    continue
                }

                if actualBytes != expectedBytes {
                    print("\(wastFile.lastPathComponent):\(command.line) - Size: expected \(expectedBytes.count), actual \(actualBytes.count)")

                    if actualBytes.count <= 200 && expectedBytes.count <= 200 {
                        print("  Expected bytes: \(expectedBytes.map { String(format: "%02x", $0) }.joined(separator: " "))")
                        print("  Actual bytes:   \(actualBytes.map { String(format: "%02x", $0) }.joined(separator: " "))")
                    }
                }

                #expect(
                    actualBytes.count == expectedBytes.count,
                    "Size mismatch for \(wastFile.lastPathComponent):\(command.line): expected \(expectedBytes.count), actual \(actualBytes.count)"
                )
                #expect(
                    actualBytes == expectedBytes,
                    "Byte mismatch for \(wastFile.lastPathComponent):\(command.line)"
                )
            }
        }
    }
#endif
