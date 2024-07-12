import Foundation

enum Spectest {
    static let rootDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // WATTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Root
    static let vendorDirectory: URL = rootDirectory
        .appendingPathComponent("Vendor")

    static var testsuitePath: URL { Self.vendorDirectory.appendingPathComponent("testsuite") }

    static func path(_ file: String) -> URL {
        testsuitePath.appendingPathComponent(file)
    }

    static func wastFiles(include: [String] = [], exclude: [String] = ["annotations.wast"]) -> AnyIterator<URL> {
        var allFiles = try! FileManager.default.contentsOfDirectory(at: testsuitePath, includingPropertiesForKeys: nil).makeIterator()
        return AnyIterator {
            while let filePath = allFiles.next() {
                guard filePath.pathExtension == "wast" else {
                    continue
                }
                guard !filePath.lastPathComponent.starts(with: "simd_") else { continue }
                if !include.isEmpty {
                    guard include.contains(filePath.lastPathComponent) else { continue }
                } else {
                    guard !exclude.contains(filePath.lastPathComponent) else { continue }
                }
                return filePath
            }
            return nil
        }
    }

    static func moduleFiles(json: URL) throws -> [(binary: URL, name: String?)] {
        let content = try String(contentsOf: json)
        var modules: [(binary: URL, name: String?)] = []
        for line in content.split(separator: "\n") {
            let pattern = #/\{"type": "module", "line": (?<line>\d+), ("name": "(?<name>.+)", )?"filename": "(?<fileName>.+)"\}/#
            guard let match = line.firstMatch(of: pattern) else { continue }
            let binary = json.deletingLastPathComponent().appendingPathComponent(String(match.output.fileName))
            modules.append((binary, match.output.name.map(String.init)))
        }
        return modules
    }
}
