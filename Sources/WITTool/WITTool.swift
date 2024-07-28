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

    @Option
    var target: Target

    @Argument
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

    @Option(name: .customLong("swift-api-digester"))
    var digesterPath: String

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

    @Argument(parsing: .captureForPassthrough)
    var digesterArgs: [String] = []

    func run() throws {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            fatalError("WITExtractor does not support platforms where Foundation.Process is unavailable")
        #else
            guard #available(macOS 11, *) else {
                fatalError("ExtractWIT requires macOS 11+")
            }

            let extractor = WITExtractor(
                namespace: namespace,
                packageName: packageName,
                digesterPath: digesterPath,
                extraDigesterArguments: digesterArgs
            )
            let output = try extractor.run(moduleName: moduleName)
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
                    sourceSummaryProvider: SwiftSourceSummaryProvider(
                        summary: output.sourceSummary,
                        typeMapping: output.typeMapping
                    )
                )
                try swiftSource.write(toFile: swiftOutputPath, atomically: true, encoding: .utf8)
            }
        #endif
    }

    private func writeFile(_ filePath: String, contents: String) throws {
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}

struct SwiftSourceSummaryProvider: SourceSummaryProvider {
    let summary: SwiftSourceSummary
    let typeMapping: (String) -> String?

    func enumCaseNames(byWITName witName: String) -> [String]? {
        guard case let .enumType(enumType) = summary.lookupType(byWITName: witName) else {
            return nil
        }
        return enumType.cases.map(\.name)
    }

    public func qualifiedSwiftTypeName(byWITName witName: String) -> String? {
        typeMapping(witName)
    }
}
