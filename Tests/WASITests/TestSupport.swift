import Foundation

@_spi(WASIPlatform) @testable import WASI
@testable import WasmKit

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif os(Windows)
    import ucrt
#endif

enum TestSupport {

    #if os(macOS) || os(Linux)
        /// Comparing paths rather than descriptor counts keeps assertions immune to whatever tests
        /// run in parallel.
        static func openDescriptorPaths() throws -> Set<String> {
            #if os(macOS)
                let fdDirectory = "/dev/fd"
            #else
                let fdDirectory = "/proc/self/fd"
            #endif
            var paths: Set<String> = []
            for entry in try FileManager.default.contentsOfDirectory(atPath: fdDirectory) {
                var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
                #if os(macOS)
                    guard let fd = Int32(entry), fcntl(fd, F_GETPATH, &buffer) != -1 else { continue }
                #else
                    let length = readlink("\(fdDirectory)/\(entry)", &buffer, buffer.count - 1)
                    guard length > 0 else { continue }
                    buffer[length] = 0
                #endif
                paths.insert(string(fromCString: buffer))
            }
            return paths
        }

        /// `realpath`, not `URL.resolvingSymlinksInPath()`: the latter leaves a macOS temp path under
        /// `/var/folders`, while the kernel reports descriptors under `/private/var/folders`.
        static func realPath(_ path: String) throws -> String {
            var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
            guard realpath(path, &buffer) != nil else { throw Error(errno: errno) }
            return string(fromCString: buffer)
        }

        private static func string(fromCString buffer: [CChar]) -> String {
            String(decoding: buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
    #endif

    struct Error: Swift.Error, CustomStringConvertible {
        let description: String

        init(description: String) {
            self.description = description
        }

        init(errno: Int32) {
            self.init(description: String(cString: strerror(errno)))
        }
    }

    class TestGuestMemory: GuestMemory {
        private var data: [UInt8]

        init(size: Int = 65536) {
            self.data = Array(repeating: 0, count: size)
        }

        func withUnsafeMutableBufferPointer<T>(
            offset: UInt,
            count: Int,
            _ body: (UnsafeMutableRawBufferPointer) throws -> T
        ) rethrows -> T {
            guard offset + UInt(count) <= data.count else {
                fatalError("Memory access out of bounds")
            }
            return try data.withUnsafeMutableBytes { buffer in
                let start = buffer.baseAddress!.advanced(by: Int(offset))
                let slice = UnsafeMutableRawBufferPointer(start: start, count: count)
                return try body(slice)
            }
        }

        func write(_ bytes: [UInt8], at offset: UInt) {
            data.replaceSubrange(Int(offset)..<Int(offset) + bytes.count, with: bytes)
        }

        func writeIOVecs(_ buffers: [[UInt8]]) -> UnsafeGuestBufferPointer<WASIAbi.IOVec> {
            var currentDataOffset: UInt32 = 0
            let iovecOffset: UInt32 = 32768

            for buffer in buffers {
                write(buffer, at: UInt(currentDataOffset))
                currentDataOffset += UInt32(buffer.count)
            }

            var iovecWriteOffset = iovecOffset
            var dataReadOffset: UInt32 = 0
            for buffer in buffers {
                let iovec = WASIAbi.IOVec(
                    buffer: UnsafeGuestRawPointer(offset: dataReadOffset),
                    length: UInt32(buffer.count)
                )
                WASIAbi.IOVec.writeToGuest(
                    at: UnsafeGuestRawPointer(offset: iovecWriteOffset),
                    in: self,
                    value: iovec
                )
                dataReadOffset += UInt32(buffer.count)
                iovecWriteOffset += WASIAbi.IOVec.sizeInGuest
            }

            return UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                baseAddress: UnsafeGuestPointer(offset: iovecOffset),
                count: UInt32(buffers.count)
            )
        }

        func readIOVecs(sizes: [Int]) -> UnsafeGuestBufferPointer<WASIAbi.IOVec> {
            var currentDataOffset: UInt32 = 0
            let iovecOffset: UInt32 = 32768

            var iovecWriteOffset = iovecOffset
            for size in sizes {
                let iovec = WASIAbi.IOVec(
                    buffer: UnsafeGuestRawPointer(offset: currentDataOffset),
                    length: UInt32(size)
                )
                WASIAbi.IOVec.writeToGuest(
                    at: UnsafeGuestRawPointer(offset: iovecWriteOffset),
                    in: self,
                    value: iovec
                )
                currentDataOffset += UInt32(size)
                iovecWriteOffset += WASIAbi.IOVec.sizeInGuest
            }

            return UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                baseAddress: UnsafeGuestPointer(offset: iovecOffset),
                count: UInt32(sizes.count)
            )
        }

        func loadIOVecs(_ iovecs: UnsafeGuestBufferPointer<WASIAbi.IOVec>) -> [[UInt8]] {
            var result: [[UInt8]] = []

            for i in 0..<Int(iovecs.count) {
                let iovec = (iovecs.baseAddress + UInt32(i)).read(from: self)
                var buffer = [UInt8](repeating: 0, count: Int(iovec.length))

                iovec.buffer.withHostPointer(in: self, count: Int(iovec.length)) { hostBuffer in
                    buffer.withUnsafeMutableBytes { destBuffer in
                        destBuffer.copyMemory(from: UnsafeRawBufferPointer(hostBuffer))
                    }
                }

                result.append(buffer)
            }

            return result
        }
    }

    class TemporaryDirectory {
        let path: String
        var url: URL { URL(fileURLWithPath: path) }

        init() throws {
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

            self.path = String(decoding: template.dropLast(), as: UTF8.self)
        }

        func createDir(at relativePath: String) throws {
            let directoryURL = url.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        func createFile(at relativePath: String, contents: String) throws {
            let fileURL = url.appendingPathComponent(relativePath)
            guard let data = contents.data(using: .utf8) else { return }
            guard FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil) else {
                throw Error(description: "Couldn't create file at \(relativePath)")
            }
        }

        func createSymlink(at relativePath: String, to target: String) throws {
            let linkURL = url.appendingPathComponent(relativePath)
            try FileManager.default.createSymbolicLink(
                atPath: linkURL.path,
                withDestinationPath: target
            )
        }

        #if !os(WASI)
            enum OpenMode {
                case readOnly, writeOnly, readWrite
            }

            /// An opened host file exposing a raw platform file descriptor for
            /// descriptor-based APIs. Foundation's `FileHandle.fileDescriptor`
            /// is unavailable on Windows, so the CRT is used there instead.
            struct OpenedFile {
                let fileDescriptor: CInt
                #if os(Windows)
                    init(fileDescriptor: CInt) {
                        self.fileDescriptor = fileDescriptor
                    }

                    func close() throws {
                        _ = _close(fileDescriptor)
                    }
                #else
                    private let handle: FileHandle

                    init(handle: FileHandle) {
                        self.handle = handle
                        self.fileDescriptor = handle.fileDescriptor
                    }

                    func close() throws {
                        try handle.close()
                    }
                #endif
            }

            /// Opens a file and returns an ``OpenedFile`` carrying a raw
            /// platform file descriptor.
            func openFile(at relativePath: String, _ mode: OpenMode) throws -> OpenedFile {
                let fileURL = url.appendingPathComponent(relativePath)
                #if os(Windows)
                    let oflag: CInt
                    switch mode {
                    case .readOnly: oflag = _O_RDONLY
                    case .writeOnly: oflag = _O_WRONLY
                    case .readWrite: oflag = _O_RDWR
                    }
                    var fd: CInt = -1
                    let error = fileURL.path.withCString(encodedAs: UTF16.self) { widePath in
                        _wsopen_s(&fd, widePath, oflag | _O_BINARY, _SH_DENYNO, _S_IREAD | _S_IWRITE)
                    }
                    guard error == 0 else {
                        throw Error(description: "Failed to open \(fileURL.path)")
                    }
                    return OpenedFile(fileDescriptor: fd)
                #else
                    let handle: FileHandle?
                    switch mode {
                    case .readOnly: handle = FileHandle(forReadingAtPath: fileURL.path)
                    case .writeOnly: handle = FileHandle(forWritingAtPath: fileURL.path)
                    case .readWrite: handle = FileHandle(forUpdatingAtPath: fileURL.path)
                    }
                    guard let handle else {
                        throw Error(description: "Failed to open \(fileURL.path)")
                    }
                    return OpenedFile(handle: handle)
                #endif
            }
        #endif

        deinit {
            _ = try? FileManager.default.removeItem(atPath: path)
        }
    }
}
