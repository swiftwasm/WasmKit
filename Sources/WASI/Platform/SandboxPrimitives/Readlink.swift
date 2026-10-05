extension SandboxPrimitives {
    static func readlinkAt(start: FileDescriptor, path: String) throws -> [UInt8] {
        let result = try openParent(start: start, path: path)
        return try result.withFields { dir, basename in
            try readSymlink(in: dir, name: basename)
        }
    }

    /// Reads the target of the symlink `name` in `dir`, growing the buffer
    /// until the whole target fits.
    static func readSymlink(in dir: FileDescriptor, name: String) throws -> [UInt8] {
        let initialBufferCapacity = 256
        let maxBufferCapacity = max(initialBufferCapacity, FileDescriptor.maximumPathLength)
        var capacity = min(initialBufferCapacity, maxBufferCapacity)
        while true {
            var buffer = [UInt8](repeating: 0, count: capacity)
            let count = try buffer.withUnsafeMutableBytes { rawBuffer in
                try dir.readSymlink(at: name, into: rawBuffer)
            }

            if count < capacity || capacity == maxBufferCapacity {
                return Array(buffer.prefix(count))
            }
            capacity = min(capacity * 2, maxBufferCapacity)
        }
    }
}
