// poll(2) wrapper for the WASI platform layer. Unavailable on Windows and on
// unknown platforms, where `poll_oneoff` reports `ENOTSUP` for fd
// subscriptions.
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(WASI)
    import WASILibc
#endif

enum PlatformPoll {
    struct Subscription {
        let fd: CInt
        let waitWrite: Bool
    }

    struct ReadyState: OptionSet {
        var rawValue: UInt8
        init(rawValue: UInt8) { self.rawValue = rawValue }

        static let readable = ReadyState(rawValue: 1 << 0)
        static let writable = ReadyState(rawValue: 1 << 1)
        static let hangup = ReadyState(rawValue: 1 << 2)
        static let error = ReadyState(rawValue: 1 << 3)
    }

    /// Waits for readiness of the given descriptors, or for the timeout.
    /// Returns one `ReadyState` per subscription (empty when not ready), or
    /// nil when the call timed out with no ready descriptor.
    ///
    /// Failures are reported as `WASIAbi.Errno` because the mapping of poll
    /// errors is part of the platform contract.
    static func poll(
        subscriptions: [Subscription], timeoutMilliseconds: UInt
    ) throws -> [ReadyState]? {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var pollfds = subscriptions.map {
                pollfd(fd: $0.fd, events: Int16($0.waitWrite ? POLLOUT : POLLIN), revents: 0)
            }
            let result = pollfds.withUnsafeMutableBufferPointer { buffer in
                poll_syscall(buffer.baseAddress, .init(buffer.count), .init(timeoutMilliseconds))
            }
            let err = PlatformErrno.current  // Preserve `errno` immediately after `poll`
            if result == 0 {
                return nil
            }
            guard result > 0 else {
                switch err.rawValue {
                case ENOMEM: throw WASIAbi.Errno.ENOMEM
                case EINTR: throw WASIAbi.Errno.EINTR
                case EINVAL: throw WASIAbi.Errno.EINVAL
                default: throw WASIAbi.Errno.ENOTSUP
                }
            }
            return pollfds.map { fd in
                var state: ReadyState = []
                if fd.revents & Int16(POLLIN) != 0 { state.insert(.readable) }
                if fd.revents & Int16(POLLOUT) != 0 { state.insert(.writable) }
                if fd.revents & Int16(POLLHUP) != 0 { state.insert(.hangup) }
                if fd.revents & Int16(POLLERR | POLLNVAL) != 0 { state.insert(.error) }
                return state
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }
}

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
    // Unshadowed libc entry point: inside `PlatformPoll.poll`, unqualified
    // `poll` would resolve to the method itself.
    private func poll_syscall(_ fds: UnsafeMutablePointer<pollfd>?, _ nfds: nfds_t, _ timeout: CInt) -> CInt {
        poll(fds, nfds, timeout)
    }
#endif
