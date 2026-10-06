// poll(2) and nanosleep(2) wrappers for the WASI platform layer. Unavailable
// on Windows and on unknown platforms, where `poll_oneoff` reports `ENOTSUP`.
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
    /// A nil timeout waits until a descriptor is ready.
    /// Returns one `ReadyState` per subscription (empty when not ready), or
    /// nil when the call timed out with no ready descriptor.
    static func poll(
        subscriptions: [Subscription], timeoutNanoseconds: UInt64?, maxMillisecondsPerCall: CInt = .max
    ) throws -> [ReadyState]? {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            precondition(maxMillisecondsPerCall > 0, "maxMillisecondsPerCall must be positive")
            var pollfds = subscriptions.map {
                pollfd(fd: $0.fd, events: Int16($0.waitWrite ? POLLOUT : POLLIN), revents: 0)
            }
            // A guest timeout longer than CInt.max ms is waited out over
            // several calls.
            var remainingMilliseconds = timeoutNanoseconds.map { $0 / 1_000_000 + ($0 % 1_000_000 == 0 ? 0 : 1) }
            while true {
                let timeout: CInt = remainingMilliseconds.map { min(CInt(clamping: $0), maxMillisecondsPerCall) } ?? -1
                let result = pollfds.withUnsafeMutableBufferPointer { buffer in
                    poll_syscall(buffer.baseAddress, .init(buffer.count), timeout)
                }
                let err = _palErrno  // Preserve `errno` immediately after `poll`
                if result == 0 {
                    guard let remaining = remainingMilliseconds, remaining > UInt64(timeout) else { return nil }
                    remainingMilliseconds = remaining - UInt64(timeout)
                    continue
                }
                guard result > 0 else {
                    throw _wasiError(fromErrno: err)
                }
                return pollfds.map { fd in
                    var state: ReadyState = []
                    if fd.revents & Int16(POLLIN) != 0 { state.insert(.readable) }
                    if fd.revents & Int16(POLLOUT) != 0 { state.insert(.writable) }
                    if fd.revents & Int16(POLLHUP) != 0 { state.insert(.hangup) }
                    if fd.revents & Int16(POLLERR | POLLNVAL) != 0 { state.insert(.error) }
                    return state
                }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Sleeps until `nanoseconds` have passed, resuming after each signal
    /// interruption.
    static func sleep(nanoseconds: UInt64) throws {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var remaining = nanoseconds
            while remaining > 0 {
                // Darwin misreports the time left after `EINTR` once `tv_sec`
                // reaches 2^32.
                let slice = min(remaining, UInt64(Int32.max) * 1_000_000_000)
                var request = timespec(tv_sec: time_t(slice / 1_000_000_000), tv_nsec: Int(slice % 1_000_000_000))
                var unslept = timespec()
                try valueOrErrno {
                    let result = nanosleep(&request, &unslept)
                    if result != 0 { request = unslept }
                    return result
                }
                remaining -= slice
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
