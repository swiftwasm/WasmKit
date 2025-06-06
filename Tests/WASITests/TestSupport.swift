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

    class TemporaryDirectory {
        let path: String
        var url: URL { URL(fileURLWithPath: path) }

        init() throws {
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
                    #if os(Android)
                    throw Error(errno: __errno().pointee)
                    #else
                    throw Error(errno: errno)
                    #endif
                }
            #endif

            self.path = String(cString: template)
        }

        func createDir(at relativePath: String) throws {
            let directoryURL = url.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        func createFile(at relativePath: String, contents: String) throws {
            let fileURL = url.appendingPathComponent(relativePath)
            guard let data = contents.data(using: .utf8) else { return }
            FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        }

        func createSymlink(at relativePath: String, to target: String) throws {
            let linkURL = url.appendingPathComponent(relativePath)
            try FileManager.default.createSymbolicLink(
                atPath: linkURL.path,
                withDestinationPath: target
            )
        }

        deinit {
            _ = try? FileManager.default.removeItem(atPath: path)
        }
    }
}
