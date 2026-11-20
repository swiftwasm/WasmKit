import Foundation
import Testing

@testable import WIT

#if ComponentModel
    import WasmTools
#endif

/// Absolute path to the vendored WASIp2 WIT proposals (`Vendor/wasi/proposals`).
/// `Vendor/wasi` is checked out by `Vendor/checkout-dependency` under the component-model
/// category; the suite below is skipped when it is absent.
private let wasiProposalsPath: String = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // WITTests/
    .deletingLastPathComponent()  // Tests/
    .deletingLastPathComponent()  // repo root
    .appendingPathComponent("Vendor/wasi/proposals").path

/// Verifies that all WASIp2 WIT packages parse correctly by roundtripping
/// through our parser and formatter, then comparing against wasm-tools
/// reference output.
@Suite(.enabled(if: FileManager.default.fileExists(atPath: wasiProposalsPath), "Vendor/wasi not checked out"))
struct WASIp2ParseTests {

    private let loader = LocalFileLoader()

    private func parsePackage(_ name: String) throws -> PackageUnit {
        try PackageUnit.parse(
            directory: "\(wasiProposalsPath)/\(name)/wit",
            loader: loader
        )
    }

    // Reference comparison needs `WasmTools`, which `WITTests` depends on only under the
    // `ComponentModel` trait.
    #if ComponentModel
        /// Format a parsed package with our formatter and compare each interface
        /// against wasm-tools reference output.
        ///
        /// wasm-tools may reorder interfaces (dependency order), so we compare
        /// per-interface rather than the whole file.
        private func assertMatchesReference(_ name: String, deps: [String] = []) throws {
            let pkg = try parsePackage(name)

            let referenceOutput = try getReferenceOutput(name, deps: deps)
            let referenceBlocks: [String: InterfaceBlock]
            do {
                referenceBlocks = try interfaceBlocks(in: referenceOutput)
            } catch {
                Issue.record("\(name): wasm-tools output does not parse: \(error)\n\(referenceOutput)")
                return
            }
            var ourNames: Set<String> = []

            for sourceFile in pkg.sourceFiles {
                for item in sourceFile.items {
                    switch item {
                    case .interface(let iface):
                        var formatter = WITFormatter(output: "")
                        formatter.write(interface: iface.syntax, indent: 0)
                        let key = iface.name.text
                        ourNames.insert(key)
                        guard let refBlock = referenceBlocks[key] else {
                            Issue.record("\(name): interface '\(key)' not found in wasm-tools output")
                            continue
                        }
                        for message in formatterMismatches(formatter.output, key: key, ref: refBlock) {
                            Issue.record("\(name)/\(key): \(message)")
                        }
                    case .world:
                        // wasm-tools resolves transitive imports and reorders world items,
                        // so we can't directly compare worlds. Interface comparison is sufficient
                        // since worlds just reference interfaces by name.
                        break
                    case .use:
                        break
                    }
                }
            }
            for key in referenceBlocks.keys.sorted() where !ourNames.contains(key) {
                Issue.record("\(name): interface '\(key)' is in wasm-tools output but not in the parsed package")
            }
        }

        private func getReferenceOutput(_ name: String, deps: [String]) throws -> String {
            if deps.isEmpty {
                // Standalone package: pass directory directly
                return try componentWit(packageDirectory: "\(wasiProposalsPath)/\(name)/wit")
            } else {
                // Package with deps: create temp directory with deps/ structure
                let tmpDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("wasip2-test-\(name)-\(UUID().uuidString)")
                defer { try? FileManager.default.removeItem(at: tmpDir) }

                // Copy package .wit files only (skip deps.toml/deps.lock)
                let srcDir = URL(fileURLWithPath: "\(wasiProposalsPath)/\(name)/wit")
                try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
                for file in try FileManager.default.contentsOfDirectory(atPath: srcDir.path) {
                    guard file.hasSuffix(".wit") else { continue }
                    try FileManager.default.copyItem(
                        at: srcDir.appendingPathComponent(file),
                        to: tmpDir.appendingPathComponent(file)
                    )
                }

                // Copy deps
                let depsDir = tmpDir.appendingPathComponent("deps")
                try FileManager.default.createDirectory(at: depsDir, withIntermediateDirectories: true)
                for dep in deps {
                    let depSrc = URL(fileURLWithPath: "\(wasiProposalsPath)/\(dep)/wit")
                    let depDst = depsDir.appendingPathComponent(dep)
                    try FileManager.default.copyItem(at: depSrc, to: depDst)
                }

                return try componentWit(packageDirectory: tmpDir.path)
            }
        }

        // MARK: - Standalone packages (no cross-package deps)

        @Test func roundtripRandom() throws {
            try assertMatchesReference("random")
        }

        @Test func roundtripIO() throws {
            try assertMatchesReference("io")
        }

        // MARK: - Packages with dependencies

        @Test func roundtripClocks() throws {
            try assertMatchesReference("clocks", deps: ["io"])
        }

        @Test func roundtripFilesystem() throws {
            try assertMatchesReference("filesystem", deps: ["io", "clocks"])
        }

        @Test func roundtripSockets() throws {
            try assertMatchesReference("sockets", deps: ["io", "clocks"])
        }

        @Test func roundtripCLI() throws {
            try assertMatchesReference("cli", deps: ["io", "clocks", "random", "filesystem", "sockets"])
        }

        @Test func roundtripHTTP() throws {
            try assertMatchesReference("http", deps: ["io", "clocks", "random", "cli", "filesystem", "sockets"])
        }
    #endif

    // MARK: - Multi-package resolution

    @Test func resolveAllWASIp2Packages() throws {
        let packageResolver = PackageResolver()
        for name in ["io", "clocks", "random", "filesystem", "sockets", "cli"] {
            let pkg = try parsePackage(name)
            packageResolver.register(packageUnit: pkg)
        }
        #expect(packageResolver.packages.count == 6)
    }

    // MARK: - Formatter (no wasm-tools reference required)

    /// Every WASIp2 package formats to non-empty canonical WIT text with a package header.
    @Test(arguments: ["io", "clocks", "random", "filesystem", "sockets", "cli"])
    func formatsPackage(name: String) throws {
        let pkg = try parsePackage(name)
        let text = WITFormatter.format(package: pkg)
        #expect(text.hasPrefix("package "))
        #expect(text.contains("interface ") || text.contains("world "))
    }

    /// Formatting is idempotent: format -> reparse -> format yields identical text.
    @Test(arguments: ["random", "io"])
    func formatIsIdempotent(name: String) throws {
        let pkg = try parsePackage(name)
        let once = WITFormatter.format(package: pkg)

        let reparsed = try SourceFileSyntax.parse(once, fileName: "\(name).wit")
        var builder = PackageBuilder()
        try builder.append(reparsed)
        let rebuilt = try builder.build()

        let twice = WITFormatter.format(package: rebuilt)
        #expect(once == twice)
    }

    /// The formatter streams into any `TextOutputStream` sink (not only a `String` buffer) and
    /// emits the document line by line: each sink write is exactly one rendered line ending in a
    /// single trailing newline. A `write(package:)` that emitted one buffered blob would produce a
    /// single chunk and fail the per-newline count, so the invariant discriminates streaming from
    /// buffering rather than being tautological.
    @Test func streamsLineByLineIntoCustomSink() throws {
        struct ChunkRecorder: TextOutputStream {
            var chunks: [String] = []
            mutating func write(_ string: String) { chunks.append(string) }
        }

        let pkg = try parsePackage("random")

        var formatter = WITFormatter(output: ChunkRecorder())
        formatter.write(package: pkg)
        let chunks = formatter.output.chunks
        let streamed = chunks.joined()

        // Concatenation of the streamed chunks equals the String-convenience output.
        #expect(streamed == WITFormatter.format(package: pkg))
        // Each write is exactly one rendered line: non-empty, ending in one trailing newline with
        // no interior newline.
        #expect(!chunks.isEmpty)
        #expect(
            chunks.allSatisfy { chunk in
                chunk.hasSuffix("\n") && !chunk.dropLast().contains("\n")
            })
        // One chunk per newline in the output: a single buffered write would make this 1, not many.
        #expect(chunks.count == streamed.filter { $0 == "\n" }.count)
    }
}

/// One interface of WIT text, cut at the item boundaries our parser finds.
private struct InterfaceBlock: Equatable {
    /// An item from its first token through its final `;` or `}`, with the text in front of it.
    struct Item: Equatable {
        /// Whitespace and any comments between the previous token and this item.
        var leadingText: String
        var text: String
    }

    /// Attributes through the opening `{`.
    var header: String
    var items: [Item]
    /// The text between the last item and the closing `}`.
    var closingSeparator: String

    /// The interface text this block was cut from, from the header through the closing `}`.
    var text: String {
        header + items.map { $0.leadingText + $0.text }.joined() + closingSeparator + "}"
    }
}

/// Cuts each top-level interface in `text` into an ``InterfaceBlock``, keyed by name. Worlds are
/// skipped by matching braces over tokens, and top-level `use` items are skipped by parsing them.
/// Stops at the first nested `package name { ... }` block, which our parser does not accept and
/// which is how `wasm-tools component wit` prints dependencies.
private func interfaceBlocks(in text: String) throws -> [String: InterfaceBlock] {
    var lexer = Lexer(cursor: Lexer.Cursor(input: text))
    if lexer.peek()?.kind == .package {
        _ = try PackageNameSyntax.parse(lexer: &lexer)
        if lexer.peek()?.kind == .leftBrace { return [:] }
        try lexer.expect(.semicolon)
    }

    var blocks: [String: InterfaceBlock] = [:]
    while let first = lexer.peek() {
        var afterAttributes = lexer
        _ = try AttributeSyntax.parseItems(lexer: &afterAttributes)
        switch afterAttributes.peek()?.kind {
        case .package:
            return blocks
        case .world:
            lexer = afterAttributes
            try lexer.expect(.world)
            _ = try Identifier.parse(lexer: &lexer)
            try lexer.expect(.leftBrace)
            var depth = 1
            while depth > 0 {
                guard let token = lexer.lex() else { throw ParseError(description: "unterminated world") }
                if token.kind == .leftBrace { depth += 1 }
                if token.kind == .rightBrace { depth -= 1 }
            }
            continue
        case .interface:
            break
        default:
            _ = try ASTItemSyntax.parse(lexer: &lexer, documents: DocumentsSyntax(comments: []))
            continue
        }
        lexer = afterAttributes
        try lexer.expect(.interface)
        let name = try Identifier.parse(lexer: &lexer)
        let openBrace = try lexer.expect(.leftBrace)
        var block = InterfaceBlock(
            header: lexer.parseText(in: first.textRange.lowerBound..<openBrace.textRange.upperBound),
            items: [], closingSeparator: "")

        var previousEnd = openBrace.textRange.upperBound
        while let next = lexer.peek(), next.kind != .rightBrace {
            let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
            _ = try InterfaceItemSyntax.parse(
                lexer: &lexer, documents: DocumentsSyntax(comments: []), attributes: attributes)
            block.items.append(
                InterfaceBlock.Item(
                    leadingText: lexer.parseText(in: previousEnd..<next.textRange.lowerBound),
                    text: lexer.parseText(in: next.textRange.lowerBound..<lexer.cursor.nextIndex)))
            previousEnd = lexer.cursor.nextIndex
        }
        let closeBrace = try lexer.expect(.rightBrace)
        block.closingSeparator = lexer.parseText(in: previousEnd..<closeBrace.textRange.lowerBound)
        blocks[name.text] = block
    }
    var rest = lexer
    while true {
        let start = rest.cursor.nextIndex
        if rest.rawLex() == nil {
            if start != rest.cursor.input.endIndex { throw ParseError(description: "unexpected character after the last item") }
            break
        }
    }
    return blocks
}

/// Indices of the entries that have no counterpart in the other list, matching duplicates one for one.
private func multisetDifference<T: Equatable>(ours: [T], ref: [T]) -> (oursOnly: [Int], refOnly: [Int]) {
    var unmatched = Array(ref.indices)
    var oursOnly: [Int] = []
    for (index, value) in ours.enumerated() {
        if let position = unmatched.firstIndex(where: { ref[$0] == value }) {
            unmatched.remove(at: position)
        } else {
            oursOnly.append(index)
        }
    }
    return (oursOnly, unmatched)
}

/// Describes how `ours` differs from `ref`. Items are compared as a multiset, which tolerates the
/// reordering wasm-tools applies. The text after `{` and before `}` is compared exactly. The text in
/// front of any other item is compared with its counterpart of the same text, unless either copy is
/// the first item.
private func mismatches(ours: InterfaceBlock, ref: InterfaceBlock) -> [String] {
    if ours.header != ref.header {
        return ["header mismatch:\n  ours: \(ours.header)\n   ref: \(ref.header)"]
    }

    var messages: [String] = []
    let whole = multisetDifference(ours: ours.items, ref: ref.items)
    let byText = multisetDifference(
        ours: whole.oursOnly.map { ours.items[$0].text }, ref: whole.refOnly.map { ref.items[$0].text })
    for position in byText.refOnly {
        messages.append("missing item from reference:\n\(ref.items[whole.refOnly[position]].text)")
    }
    for position in byText.oursOnly {
        messages.append("extra item not in reference:\n\(ours.items[whole.oursOnly[position]].text)")
    }

    let oursPaired = whole.oursOnly.enumerated().filter { !byText.oursOnly.contains($0.offset) }.map(\.element)
    let refPaired = whole.refOnly.enumerated().filter { !byText.refOnly.contains($0.offset) }.map(\.element)
    if let first = ours.items.first, let refFirst = ref.items.first, first.leadingText != refFirst.leadingText {
        messages.append(
            "text after `{` differs: ours \(first.leadingText.debugDescription), ref \(refFirst.leadingText.debugDescription)")
    }
    var unusedRef = refPaired
    for oursIndex in oursPaired {
        let item = ours.items[oursIndex]
        guard let position = unusedRef.firstIndex(where: { ref.items[$0].text == item.text }) else { continue }
        let refIndex = unusedRef.remove(at: position)
        let refLeading = ref.items[refIndex].leadingText
        // wasm-tools may move an item to or from the first position, whose separator is covered above.
        if oursIndex != 0 && refIndex != 0 && item.leadingText != refLeading {
            messages.append(
                "text in front of an item differs: ours \(item.leadingText.debugDescription), ref \(refLeading.debugDescription), before:\n\(item.text)")
        }
    }
    if ours.closingSeparator != ref.closingSeparator {
        messages.append(
            "text before `}` differs: ours \(ours.closingSeparator.debugDescription), ref \(ref.closingSeparator.debugDescription)")
    }
    return messages
}

/// Describes how formatter output for the interface `key` differs from the reference block `ref`.
private func formatterMismatches(_ output: String, key: String, ref: InterfaceBlock) -> [String] {
    let ours: InterfaceBlock
    do {
        guard let block = try interfaceBlocks(in: output)[key] else {
            return ["formatter output has no interface '\(key)'\n\(output)"]
        }
        ours = block
    } catch {
        return ["formatter output does not parse: \(error)\n\(output)"]
    }
    var messages: [String] = []
    if output != ours.text + "\n" {
        messages.append("formatter output has text outside the interface:\n\(output)")
    }
    return messages + mismatches(ours: ours, ref: ref)
}

private func item(_ leadingText: String, _ text: String) -> InterfaceBlock.Item {
    InterfaceBlock.Item(leadingText: leadingText, text: text)
}

@Suite struct InterfaceBlocksTests {
    @Test func interfaceOnOneLine() throws {
        let blocks = try interfaceBlocks(in: "interface a { f: func(); }\n")
        #expect(
            blocks["a"]
                == InterfaceBlock(header: "interface a {", items: [item(" ", "f: func();")], closingSeparator: " "))
    }

    @Test func braceInsideComment() throws {
        let blocks = try interfaceBlocks(in: "interface a {\n  f: func(); // }\n  g: func();\n}\n")
        #expect(
            blocks["a"]
                == InterfaceBlock(
                    header: "interface a {",
                    items: [item("\n  ", "f: func();"), item(" // }\n  ", "g: func();")],
                    closingSeparator: "\n"))
    }

    @Test func blankLineBetweenAttributeAndInterface() throws {
        let blocks = try interfaceBlocks(in: "@since(version = 0.2.0)\n\ninterface a {\n  f: func();\n}\n")
        #expect(blocks["a"]?.header == "@since(version = 0.2.0)\n\ninterface a {")
    }

    @Test func twoItemsOnOneLine() throws {
        let blocks = try interfaceBlocks(in: "interface a {\n  type x = u8; type y = u16;\n}\n")
        #expect(blocks["a"]?.items == [item("\n  ", "type x = u8;"), item(" ", "type y = u16;")])
    }

    @Test func recordKeepsClosingBrace() throws {
        let blocks = try interfaceBlocks(in: "interface a {\n  record r {\n    x: u8,\n  }\n}\n")
        #expect(blocks["a"]?.items.map(\.text) == ["record r {\n    x: u8,\n  }"])
    }

    @Test func itemStartsAtItsAttribute() throws {
        let blocks = try interfaceBlocks(in: "interface a {\n  @since(version = 0.2.0)\n  f: func();\n}\n")
        #expect(blocks["a"]?.items == [item("\n  ", "@since(version = 0.2.0)\n  f: func();")])
        #expect(blocks["a"]?.closingSeparator == "\n")
    }

    @Test func emptyInterface() throws {
        let blocks = try interfaceBlocks(in: "interface a {}\n")
        #expect(blocks["a"] == InterfaceBlock(header: "interface a {", items: [], closingSeparator: ""))
    }

    @Test func skipsWorldsTopLevelUsesAndStopsAtFirstNestedPackage() throws {
        let text = """
            package a:b;

            use a as b;

            world w {
              import i;
            }

            @since(version = 0.2.0)
            world v {
              import i;
            }

            @since(version = 0.2.0)
            interface h {
            }

            interface i {
              f: func();
            }
            package c:d {
              interface j {
                g: func();
              }
            }
            interface k {
            }

            """
        let names = try interfaceBlocks(in: text).keys.sorted()
        #expect(names == ["h", "i"])
    }

    @Test func multipleInterfacesInOneInput() throws {
        let blocks = try interfaceBlocks(in: "interface a {\n  f: func();\n}\n\ninterface b {\n  g: func();\n}\n")
        #expect(blocks.keys.sorted() == ["a", "b"])
        #expect(blocks["a"]?.items.map(\.text) == ["f: func();"])
        #expect(blocks["b"]?.items.map(\.text) == ["g: func();"])
    }

    @Test func attributedNestedPackageEndsTheScan() throws {
        let text = "interface a {}\n@since(version = 0.2.0)\npackage c:d {\n  interface j {}\n}\n"
        #expect(try interfaceBlocks(in: text).keys.sorted() == ["a"])
    }

    @Test func leadingNestedPackageYieldsNothing() throws {
        #expect(try interfaceBlocks(in: "package c:d {\n  interface j {}\n}\n").isEmpty)
    }

    @Test func worldBodyIsSkippedWithoutParsingIt() throws {
        let blocks = try interfaceBlocks(in: "world w {\n  bogus { nested }\n}\ninterface a {}\n")
        #expect(blocks.keys.sorted() == ["a"])
    }

    @Test func cutRebuildsTheInput() throws {
        for input in [
            "interface a { f: func(); }",
            "@since(version = 0.2.0)\n\ninterface a {\n  f: func(); // }\n  @since(version = 0.2.0)\n  record r {\n    x: u8,\n  }\n\n  type x = u8; type y = u16;\n}",
            "interface a {}",
        ] {
            #expect(try interfaceBlocks(in: input)["a"]?.text == input)
        }
    }

    @Test func rejectsUnknownCharacterBetweenInterfaces() {
        #expect(throws: ParseError.self) { try interfaceBlocks(in: "interface a {}\n#\ninterface b {}\n") }
        #expect(throws: ParseError.self) { try interfaceBlocks(in: "interface a {}\n#") }
    }

    @Test func rejectsInvalidWIT() {
        #expect(throws: ParseError.self) { try interfaceBlocks(in: "interface a {\n  bogus\n}\n") }
        #expect(throws: ParseError.self) { try interfaceBlocks(in: "interface a {\n  f: func();\n") }
    }
}

@Suite struct InterfaceBlockMismatchTests {
    private func block(_ items: [InterfaceBlock.Item], closing: String = "\n") -> InterfaceBlock {
        InterfaceBlock(header: "interface a {", items: items, closingSeparator: closing)
    }

    @Test func equalBlocksHaveNoMismatch() {
        let value = block([item("\n  ", "f: func();"), item("\n\n  ", "g: func();")])
        #expect(mismatches(ours: value, ref: value).isEmpty)
    }

    @Test func reorderedItemsHaveNoMismatch() {
        let ours = block([item("\n  ", "a: func();"), item("\n\n  ", "b: func();"), item("\n\n  ", "c: func();")])
        let ref = block([item("\n  ", "a: func();"), item("\n\n  ", "c: func();"), item("\n\n  ", "b: func();")])
        #expect(mismatches(ours: ours, ref: ref).isEmpty)
    }

    @Test func separatorsArePairedByItemTextNotPosition() {
        let ours = block([item("\n  ", "a: func();"), item("\n  ", "b: func();"), item("\n\n  ", "c: func();")])
        let ref = block([item("\n  ", "a: func();"), item("\n  ", "c: func();"), item("\n\n  ", "b: func();")])
        #expect(
            mismatches(ours: ours, ref: ref) == [
                "text in front of an item differs: ours \"\\n  \", ref \"\\n\\n  \", before:\nb: func();",
                "text in front of an item differs: ours \"\\n\\n  \", ref \"\\n  \", before:\nc: func();",
            ])
    }

    @Test func differingSeparatorNamesTheItem() {
        let ours = block([item("\n  ", "f: func();"), item("\n  ", "g: func();"), item("\n\n  ", "h: func();")])
        let ref = block([item("\n  ", "f: func();"), item("\n\n  ", "g: func();"), item("\n\n  ", "h: func();")])
        #expect(
            mismatches(ours: ours, ref: ref)
                == ["text in front of an item differs: ours \"\\n  \", ref \"\\n\\n  \", before:\ng: func();"])
    }

    @Test func blankLineMovedToTheOpeningIsReported() {
        let ours = block([item("\n\n  ", "f: func();"), item("\n  ", "g: func();")])
        let ref = block([item("\n  ", "f: func();"), item("\n\n  ", "g: func();")])
        #expect(
            mismatches(ours: ours, ref: ref) == [
                "text after `{` differs: ours \"\\n\\n  \", ref \"\\n  \"",
                "text in front of an item differs: ours \"\\n  \", ref \"\\n\\n  \", before:\ng: func();",
            ])
    }

    @Test func itemMovedToTheFrontKeepsItsSeparatorOutOfTheComparison() {
        let ours = block([item("\n  ", "f: func();"), item("\n\n  ", "g: func();")])
        let ref = block([item("\n  ", "g: func();"), item("\n\n  ", "f: func();")])
        #expect(mismatches(ours: ours, ref: ref).isEmpty)
    }

    @Test func differingClosingSeparator() {
        let ours = block([item("\n  ", "f: func();")], closing: "\n\n")
        let ref = block([item("\n  ", "f: func();")])
        #expect(mismatches(ours: ours, ref: ref) == ["text before `}` differs: ours \"\\n\\n\", ref \"\\n\""])
    }

    @Test func duplicatedItemIsReportedAsExtraOnly() {
        let ours = block([item("\n  ", "f: func();"), item("\n  ", "f: func();")])
        let ref = block([item("\n  ", "f: func();")])
        let messages = mismatches(ours: ours, ref: ref)
        #expect(messages == ["extra item not in reference:\nf: func();"])
    }

    @Test func extraItemIsNamedByItsOwnText() {
        let ours = block([item("\n  ", "a: func();"), item("\n\n  ", "b: func();")])
        let ref = block([item("\n  ", "a: func();")])
        #expect(mismatches(ours: ours, ref: ref) == ["extra item not in reference:\nb: func();"])
    }

    @Test func missingItemIsReportedWithoutSeparatorNoise() {
        let ours = block([item("\n  ", "a: func();"), item("\n\n  ", "c: func();")])
        let ref = block([item("\n  ", "a: func();"), item("\n\n  ", "b: func();"), item("\n\n  ", "c: func();")])
        let messages = mismatches(ours: ours, ref: ref)
        #expect(messages == ["missing item from reference:\nb: func();"])
    }

    @Test func headerMismatchStopsComparison() {
        var ours = block([item("\n  ", "f: func();")])
        ours.header = "interface b {"
        let ref = block([item("\n  ", "g: func();")])
        let messages = mismatches(ours: ours, ref: ref)
        #expect(messages.count == 1 && messages[0].hasPrefix("header mismatch"))
    }
}

@Suite struct FormatterMismatchTests {
    private let ref = InterfaceBlock(
        header: "interface a {", items: [item("\n  ", "f: func();")], closingSeparator: "\n")

    @Test func matchingOutputHasNoMismatch() {
        #expect(formatterMismatches("interface a {\n  f: func();\n}\n", key: "a", ref: ref).isEmpty)
    }

    @Test func extraItemIsReported() {
        let messages = formatterMismatches("interface a {\n  f: func();\n\n  g: func();\n}\n", key: "a", ref: ref)
        #expect(messages == ["extra item not in reference:\ng: func();"])
    }

    @Test func textOutsideTheInterfaceIsReported() {
        let output = "interface a {\n  f: func();\n}\n\ninterface b {}\n"
        #expect(formatterMismatches(output, key: "a", ref: ref) == ["formatter output has text outside the interface:\n\(output)"])
    }

    @Test func droppedAttributeIsReportedAsHeaderMismatch() {
        var attributed = ref
        attributed.header = "@since(version = 0.2.0)\ninterface a {"
        #expect(
            formatterMismatches("interface a {\n  f: func();\n}\n", key: "a", ref: attributed)
                == ["header mismatch:\n  ours: interface a {\n   ref: @since(version = 0.2.0)\ninterface a {"])
    }

    @Test func missingInterfaceIsReported() {
        let messages = formatterMismatches("interface b {\n  f: func();\n}\n", key: "a", ref: ref)
        #expect(messages == ["formatter output has no interface 'a'\ninterface b {\n  f: func();\n}\n"])
    }

    @Test func unparsableOutputIsReported() {
        let messages = formatterMismatches("interface a {\n  bogus\n}\n", key: "a", ref: ref)
        #expect(messages.count == 1 && messages[0].hasPrefix("formatter output does not parse:"))
    }
}
