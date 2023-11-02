import PackagePlugin
import Foundation

@main
struct Plugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        if !target.recursiveTargetDependencies.contains(where: { $0.name == "_CabiShims" }) {
            Diagnostics.emit(.error, "\"_CabiShims\" must be included as a dependency")
        }
        let witTool = try context.tool(named: "WITTool").path
        let witDir = target.directory.appending("wit")
        let inputFiles = try FileManager.default.subpathsOfDirectory(atPath: witDir.string).map {
            witDir.appending(subpath: $0)
        }
        let outputFile = context.pluginWorkDirectory.appending("GeneratedOverlay", "\(target.name)Overlay.swift")
        let command = Command.buildCommand(
            displayName: "Generating WIT overlay for \(target.name)",
            executable: witTool,
            arguments: [
                "generate-overlay", "--target", "guest",
                witDir, "-o", outputFile
            ],
            inputFiles: inputFiles,
            outputFiles: [outputFile]
        )
        return [command]
    }
}

extension FileManager {
    internal func isDirectory(filePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: filePath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
