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

private func wasiPackageNames() throws -> [String] {
    guard FileManager.default.fileExists(atPath: wasiProposalsPath) else { return [] }
    return try FileManager.default.contentsOfDirectory(atPath: wasiProposalsPath)
        .filter { FileManager.default.fileExists(atPath: "\(wasiProposalsPath)/\($0)/wit") }
        .sorted()
}

/// The `wit` directory of every package that the package in `witDirectory` depends on, directly or
/// through another dependency, keyed by package name.
///
/// Each `wit` directory lists its direct dependencies in `deps.toml`, one `name = "path"` line each,
/// with the path relative to that directory.
private func wasiDependencies(of witDirectory: String) throws -> [String: String] {
    var dependencies: [String: String] = [:]
    var pending = [witDirectory]
    while let directory = pending.popLast() {
        let manifestPath = "\(directory)/deps.toml"
        guard FileManager.default.fileExists(atPath: manifestPath) else { continue }
        for line in try String(contentsOfFile: manifestPath, encoding: .utf8).split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            try #require(
                parts.count == 2 && parts[1].count >= 2 && parts[1].hasPrefix("\"") && parts[1].hasSuffix("\""),
                "unexpected line in \(manifestPath): \(line)")
            let path = URL(
                fileURLWithPath: String(parts[1].dropFirst().dropLast()),
                relativeTo: URL(fileURLWithPath: directory, isDirectory: true)
            ).standardizedFileURL.path
            if dependencies.updateValue(path, forKey: parts[0]) == nil {
                pending.append(path)
            }
        }
    }
    return dependencies
}

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
        /// `wasm-tools` prints the formatted source files of `package` exactly as it prints the
        /// original ones.
        @Test(arguments: try wasiPackageNames())
        func formattedPackageMatchesSource(package: String) throws {
            let witDirectory = "\(wasiProposalsPath)/\(package)/wit"
            var dependencies: [String: String] = [:]
            for (name, directory) in try wasiDependencies(of: witDirectory) {
                dependencies["/package/deps/\(name)"] = directory
            }
            var sourceDirectories = dependencies
            sourceDirectories["/package"] = witDirectory
            let source = try componentWit(packagePath: "/package", directories: sourceDirectories, noDocs: false)

            let formattedFiles = try parsePackage(package).sourceFiles.map { file in
                WasmToolsInputFile(
                    guestPath: "/package/\(URL(fileURLWithPath: file.fileName).lastPathComponent)",
                    content: WITFormatter.format(sourceFile: file.syntax)
                )
            }
            let formatted = try componentWit(
                packagePath: "/package", directories: dependencies, files: formattedFiles, noDocs: false)

            #expect(
                formatted.split(separator: "\n", omittingEmptySubsequences: false)
                    == source.split(separator: "\n", omittingEmptySubsequences: false))
        }
    #endif

    @Test func resolveAllWASIp2Packages() throws {
        let names = try wasiPackageNames()
        let packageResolver = PackageResolver()
        for name in names {
            packageResolver.register(packageUnit: try parsePackage(name))
        }
        #expect(packageResolver.packages.count == names.count)
    }

    /// Formatting a source file, parsing the output and formatting it again gives the same text.
    @Test(arguments: try wasiPackageNames())
    func formatIsIdempotent(package: String) throws {
        for file in try parsePackage(package).sourceFiles {
            let once = WITFormatter.format(sourceFile: file.syntax)
            let reparsed = try SourceFileSyntax.parse(once, fileName: file.fileName)
            #expect(WITFormatter.format(sourceFile: reparsed.syntax) == once, "\(file.fileName)")
        }
    }
}
