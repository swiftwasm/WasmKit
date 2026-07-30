import Foundation

/// Minimal file helpers for CLI commands, built on Foundation.
enum CLIFile {
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    static func openRead(_ path: String) throws -> FileHandle {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            throw Error(description: "Failed to open file: \(path)")
        }
        return handle
    }

    static func createWrite(_ path: String) throws -> FileHandle {
        guard FileManager.default.createFile(atPath: path, contents: nil),
            let handle = FileHandle(forWritingAtPath: path)
        else {
            throw Error(description: "Failed to create file: \(path)")
        }
        return handle
    }
}
