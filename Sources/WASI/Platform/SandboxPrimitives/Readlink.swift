import SystemExtras
import SystemPackage

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import CSystem
    import Glibc
#elseif canImport(Musl)
    import CSystem
    import Musl
#elseif canImport(Android)
    import CSystem
    import Android
#elseif os(Windows)
    import CSystem
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
            let (dir, basename) = try openParent(start: start, path: path)
            defer {
                if dir.rawValue != start.rawValue {
                    try? dir.close()
                }
            }

            return try basename.withCString { cBasename in
                var capacity = 256
                while true {
                    var buffer = [UInt8](repeating: 0, count: capacity)
                    let count = try buffer.withUnsafeMutableBytes { rawBuffer -> Int in
                        guard let baseAddress = rawBuffer.baseAddress else {
                            throw WASIAbi.Errno.EINVAL
                        }
                        let base = baseAddress.assumingMemoryBound(to: Int8.self)
                        let written = readlinkat(dir.rawValue, cBasename, base, rawBuffer.count)
                        guard written >= 0 else {
                            throw try WASIAbi.Errno(platformErrno: errno)
                        }
                        return written
                    }

                    if count < capacity || capacity >= 65536 {
                        return Array(buffer.prefix(count))
                    }
                    capacity &*= 2
                }
            }
        #endif
    }
}

