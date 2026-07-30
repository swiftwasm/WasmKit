import WASI

/// Minimal file helpers for CLI commands, backed by the WASI module's
/// platform layer so the CLI needs no direct Foundation file IO.
enum CLIFile {
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    /// An opened file exposing the raw platform descriptor for
    /// descriptor-based APIs. The handle owns the descriptor; call
    /// ``close()`` exactly once.
    struct Handle {
        private let fd: WASI.FileDescriptor

        fileprivate init(fd: WASI.FileDescriptor) {
            self.fd = fd
        }

        /// The raw platform descriptor, for APIs that borrow it.
        var rawValue: CInt { fd.rawValue }

        /// Reads up to `maxLength` bytes from the current offset. A shorter
        /// result means end-of-file.
        func read(upToCount maxLength: Int) throws -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: maxLength)
            let count = try buffer.withUnsafeMutableBytes { try fd.read(into: $0) }
            buffer.removeLast(maxLength - count)
            return buffer
        }

        func seekToStart() throws {
            _ = try fd.seek(offset: 0, from: .start)
        }

        /// Writes all of `bytes` at the current offset.
        func writeAll(_ bytes: [UInt8]) throws {
            try bytes.withUnsafeBytes { raw in
                var written = 0
                while written < raw.count {
                    written += try fd.write(UnsafeRawBufferPointer(rebasing: raw[written...]))
                }
            }
        }

        func close() throws {
            try fd.close()
        }
    }

    static func openRead(_ path: String) throws -> Handle {
        do {
            return Handle(fd: try WASI.FileDescriptor.open(path, .readOnly))
        } catch {
            throw Error(description: "Failed to open file: \(path) (\(error))")
        }
    }

    static func createWrite(_ path: String) throws -> Handle {
        do {
            let fd = try WASI.FileDescriptor.open(
                path, .writeOnly,
                options: [.create, .truncate],
                permissions: FileDescriptor.FilePermissions(rawValue: 0o644)
            )
            return Handle(fd: fd)
        } catch {
            throw Error(description: "Failed to create file: \(path) (\(error))")
        }
    }
}
