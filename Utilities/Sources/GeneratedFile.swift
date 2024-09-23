import Foundation

/// A unit of code-generation output file.
struct GeneratedFile {
    let pathComponents: [String]
    let content: String

    init(_ pathComponents: [String], _ content: String) {
        self.pathComponents = pathComponents
        self.content = content
    }

    func writeIfChanged(sourceRoot: URL) throws {
        let subPath = pathComponents.joined(separator: "/")
        let path = sourceRoot.appendingPathComponent(subPath)
        // Write the content only if the file does not exist or the content is different
        let shouldWrite: Bool
        if !FileManager.default.fileExists(atPath: path.path) {
            shouldWrite = true
        } else {
            let existingContent = try String(contentsOf: path)
            shouldWrite = existingContent != content
        }

        if shouldWrite {
            try content.write(to: path, atomically: true, encoding: .utf8)
            print("\u{001B}[1;33mUpdated\u{001B}[0;0m \(subPath)")
        }
    }
}
