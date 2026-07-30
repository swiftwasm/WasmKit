#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(Windows)
    import ucrt
#elseif os(WASI)
    import WASILibc
#else
    #error("Unsupported Platform")
#endif

extension SandboxPrimitives {
    static func readlinkAt(start: FileDescriptor, path: String) throws -> [UInt8] {
        #if os(Windows) || os(WASI)
            throw WASIAbi.Errno.ENOTSUP
        #else
            let initialBufferCapacity = 256
            let maxBufferCapacity = max(initialBufferCapacity, Int(PATH_MAX))

            let result = try openParent(start: start, path: path)
            return try result.withFields { dir, basename in
                var capacity = min(initialBufferCapacity, maxBufferCapacity)
                while true {
                    var buffer = [UInt8](repeating: 0, count: capacity)
                    let count = try buffer.withUnsafeMutableBytes { rawBuffer in
                        try WASIAbi.Errno.translatingPlatformErrno {
                            try dir.readSymlink(at: basename, into: rawBuffer)
                        }
                    }

                    if count < capacity || capacity == maxBufferCapacity {
                        return Array(buffer.prefix(count))
                    }
                    capacity = min(capacity * 2, maxBufferCapacity)
                }
            }
        #endif
    }
}
