import PackagePlugin
import Foundation

@main
struct Plugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var argumentExtractor = ArgumentExtractor(arguments)
        let targetNames = argumentExtractor.extractOption(named: "target")
        let outputMappingPath = argumentExtractor.extractOption(named: "output-mapping").last
        for targetName in targetNames {
            try extractFromTarget(named: targetName, outputMappingPath: outputMappingPath, context: context)
        }
    }

    func extractFromTarget(named targetName: String, outputMappingPath: String?, context: PluginContext) throws {
        guard let target = context.package.targets.first(where: { $0.name == targetName }) else {
            throw PluginError(description: "No target named '\(targetName)' in package '\(context.package.displayName)'")
        }
        guard let sourceModule = target as? SwiftSourceModuleTarget else {
            throw PluginError(description: "Target '\(targetName)' is not a Swift source module")
        }
        let sourcePaths = sourceModule.sourceFiles
            .filter { $0.type == .source && $0.url.pathExtension == "swift" }
            .map { $0.url.path }
        guard !sourcePaths.isEmpty else {
            throw PluginError(description: "Target '\(targetName)' has no Swift source files to extract WIT from")
        }

        let witOutputPath = context.pluginWorkDirectoryURL.appendingPathComponent(targetName + ".wit")
        let swiftOutputPath = context.pluginWorkDirectoryURL.appendingPathComponent(targetName + "_WITOverlay.swift")

        // Dependency-module sources, so a `@WIT` decl that references a type declared in a dependency can be
        // resolved and inlined into the emitted interface. `compactMap` to `SwiftSourceModuleTarget` drops
        // binary/system targets that carry no parseable Swift source.
        let dependencyArguments: [String] = sourceModule.recursiveTargetDependencies
            .compactMap { $0 as? SwiftSourceModuleTarget }
            .flatMap { dependency in
                dependency.sourceFiles
                    .filter { $0.type == .source && $0.url.pathExtension == "swift" }
                    .flatMap { ["--dependency-source", "\(dependency.name)=\($0.url.path)"] }
            }

        let tool = try context.tool(named: "WITTool")
        let arguments = [
            "extract-wit",
            "--module-name", targetName,
            "--package-name", context.package.displayName,
            "--wit-output-path", witOutputPath.path,
            "--swift-output-path", swiftOutputPath.path,
        ] + dependencyArguments + sourcePaths

        // WITTool writes only diagnostics to stderr. Capture them so drop/skip warnings are observable
        // deterministically via the output-mapping JSON, not only via SwiftPM's stderr forwarding.
        let process = Process()
        process.executableURL = tool.url
        process.arguments = arguments
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        try process.run()
        // readDataToEndOfFile drains as the child writes, so a large stderr cannot deadlock waitUntilExit.
        let diagnosticsData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let diagnostics = String(decoding: diagnosticsData, as: UTF8.self)
        guard process.terminationStatus == 0 else {
            throw PluginError(
                description: "\(([tool.url.path] + arguments).joined(separator: " ")) failed:\n\(diagnostics)")
        }

        let mapping = OutputMapping(
            witOutputPath: witOutputPath.path, swiftOutputPath: swiftOutputPath.path, diagnostics: diagnostics)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let mappingJSON = String(decoding: try encoder.encode(mapping), as: UTF8.self)
        if let outputMappingPath {
            try mappingJSON.write(to: URL(fileURLWithPath: outputMappingPath), atomically: true, encoding: .utf8)
        } else {
            print(mappingJSON)
        }
    }
}

struct OutputMapping: Encodable {
    let witOutputPath: String
    let swiftOutputPath: String
    let diagnostics: String
}

struct PluginError: Error, CustomStringConvertible {
    let description: String
}
