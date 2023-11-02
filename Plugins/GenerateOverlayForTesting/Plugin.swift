import PackagePlugin
import Foundation

@main
struct Plugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let witTool = try context.tool(named: "WITTool").path
        let fixturesDir = target.directory.appending("Fixtures")
        let hostOverlayDir = context.pluginWorkDirectory.appending("GeneratedHostOverlay")
        return try FileManager.default.contentsOfDirectory(atPath: fixturesDir.string).compactMap { singleFixture in
            let outputFile = hostOverlayDir.appending(singleFixture + "HostOverlay.swift")
            let inputFileDir = fixturesDir.appending(singleFixture, "wit")
            guard FileManager.default.isDirectory(filePath: inputFileDir.string) else { return nil }

            let inputFiles = try FileManager.default.subpathsOfDirectory(atPath: inputFileDir.string).map {
                inputFileDir.appending(subpath: $0)
            }
            return Command.buildCommand(
                displayName: "Generating host overlay for \(singleFixture)",
                executable: witTool,
                arguments: [
                    "generate-overlay", "--target", "host",
                    inputFileDir, "-o", outputFile
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
