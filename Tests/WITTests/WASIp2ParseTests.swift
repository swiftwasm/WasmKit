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
        /// Format a parsed package with our formatter and compare each interface/world
        /// against wasm-tools reference output.
        ///
        /// wasm-tools may reorder interfaces (dependency order), so we compare
        /// per-interface/world rather than the whole file.
        private func assertMatchesReference(_ name: String, deps: [String] = []) throws {
            // 1. Parse with our parser
            let pkg = try parsePackage(name)

            // 2. Get reference output from wasm-tools, then parse it to extract
            //    per-interface/world blocks
            let referenceOutput = try getReferenceOutput(name, deps: deps)
            let referenceBlocks = extractBlocks(from: referenceOutput)

            // 3. Format each interface/world with our formatter and compare
            for sourceFile in pkg.sourceFiles {
                for item in sourceFile.items {
                    switch item {
                    case .interface(let iface):
                        var formatter = WITFormatter(output: "")
                        formatter.write(interface: iface.syntax, indent: 0)
                        let ourBlock = formatter.output
                        let key = iface.name.text
                        guard let refBlock = referenceBlocks[key] else {
                            Issue.record("\(name): interface '\(key)' not found in wasm-tools output")
                            continue
                        }
                        compareBlocks(name: "\(name)/\(key)", ours: ourBlock, ref: refBlock)
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
        }

        /// Extract top-level interface/world blocks from wasm-tools output, keyed by name.
        private func extractBlocks(from text: String) -> [String: String] {
            var blocks: [String: String] = [:]
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var i = 0
            while i < lines.count {
                let line = lines[i]
                // Detect start of an interface or world block (possibly preceded by attributes)
                var blockStart = i
                // Look back to include attribute lines
                while blockStart > 0 && lines[blockStart - 1].hasPrefix("@") {
                    blockStart -= 1
                }
                // Skip empty lines before attributes
                if line.hasPrefix("interface ") || line.hasPrefix("world ") {
                    let name: String
                    if line.hasPrefix("interface ") {
                        name = String(line.dropFirst("interface ".count).prefix(while: { $0 != " " && $0 != "{" }))
                    } else {
                        name = String(line.dropFirst("world ".count).prefix(while: { $0 != " " && $0 != "{" }))
                    }
                    // Find the closing `}`
                    var depth = 0
                    var blockEnd = i
                    for j in i..<lines.count {
                        if lines[j].contains("{") { depth += 1 }
                        if lines[j].contains("}") { depth -= 1 }
                        if depth == 0 {
                            blockEnd = j
                            break
                        }
                    }
                    let blockLines = lines[blockStart...blockEnd]
                    blocks[name] = blockLines.joined(separator: "\n") + "\n"
                    i = blockEnd + 1
                } else {
                    i += 1
                }
            }
            return blocks
        }

        /// Compare two interface/world blocks by splitting into individual items
        /// and comparing as sets. This tolerates ordering differences (the WIT spec
        /// says item order within interfaces has no semantic impact).
        private func compareBlocks(name: String, ours: String, ref: String) {
            let ourItems = splitIntoItems(ours)
            let refItems = splitIntoItems(ref)

            // Check header line matches (e.g., "@since...\ninterface foo {")
            if ourItems.header != refItems.header {
                Issue.record(
                    """
                    \(name): header mismatch:
                      ours: \(ourItems.header)
                       ref: \(refItems.header)
                    """)
                return
            }

            // Compare items as sets
            let ourSet = Set(ourItems.items)
            let refSet = Set(refItems.items)

            let missing = refSet.subtracting(ourSet)
            let extra = ourSet.subtracting(refSet)

            for item in missing.sorted() {
                Issue.record("\(name): missing item from reference:\n\(item)")
            }
            for item in extra.sorted() {
                Issue.record("\(name): extra item not in reference:\n\(item)")
            }
        }

        private struct SplitBlock {
            var header: String  // attributes + opening line
            var items: [String]  // individual items separated by blank lines
        }

        /// Split an interface/world block into header + individual items.
        /// Items within the block are separated by blank lines.
        private func splitIntoItems(_ block: String) -> SplitBlock {
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard lines.count >= 2 else { return SplitBlock(header: block, items: []) }

            // Find the opening `{` line
            var headerEnd = 0
            for (i, line) in lines.enumerated() {
                if line.hasSuffix("{") {
                    headerEnd = i
                    break
                }
            }

            let header = lines[0...headerEnd].joined(separator: "\n")

            // Split body into items (groups of non-empty lines separated by blank lines)
            var items: [String] = []
            var current: [String] = []
            for line in lines[(headerEnd + 1)...] {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    if !current.isEmpty {
                        items.append(current.joined(separator: "\n"))
                        current = []
                    }
                } else if line.trimmingCharacters(in: .whitespaces) == "}" {
                    if !current.isEmpty {
                        items.append(current.joined(separator: "\n"))
                        current = []
                    }
                } else {
                    current.append(line)
                }
            }
            if !current.isEmpty {
                items.append(current.joined(separator: "\n"))
            }

            return SplitBlock(header: header, items: items)
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
