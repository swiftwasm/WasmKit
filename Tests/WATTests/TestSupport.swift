import Foundation
import WAT

@testable import WasmParser

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
        var template = [UInt8](templatePath.path.utf8).map({ UInt8($0) }) + [UInt8(0)]

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

        let path = String(decoding: template.dropLast(), as: UTF8.self)
        var shouldRetain = false
        defer {
            if !shouldRetain {
                _ = try? FileManager.default.removeItem(atPath: path)
            }
        }
        return try body(path, &shouldRetain)
    }

    static func lookupExecutable(_ name: String) -> URL? {
        let envName = "\(name.uppercased())_EXEC"
        if let path = ProcessInfo.processInfo.environment[envName] {
            let url = URL(fileURLWithPath: path).deletingLastPathComponent().appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
            print("Executable path \(url.path) specified by \(envName) is not found or not executable, falling back to PATH lookup")
        }
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

    /// The id and content range of each section in `bytes` from offset `start`.
    static func sections(in bytes: [UInt8], from start: Int = 8) throws -> [(id: UInt8, content: Range<Int>)] {
        var stream = ByteStream(StaticByteStreamSource(bytes: bytes))
        stream.currentIndex = start
        var sections: [(id: UInt8, content: Range<Int>)] = []
        while try !stream.hasReachedEnd() {
            let id = try stream.consumeAny()
            let length = Int(try decodeLEB128(stream: &stream) as UInt32)
            sections.append((id, stream.currentIndex..<(stream.currentIndex + length)))
            _ = try stream.consume(count: length)
        }
        return sections
    }

    /// The content of the first section with id `id` in `bytes`, read from offset `start`.
    static func section(_ id: UInt8, in bytes: [UInt8], from start: Int = 8) throws -> [UInt8]? {
        try sections(in: bytes, from: start).first { $0.id == id }.map { Array(bytes[$0.content]) }
    }

    /// The binary module that `source` describes. `features` applies to a quoted module.
    static func encode(_ source: ModuleSource, features: WasmFeatureSet = .default) throws -> [UInt8] {
        switch source {
        case .text(let wat):
            return try wat.encode()
        case .quote(let text):
            return try wat2wasm(String(decoding: text, as: UTF8.self), features: features)
        case .binary(let bytes):
            return bytes
        }
    }

    /// The message of the error `body` throws, or nil if it throws none.
    static func errorMessage(_ body: () throws -> Void) -> String? {
        do {
            try body()
            return nil
        } catch let error as WatParserError {
            return error.message
        } catch {
            return "\(error)"
        }
    }
}
