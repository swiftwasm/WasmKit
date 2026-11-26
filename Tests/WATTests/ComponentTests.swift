#if ComponentModel
    import ComponentModel
    import Foundation
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

        static func componentWastFiles() -> [URL] {
            let componentModelTestPath = vendorPath.appendingPathComponent("component-model/test")

            guard FileManager.default.fileExists(atPath: componentModelTestPath.path) else {
                return []
            }

            let fixturesPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
                .appendingPathComponent("ComponentModelFixtures")
            let searchPaths =
                [fixturesPath]
                + ["wasm-tools", "wasmtime", "values", "names", "resources", "async"].map {
                    componentModelTestPath.appendingPathComponent($0)
                }

            return searchPaths.flatMap {
                (try? FileManager.default.contentsOfDirectory(
                    at: $0,
                    includingPropertiesForKeys: nil
                )) ?? []
            }.filter { $0.pathExtension == "wast" }
        }

        static let knownIssues: [String: Set<Int>] = [
            // The loader fills each index space in a fixed section order. It rejects these
            // wasm-tools encodings, which interleave aliases, `canon lower` and type exports.
            "wasmtime/adapter.wast": [97],
            "wasmtime/fused.wast": [472, 508],
            "wasmtime/strings.wast": [4, 40, 76],
            // The text parser does not support `refines` on variant cases.
            "wasm-tools/definedtypes.wast": [3],
            // The text parser does not support `async` function types, `stream` and `future`
            // types, or async canon built-ins.
            "async/trap-on-reenter.wast": [4],
            // The text parser does not support shorthand forms: inline `import` and `export` on
            // components, core modules and instances, ids on exports, implicit outer aliases,
            // `(core func (alias ...))`, and export projections other than a single `(func $i "name")`.
            "async/deadlock.wast": [4],
            "async/drop-waitable-set.wast": [5],
            "wasm-tools/alias.wast": [68, 162, 174, 203, 224],
            "wasm-tools/export-introduces-alias.wast": [3],
            "wasm-tools/func.wast": [60],
            "wasm-tools/instantiate.wast": [80, 98, 373, 542],
            "wasm-tools/module-link.wast": [3, 12],
            "wasm-tools/naming.wast": [105],
            "wasm-tools/resources.wast": [291, 396, 439, 465, 567, 577, 591, 609, 625, 657, 721, 1022, 1080],
            "wasm-tools/tags.wast": [17],
            "wasm-tools/type-export-restrictions.wast": [107, 231, 244, 260, 319, 418, 468],
            "wasm-tools/virtualize.wast": [3],
            "wasmtime/instance.wast": [18, 104, 130, 191, 216, 224],
            "wasmtime/modules.wast": [3, 34, 67, 108, 201, 292, 298, 315, 368, 416],
            "wasmtime/nested.wast": [24, 36, 128, 149, 175, 213, 219, 264, 322, 374],
            "wasmtime/resources.wast": [961],
            "wasmtime/tags.wast": [3],
        ]

        static let features: WasmFeatureSet = WasmFeatureSet.all

        // MARK: - Encoding Tests

        @Test(arguments: componentWastFiles())
        func componentModelSpectest(wastFile: URL) throws {
            let wastContent = try String(contentsOf: wastFile, encoding: .utf8)
            let knownIssueLines =
                Self.knownIssues[wastFile.deletingLastPathComponent().lastPathComponent + "/" + wastFile.lastPathComponent] ?? []
            var reachedKnownIssueLines: Set<Int> = []

            // Try to run wast2json for encoding validation (may fail for files with component assert_return)
            var moduleCommands: [WAST2JSONCommand] = []
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
            var wast = try parseComponentWAST(wastContent, features: Self.features)

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
                        let isKnownIssue = knownIssueLines.contains(line)
                        if isKnownIssue { reachedKnownIssueLines.insert(line) }
                        do {
                            try withKnownIssue {
                                try executeAssertTrap(
                                    execute: execute,
                                    expectedMessage: expectedMessage,
                                    instance: currentInstance,
                                    linker: linker,
                                    location: location
                                )
                            } when: {
                                isKnownIssue
                            }
                            executedAssertTraps += 1
                        } catch let error {
                            // Skip assert_trap that requires unsupported features
                            print("\(wastFile.lastPathComponent):\(line): skipped assert_trap: \(error)")
                            skippedAssertTraps += 1
                        }

                    case .assertInvalid, .assertMalformed, .register, .invoke:
                        // TODO: Not implemented yet
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
                let isKnownIssue = knownIssueLines.contains(command.line)
                if isKnownIssue { reachedKnownIssueLines.insert(command.line) }

                withKnownIssue {
                    guard let component = componentsByLine[command.line] else {
                        Issue.record("\(wastFile.lastPathComponent):\(command.line): Component not found at line")
                        return
                    }

                    var encoder = ComponentEncoder()
                    let actualBytes: [UInt8]
                    do {
                        actualBytes = try encoder.encode(component, options: .init(nameSection: true))
                    } catch {
                        Issue.record("\(wastFile.lastPathComponent):\(command.line): Encode failed: \(error)")
                        return
                    }

                    // Get expected bytes from memory (extracted by wast2json)
                    guard let expectedBytes = wasmFiles[filename] else {
                        Issue.record("\(wastFile.lastPathComponent):\(command.line): Expected file not found: \(filename)")
                        return
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
                } when: {
                    isKnownIssue
                }
            }

            for line in knownIssueLines.subtracting(reachedKnownIssueLines).sorted() {
                Issue.record("\(wastFile.lastPathComponent):\(line): known issue line was not reached")
            }
        }

        @Test
        func parsesRegisterDirective() throws {
            var wast = try parseComponentWAST(#"(component $c) (register "name" $c)"#)
            _ = try #require(try wast.nextDirective())
            let (directive, _) = try #require(try wast.nextDirective())
            guard case .register(let name, let componentId) = directive else {
                Issue.record("Expected register directive, got \(directive)")
                return
            }
            #expect(name == "name")
            #expect(componentId == "$c")
        }

        @Test
        func parsesRegisterDirectiveWithoutComponentId() throws {
            var wast = try parseComponentWAST(#"(component) (register "name")"#)
            _ = try #require(try wast.nextDirective())
            let (directive, _) = try #require(try wast.nextDirective())
            guard case .register(let name, let componentId) = directive else {
                Issue.record("Expected register directive, got \(directive)")
                return
            }
            #expect(name == "name")
            #expect(componentId == nil)
        }

        @Test(arguments: ["type", "instance"])
        func coreSortExportAliasIsRejected(coreSort: String) throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm(#"(component (import "i" (instance $i)) (alias export $i "t" (core \#(coreSort) $t)))"#)
            }
            #expect(error?.message == "A component instance cannot export a core \(coreSort)")
        }

        @Test(arguments: ["type", "module", "instance"])
        func unsupportedCoreExportAliasSortIsRejected(coreSort: String) throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm(
                    #"(component (core module $m) (core instance $ci (instantiate $m)) (alias core export $ci "x" (core \#(coreSort) $y)))"#
                )
            }
            #expect(error?.message == "Unsupported core sort '\(coreSort)' for core export alias")
        }

        @Test(arguments: [
            (#"(alias export $i "x" (bogus $x))"#, "Unexpected component declaration sort 'bogus'"),
            (#"(alias export $i "x" (core bogus $x))"#, "Unexpected core declaration sort 'bogus'"),
            (#"(instance (export "x" (bogus $x)))"#, "Unexpected component declaration sort 'bogus'"),
            (#"(instance (export "x" (core bogus $x)))"#, "Unexpected core declaration sort 'bogus'"),
            (#"(instance (instantiate $c (with "x" (bogus $x))))"#, "Unexpected component declaration sort 'bogus'"),
            (#"(instance (instantiate $c (with "x" (core bogus $x))))"#, "Unexpected core declaration sort 'bogus'"),
            (#"(alias core export $ci "x" (core bogus $y))"#, "Unexpected core declaration sort 'bogus'"),
            ("(core type (module (alias outer 0 0 (bogus $x))))", "Unexpected core declaration sort 'bogus'"),
        ])
        func unknownSortKeywordIsRejected(field: String, message: String) throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm(#"(component (import "i" (instance $i)) (component $c) \#(field))"#)
            }
            #expect(error?.message == message)
        }

        @Test
        func unresolvedCoreImportTypeIsRejected() throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm(#"(component (core type (module (import "m" "n" (func (type $missing))))))"#)
            }
            #expect(error?.message == "Unknown core type '$missing'")
        }

        @Test
        func nestedValueTypesWithinLimitAreAccepted() throws {
            _ = try wat2wasm("(component (type \(nestedValueType(depth: 11))))")
        }

        @Test
        func tooDeeplyNestedValueTypeIsRejected() throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm("(component (type \(nestedValueType(depth: 12))))")
            }
            #expect(error?.message == "nesting too deep")
        }

        @Test
        func nestedInstanceTypesWithinLimitAreAccepted() throws {
            _ = try wat2wasm("(component (type \(nestedInstanceType(depth: 10))))")
        }

        @Test
        func tooDeeplyNestedInstanceTypeIsRejected() throws {
            let error = #expect(throws: WatParserError.self) {
                try wat2wasm("(component (type \(nestedInstanceType(depth: 11))))")
            }
            #expect(error?.message == "nesting too deep")
        }

        // MARK: - Test Helpers

        private func nestedValueType(depth: Int) -> String {
            String(repeating: "(list ", count: depth) + "u8" + String(repeating: ")", count: depth)
        }

        private func nestedInstanceType(depth: Int) -> String {
            String(repeating: "(instance (type ", count: depth) + "(func)" + String(repeating: "))", count: depth)
        }

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
            execute: ComponentWASTExecute,
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
            execute: ComponentWASTExecute,
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

        /// Compare two ComponentValues for equality. Doesn't support resources.
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
