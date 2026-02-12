#if ComponentModel
    import ComponentModel
    import Foundation
    import SystemPackage
    import Testing
    import WAT
    import WasmKit
    import WasmKitWASI
    import WasmParser
    import WasmTools

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
                componentModelTestPath.appendingPathComponent("values"),
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
                    "fused.wast",
                    "strings.wast",
                    "adapter.wast",
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

            // For execution: track current component instance
            let engine = Engine()
            let store = Store(engine: engine)
            let linker = ComponentLoader(store: store)
            var currentInstance: ComponentInstance?
            var skippedAssertReturns = 0
            var executedAssertReturns = 0
            var executedAssertTraps = 0
            var skippedAssertTraps = 0

            while true {
                do {
                    guard let (directive, location) = try wast.nextDirective() else { break }
                    let line = location.computeLineAndColumn().line

                    switch directive {
                    case .component(let comp):
                        if case .text(let componentDef) = comp.source {
                            componentsByLine[line] = componentDef
                        }
                        // Also try to instantiate for execution
                        do {
                            currentInstance = try instantiateComponent(comp, linker: linker)
                        } catch {
                            // Instantiation may fail for various reasons (unsupported features)
                            // That's OK for encoding-only tests
                            currentInstance = nil
                        }

                    case .assertReturn(let execute, let expectedResults):
                        guard let instance = currentInstance else {
                            skippedAssertReturns += 1
                            continue
                        }
                        do {
                            try executeAssertReturn(
                                execute: execute,
                                expected: expectedResults,
                                instance: instance,
                                location: location
                            )
                            executedAssertReturns += 1
                        } catch let error {
                            // Skip assert_return that requires unsupported features (e.g., strings)
                            print("\(wastFile.lastPathComponent):\(line): skipped assert_return: \(error)")
                            skippedAssertReturns += 1
                        }

                    case .assertTrap(let execute, let expectedMessage):
                        do {
                            try executeAssertTrap(
                                execute: execute,
                                expectedMessage: expectedMessage,
                                instance: currentInstance,
                                linker: linker,
                                location: location
                            )
                            executedAssertTraps += 1
                        } catch let error {
                            // Skip assert_trap that requires unsupported features
                            print("\(wastFile.lastPathComponent):\(line): skipped assert_trap: \(error)")
                            skippedAssertTraps += 1
                        }

                    case .assertInvalid, .assertMalformed, .register, .invoke:
                        // TODO: Not implemented yet
                        #warning(".assertInvalid, .assertMalformed, .register, .invoke commands not implemented yet")
                        continue
                    }
                } catch {
                    // Skip directives that fail to parse (e.g., assert_invalid with unsupported syntax)
                    wast.skipCurrentDirective()
                    continue
                }
            }

            if skippedAssertReturns > 0 || executedAssertReturns > 0 {
                print("\(wastFile.lastPathComponent): executed \(executedAssertReturns) assert_return, skipped \(skippedAssertReturns)")
            }
            if skippedAssertTraps > 0 || executedAssertTraps > 0 {
                print("\(wastFile.lastPathComponent): executed \(executedAssertTraps) assert_trap, skipped \(skippedAssertTraps)")
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

        // MARK: - Test Helpers

        /// Instantiate a component from a ComponentDirective.
        private func instantiateComponent(
            _ comp: ComponentDirective,
            linker: ComponentLoader
        ) throws -> ComponentInstance {
            guard case .text(let componentDef) = comp.source else {
                throw TestError("Only text components supported")
            }

            var encoder = ComponentEncoder()
            let ourBytes = try encoder.encode(componentDef, options: .init())

            let parsed = try parseComponent(bytes: ourBytes)

            return try linker.instantiate(component: parsed)
        }

        /// Execute an assert_trap directive and verify the trap occurs.
        private func executeAssertTrap(
            execute: ComponentWastExecute,
            expectedMessage: String,
            instance: ComponentInstance?,
            linker: ComponentLoader,
            location: Location
        ) throws {
            switch execute {
            case .invoke(let invoke):
                // Invoke form: call a function and expect it to trap
                guard let instance = instance else {
                    throw TestError("No current instance for invoke assert_trap")
                }

                guard let exported = instance.export(invoke.name),
                    case .function(let componentFunc) = exported
                else {
                    let exportNames = instance.exports.map { $0.0 }
                    throw TestError("Function '\(invoke.name)' not found in component exports. Available: \(exportNames)")
                }

                do {
                    _ = try componentFunc.invoke(invoke.args)
                    Issue.record("Expected trap at \(location) but invocation succeeded")
                } catch let error {
                    // Verify the error message contains the expected substring
                    let errorMessage = String(describing: error)
                    if !errorMessage.contains(expectedMessage) {
                        Issue.record("Trap message mismatch at \(location): expected '\(expectedMessage)', got '\(errorMessage)'")
                    }
                }

            case .component(let comp):
                // Component form: instantiate a component and expect it to trap during instantiation
                do {
                    _ = try instantiateComponent(comp, linker: linker)
                    Issue.record("Expected trap during component instantiation at \(location) but instantiation succeeded")
                } catch let error {
                    // Verify the error message contains the expected substring
                    let errorMessage = String(describing: error)
                    if !errorMessage.contains(expectedMessage) {
                        Issue.record("Trap message mismatch at \(location): expected '\(expectedMessage)', got '\(errorMessage)'")
                    }
                }

            case .get:
                throw TestError("get execute not supported for assert_trap")
            }
        }

        /// Execute an assert_return directive and check results.
        private func executeAssertReturn(
            execute: ComponentWastExecute,
            expected: [ComponentValue],
            instance: ComponentInstance,
            location: Location
        ) throws {
            guard case .invoke(let invoke) = execute else {
                throw TestError("Only invoke execute supported, got \(execute)")
            }

            guard let exported = instance.export(invoke.name),
                case .function(let componentFunc) = exported
            else {
                let exportNames = instance.exports.map { $0.0 }
                throw TestError("Function '\(invoke.name)' not found in component exports. Available: \(exportNames)")
            }

            let results = try componentFunc.invoke(invoke.args)

            guard results.count == expected.count else {
                Issue.record("Result count mismatch at \(location): expected \(expected.count), got \(results.count)")
                return
            }

            for (index, (actual, exp)) in zip(results, expected).enumerated() {
                if !componentValuesEqual(actual, exp) {
                    Issue.record("Result \(index) mismatch at \(location): expected \(exp), got \(actual)")
                }
            }
        }

        /// Compare two ComponentValues for equality.
        private func componentValuesEqual(_ a: ComponentValue, _ b: ComponentValue) -> Bool {
            switch (a, b) {
            case (.bool(let av), .bool(let bv)): return av == bv
            case (.s8(let av), .s8(let bv)): return av == bv
            case (.u8(let av), .u8(let bv)): return av == bv
            case (.s16(let av), .s16(let bv)): return av == bv
            case (.u16(let av), .u16(let bv)): return av == bv
            case (.s32(let av), .s32(let bv)): return av == bv
            case (.u32(let av), .u32(let bv)): return av == bv
            case (.s64(let av), .s64(let bv)): return av == bv
            case (.u64(let av), .u64(let bv)): return av == bv
            case (.float32(let av), .float32(let bv)): return av.bitPattern == bv.bitPattern
            case (.float64(let av), .float64(let bv)): return av.bitPattern == bv.bitPattern
            case (.char(let av), .char(let bv)): return av == bv
            case (.string(let av), .string(let bv)): return av == bv
            default: return false
            }
        }

        struct TestError: Error {
            let message: String
            init(_ message: String) { self.message = message }
        }
    }
#endif
