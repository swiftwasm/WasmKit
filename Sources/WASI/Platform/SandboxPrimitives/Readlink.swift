extension SandboxPrimitives {
    static func readlinkAt(start: FileDescriptor, path: String) throws -> [UInt8] {
        let initialBufferCapacity = 256
        let maxBufferCapacity = max(initialBufferCapacity, FileDescriptor.maximumPathLength)

        let result = try openParent(start: start, path: path)
        return try result.withFields { dir, basename in
            var capacity = min(initialBufferCapacity, maxBufferCapacity)
            while true {
                var buffer = [UInt8](repeating: 0, count: capacity)
                let count = try buffer.withUnsafeMutableBytes { rawBuffer in
                    try WASIAbi.Errno.translatingPlatformError {
                        try dir.readSymlink(at: basename, into: rawBuffer)
                    }
                }

                if count < capacity || capacity == maxBufferCapacity {
                    return Array(buffer.prefix(count))
                }
                capacity = min(capacity * 2, maxBufferCapacity)
            }
        }
    }
}
