import Foundation

enum TestSupport {
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String

        init(description: String) {
            self.description = description
        }

        init(errno: Int32) {
            self.init(description: String(cString: strerror(errno)))
        }
    }

    static func withTemporaryDirectory<Result>(
        _ body: (String, _ shouldRetain: inout Bool) throws -> Result
    ) throws -> Result {
        let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
        let templatePath = tempdir.appendingPathComponent("WasmKit.XXXXXX")
        var template = [UInt8](templatePath.path.utf8).map({ Int8($0) }) + [Int8(0)]

        #if os(Windows)
        if _mktemp_s(&template, template.count) != 0 {
            throw Error(errno: errno)
        }
        if _mkdir(template) != 0 {
            throw Error(errno: errno)
        }
        #else
        if mkdtemp(&template) == nil {
            throw Error(errno: errno)
        }
        #endif

        let path = String(cString: template)
        var shouldRetain = false
        defer {
            if !shouldRetain {
                _ = try? FileManager.default.removeItem(atPath: path)
            }
        }
        return try body(path, &shouldRetain)
    }

    static func lookupExecutable(_ name: String) -> URL? {
        #if os(Windows)
        let pathEnvVar = "Path"
        let pathSeparator: Character = ";"
        #else
        let pathEnvVar = "PATH"
        let pathSeparator: Character = ":"
        #endif

        let paths = ProcessInfo.processInfo.environment[pathEnvVar] ?? ""
        let searchPaths = paths.split(separator: pathSeparator).map(String.init)
        for path in searchPaths {
            let url = URL(fileURLWithPath: path).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }
        return nil
    }
}
