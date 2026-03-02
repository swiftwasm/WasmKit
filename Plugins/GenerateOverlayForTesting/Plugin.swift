import PackagePlugin
import Foundation

@main
struct Plugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let witTool = try context.tool(named: "WITTool").url
        let fixturesDir = target.directoryURL.appendingPathComponent("Fixtures")
        let hostOverlayDir = context.pluginWorkDirectoryURL.appendingPathComponent("GeneratedHostOverlay")
        return try FileManager.default.contentsOfDirectory(atPath: fixturesDir.path).compactMap { singleFixture in
            let outputFile = hostOverlayDir.appendingPathComponent(singleFixture + "HostOverlay.swift")
            let inputFileDir = fixturesDir.appendingPathComponent(singleFixture).appendingPathComponent("wit")
            guard FileManager.default.isDirectory(filePath: inputFileDir.path) else { return nil }

            let inputFiles = try FileManager.default.subpathsOfDirectory(atPath: inputFileDir.path).map {
                inputFileDir.appendingPathComponent($0)
            }
            return Command.buildCommand(
                displayName: "Generating host overlay for \(singleFixture)",
                executable: witTool,
                arguments: [
                    "generate-overlay", "--target", "host",
                    inputFileDir.path, "-o", outputFile.path
                ],
                inputFiles: inputFiles,
                outputFiles: [outputFile]
            )
        }
    }
}

extension FileManager {
    internal func isDirectory(filePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: filePath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
