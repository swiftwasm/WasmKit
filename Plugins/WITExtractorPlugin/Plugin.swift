import PackagePlugin
import Foundation

@main
struct Plugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var argumentExtractor = ArgumentExtractor(arguments)
        let targets = argumentExtractor.extractOption(named: "target")
        let sdk = argumentExtractor.extractOption(named: "sdk").last
        let parameters = PackageManager.BuildParameters()
        for target in targets {
            try extractFromTarget(target: target, sdk: sdk, parameters: parameters, context: context)
        }
    }

    func extractFromTarget(
        target: String,
        sdk: String?,
        parameters: PackageManager.BuildParameters,
        context: PluginContext
    ) throws {
        let buildResult = try packageManager.build(.target(target), parameters: parameters)
        guard buildResult.succeeded else {
            throw PluginError(description: "Failed to build \(target): \(buildResult.logText)")
        }
        // FIXME: Don't assume build directory to be ".build" because it can be configured --scratch-path
        let dataPath = context.package.directory.appending([".build"])
        let buildPath = dataPath.appending([parameters.configuration.rawValue])
        let llbuildManifest = dataPath.appending([parameters.configuration.rawValue + ".yaml"])
        guard let swiftcExecutable = ProcessInfo.processInfo.environment["WIT_EXTRACTOR_SWIFTC_PATH"]
                ?? inferSwiftcExecutablePath(llbuildManifest: llbuildManifest) else {
            throw PluginError(description: "Cloudn't infer `swiftc` command path from build directory. Please specify WIT_EXTRACTOR_SWIFTC_PATH")
        }
        let digesterExecutable = Path(swiftcExecutable).removingLastComponent().appending(["swift-api-digester"])
        let tool = try context.tool(named: "WITTool")
        var arguments =  [
            "extract-wit",
            "--swift-api-digester", digesterExecutable.string,
            "--module-name", target,
            "--package-name", context.package.displayName,
            "-I", buildPath.string
        ]
        if let sdk {
            arguments += ["-sdk", sdk]
        }
        let process = try Process.run(URL(fileURLWithPath: tool.path.string), arguments: arguments)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PluginError(
                description: "Failed to run \(([tool.path.string] + arguments).joined(separator: " "))"
            )
        }
    }

    func inferSwiftcExecutablePath(llbuildManifest: Path) -> String? {
        // FIXME: This is completely not the right way but there is no right way for now...
        guard let contents = try? String(contentsOfFile: llbuildManifest.string, encoding: .utf8) else {
            return nil
        }
        for line in contents.split(separator: "\n") {
            let prefix = "    executable: \""
            if line.hasPrefix(prefix), line.hasSuffix("/swiftc\"") {
                let pathStart = line.index(line.startIndex, offsetBy: prefix.count)
                let pathEnd = line.index(before: line.endIndex)
                let executablePath = line[pathStart..<pathEnd]
                return String(executablePath)
            }
        }
        return nil
    }
}

struct PluginError: Error, CustomStringConvertible {
    let description: String
}
