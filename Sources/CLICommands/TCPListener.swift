// A minimal blocking TCP listener for the debugger server. A GDB stub serves
// one client, so a simple accept/read/write loop is all we need.
#if WasmDebuggingSupport && !os(Windows)

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Android)
        import Android
    #endif

    struct TCPListener {
        struct Error: Swift.Error, CustomStringConvertible {
            let description: String

            init(_ operation: String) {
                self.description = "\(operation) failed: \(String(cString: strerror(errno)))"
            }
        }

        struct Connection {
            private let fd: CInt

            init(fd: CInt) { self.fd = fd }

            /// Reads available bytes, blocking until at least one arrives.
            /// Returns nil at end-of-stream.
            func receive(upTo maxLength: Int = 4096) throws -> [UInt8]? {
                var buffer = [UInt8](repeating: 0, count: maxLength)
                while true {
                    let count = buffer.withUnsafeMutableBytes { raw in
                        read(fd, raw.baseAddress, raw.count)
                    }
                    if count > 0 {
                        buffer.removeLast(maxLength - count)
                        return buffer
                    }
                    if count == 0 { return nil }
                    if errno == EINTR { continue }
                    throw Error("read")
                }
            }

            func send(_ bytes: [UInt8]) throws {
                try bytes.withUnsafeBytes { raw in
                    var sent = 0
                    while sent < raw.count {
                        let count = write(fd, raw.baseAddress! + sent, raw.count - sent)
                        if count >= 0 {
                            sent += count
                        } else if errno != EINTR {
                            throw Error("write")
                        }
                    }
                }
            }

            func close() {
                #if canImport(Darwin)
                    _ = Darwin.close(fd)
                #elseif canImport(Glibc)
                    _ = Glibc.close(fd)
                #elseif canImport(Musl)
                    _ = Musl.close(fd)
                #elseif canImport(Android)
                    _ = Android.close(fd)
                #endif
            }
        }

        private let fd: CInt

        /// Creates a socket listening on the given IPv4 host address and port.
        init(host: String, port: Int, backlog: Int = 256) throws {
            let host = host == "localhost" ? "127.0.0.1" : host
            let fd = socket(AF_INET, socketStreamType, 0)
            guard fd >= 0 else { throw Error("socket") }

            var enable: CInt = 1
            _ = withUnsafeBytes(of: &enable) {
                setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, $0.baseAddress, socklen_t($0.count))
            }

            var address = sockaddr_in()
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = UInt16(port).bigEndian
            guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
                throw Error("inet_pton(\(host))")
            }

            let bound = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard bound == 0 else { throw Error("bind") }
            guard listen(fd, CInt(backlog)) == 0 else { throw Error("listen") }
            self.fd = fd
        }

        /// Blocks until a client connects.
        func accept() throws -> Connection {
            while true {
                let connectionFd = acceptSyscall(fd, nil, nil)
                if connectionFd >= 0 { return Connection(fd: connectionFd) }
                if errno == EINTR { continue }
                throw Error("accept")
            }
        }

        func close() {
            #if canImport(Darwin)
                _ = Darwin.close(fd)
            #elseif canImport(Glibc)
                _ = Glibc.close(fd)
            #elseif canImport(Musl)
                _ = Musl.close(fd)
            #elseif canImport(Android)
                _ = Android.close(fd)
            #endif
        }
    }

    // SOCK_STREAM is an enum on Linux/Glibc but a plain constant elsewhere.
    private var socketStreamType: CInt {
        #if canImport(Glibc)
            return CInt(SOCK_STREAM.rawValue)
        #else
            return SOCK_STREAM
        #endif
    }

    private func acceptSyscall(_ fd: CInt, _ address: UnsafeMutablePointer<sockaddr>?, _ length: UnsafeMutablePointer<socklen_t>?) -> CInt {
        accept(fd, address, length)
    }

#endif
