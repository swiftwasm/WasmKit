import PackagePlugin
import Foundation

@main
struct Plugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var argumentExtractor = ArgumentExtractor(arguments)
        let targets = argumentExtractor.extractOption(named: "target")
        let sdk = argumentExtractor.extractOption(named: "sdk").last
        let outputMappingPath = argumentExtractor.extractOption(named: "output-mapping").last
        let parameters = PackageManager.BuildParameters()
        for target in targets {
            try extractFromTarget(target: target, sdk: sdk, outputMappingPath: outputMappingPath, parameters: parameters, context: context)
        }
    }

    func extractFromTarget(
        target: String,
        sdk: String?,
        outputMappingPath: String?,
        parameters: PackageManager.BuildParameters,
        context: PluginContext
    ) throws {
        let buildResult = try packageManager.build(.target(target), parameters: parameters)
        guard buildResult.succeeded else {
            throw PluginError(description: "Failed to build \(target): \(buildResult.logText)")
        }
        // TODO: Add proper API to PackagePlugin to get data directory
        let dataPath = context.pluginWorkDirectoryURL // output
            .deletingLastPathComponent() // WITExtractorPlugin
            .deletingLastPathComponent() // plugins
            .deletingLastPathComponent() // .build (by default)

        let buildPath = dataPath.appendingPathComponent(parameters.configuration.rawValue)
        let llbuildManifest = dataPath.appendingPathComponent(parameters.configuration.rawValue + ".yaml")
        guard let swiftcExecutable = ProcessInfo.processInfo.environment["WIT_EXTRACTOR_SWIFTC_PATH"]
                ?? inferSwiftcExecutablePath(llbuildManifest: llbuildManifest) else {
            throw PluginError(description: "Cloudn't infer `swiftc` command path from build directory. Please specify WIT_EXTRACTOR_SWIFTC_PATH")
        }
        let digesterExecutable = URL(fileURLWithPath: swiftcExecutable).deletingLastPathComponent().appendingPathComponent("swift-api-digester")

        let witOutputPath = context.pluginWorkDirectoryURL.appendingPathComponent(target + ".wit")
        let swiftOutputPath = context.pluginWorkDirectoryURL.appendingPathComponent(target + "_WITOverlay.swift")

        let tool = try context.tool(named: "WITTool")
        var arguments =  [
            "extract-wit",
            "--swift-api-digester", digesterExecutable.path,
            "--module-name", target,
            "--package-name", context.package.displayName,
            "--wit-output-path", witOutputPath.path,
            "--swift-output-path", swiftOutputPath.path,
            "-I", buildPath.appendingPathComponent("Modules").path,
        ]

        #if compiler(<6.0)
        // Swift 5.10 and earlier emit module files under the per-configuration build directory
        // instead of the Modules directory.
        arguments += [
            "-I", buildPath.path,
        ]
        #endif
        if let sdk {
            arguments += ["-sdk", sdk]
        }
        let process = try Process.run(tool.url, arguments: arguments)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PluginError(
                description: "Failed to run \(([tool.url.path] + arguments).joined(separator: " "))"
            )
        }

        let outputMapping = """
        {
            "witOutputPath": "\(witOutputPath.path)",
            "swiftOutputPath": "\(swiftOutputPath.path)"
        }
        """
        if let outputMappingPath {
            try outputMapping.write(to: URL(fileURLWithPath: outputMappingPath), atomically: true, encoding: .utf8)
        } else {
            print(outputMapping)
        }
    }

    func inferSwiftcExecutablePath(llbuildManifest: URL) -> String? {
        // FIXME: This is completely not the right way but there is no right way for now...
        guard let contents = try? String(contentsOfFile: llbuildManifest.path, encoding: .utf8) else {
            return nil
        }
        for line in contents.split(separator: "\n") {
            do {
                let prefix = "    executable: \""
                if line.hasPrefix(prefix), line.hasSuffix("/swiftc\"") {
                    let pathStart = line.index(line.startIndex, offsetBy: prefix.count)
                    let pathEnd = line.index(before: line.endIndex)
                    let executablePath = line[pathStart..<pathEnd]
                    return String(executablePath)
                }
            }
            do {
                // Swift 6.0 no longer uses llbuild's built-in swift tool. Instead,
                // it uses the generic shell tool with full arguments.
                // https://github.com/swiftlang/swift-package-manager/pull/6585
                let prefix = "    args: "
                if line.hasPrefix(prefix) {
                    let argsString = line[line.index(line.startIndex, offsetBy: prefix.count)...]
                    guard let args = try? JSONDecoder().decode([String].self, from: Data(argsString.utf8)),
                      let swiftc = args.first(where: { $0.hasSuffix("/swiftc") }) else {
                        continue
                    }
                    return swiftc
                }
            }
        }
        return nil
    }
}

struct PluginError: Error, CustomStringConvertible {
    let description: String
}
