import ArgumentParser
import Foundation
import WIT
import WITExtractor
import WITOverlayGenerator

@main
struct WITTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wit-tool",
        abstract: "WIT-related tool set",
        subcommands: [Validate.self, GenerateOverlay.self, ExtractWIT.self]
    )

    /// Create a semantics analysis context by loading the given `wit` directory or `.wit` file path.
    static func deriveSemanticsContext(path: String, loader: LocalFileLoader) throws -> SemanticsContext {
        let packageResolver: PackageResolver
        let mainPackage: PackageUnit
        if FileManager.default.isDirectory(filePath: path) {
            (mainPackage, packageResolver) = try PackageResolver.parse(
                directory: path, loader: loader
            )
        } else {
            packageResolver = PackageResolver()
            let sourceFile = try SourceFileSyntax.parse(filePath: path, loader: loader)
            mainPackage = try packageResolver.register(packageSources: [sourceFile])
        }

        return SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
    }
}

struct Validate: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate a WIT package"
    )

    @Argument
    var path: String

    func run() throws {
        let loader = LocalFileLoader()
        let context = try WITTool.deriveSemanticsContext(path: path, loader: loader)
        let diagnostics = try context.validate(package: context.rootPackage)
        for (fileName, diagnostics) in diagnostics {
            let sourceContent = try loader.contentsOfWITFile(at: fileName)
            for diagnostic in diagnostics {
                guard let (line, column) = diagnostic.location(sourceContent) else {
                    print("\(fileName): error: \(diagnostic.message)")
                    continue
                }
                print("\(fileName):\(line):\(column): error: \(diagnostic.message)")
            }
        }
    }
}

struct GenerateOverlay: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate a Swift overlay from a WIT package"
    )

    enum Target: String, ExpressibleByArgument {
        case guest
        case host
    }

    @Option(help: "Whether bindings should be generated for a Wasm guest component or a host Wasm runtime. Possible values: `guest`, `host`. ")
    var target: Target

    @Argument(help: "Path to a `wit` directory or a `.wit` file.")
    var path: String

    @Option(name: .shortAndLong)
    var output: String = "-"

    func run() throws {
        let loader = LocalFileLoader()
        let context = try WITTool.deriveSemanticsContext(path: path, loader: loader)
        let contents: String
        switch target {
        case .guest:
            contents = try WITOverlayGenerator.generateGuest(context: context)
        case .host:
            contents = try WITOverlayGenerator.generateHost(context: context)
        }
        if output == "-" {
            print(contents)
        } else {
            try FileManager.default.createDirectory(
                at: URL(fileURLWithPath: output).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try contents.write(toFile: output, atomically: true, encoding: .utf8)
        }
    }
}

struct ExtractWIT: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "extract-wit"
    )

    struct ExtractWITError: Swift.Error, CustomStringConvertible {
        let description: String
    }

    @Option
    var moduleName: String

    @Option
    var namespace: String = "swift"

    @Option
    var packageName: String

    @Option
    var witOutputPath: String

    @Option
    var swiftOutputPath: String

    /// `<Module>=<path>` pairs.
    @Option(name: .customLong("dependency-source"))
    var dependencySources: [String] = []

    @Argument
    var sourcePaths: [String]

    func run() throws {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
        #else
            let sources = try sourcePaths.map { try String(contentsOfFile: $0, encoding: .utf8) }
            var dependencySourcesByModule: [String: [String]] = [:]
            for spec in dependencySources {
                guard let separator = spec.firstIndex(of: "=") else {
                    throw ExtractWITError(
                        description: "Invalid --dependency-source '\(spec)', expected <Module>=<path>")
                }
                let module = String(spec[..<separator])
                let path = String(spec[spec.index(after: separator)...])
                dependencySourcesByModule[module, default: []].append(
                    try String(contentsOfFile: path, encoding: .utf8))
            }
            let extractor = WITExtractor(
                namespace: namespace, packageName: packageName, sources: sources,
                dependencySources: dependencySourcesByModule)
            let output = extractor.run(moduleName: moduleName)
            try output.witContents.write(toFile: witOutputPath, atomically: true, encoding: .utf8)

            for diagnostic in extractor.diagnostics {
                try FileHandle.standardError.write(contentsOf: Data((diagnostic.description + "\n").utf8))
            }

            // Generate overlay shim to export extracted WIT interface
            do {
                let sourceFile = try SourceFileSyntax.parse(
                    output.witContents,
                    fileName: "<extracted>.wit"
                )
                let packageResolver = PackageResolver()
                let packageUnit = try packageResolver.register(packageSources: [sourceFile])
                let context = SemanticsContext(rootPackage: packageUnit, packageResolver: packageResolver)
                let (interface, _) = try context.lookupInterface(name: output.interfaceName, contextPackage: packageUnit)

                let swiftSource = try generateGuestExportInterface(
                    context: context,
                    sourceFile: sourceFile,
                    interface: interface,
                    sourceSummaryProvider: SwiftSourceSummaryProvider(summary: output.sourceSummary)
                )
                try swiftSource.write(toFile: swiftOutputPath, atomically: true, encoding: .utf8)
            }
        #endif
    }
}

struct SwiftSourceSummaryProvider: SourceSummaryProvider {
    let summary: SwiftSourceSummary

    func enumCaseNames(byWITName witName: String) -> [String]? {
        summary.enumCaseNames(byWITName: witName)
    }

    func recordFieldNames(byWITName witName: String) -> [String]? {
        summary.recordFieldNames(byWITName: witName)
    }

    func qualifiedSwiftTypeName(byWITName witName: String) -> String? {
        summary.qualifiedSwiftName(byWITName: witName)
    }

    func swiftArgumentLabels(byFunctionWITName witName: String) -> [String?]? {
        summary.argumentLabels(byWITFunctionName: witName)
    }
}
