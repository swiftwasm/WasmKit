// poll(2) wrapper for the WASI platform layer. Windows has no poll for
// arbitrary handles, so readiness is probed per kind of handle there.
// Unavailable on unknown platforms, where `poll_oneoff` reports `ENOTSUP` for
// fd subscriptions.
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
#elseif os(Windows)
    import ucrt
    import WinSDK
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
        subscriptions: [Subscription], timeoutMilliseconds: UInt?
    ) throws -> [ReadyState]? {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var pollfds = subscriptions.map {
                pollfd(fd: $0.fd, events: Int16($0.waitWrite ? POLLOUT : POLLIN), revents: 0)
            }
            // `poll` takes the timeout in a CInt, where a negative value waits
            // indefinitely. A guest picks the timeout, so clamp rather than
            // narrow: a wait longer than CInt can express is one it can wait out.
            let timeout: CInt = timeoutMilliseconds.map { CInt(clamping: $0) } ?? -1
            let result = pollfds.withUnsafeMutableBufferPointer { buffer in
                poll_syscall(buffer.baseAddress, .init(buffer.count), timeout)
            }
            let err = _palErrno  // Preserve `errno` immediately after `poll`
            if result == 0 {
                return nil
            }
            guard result > 0 else {
                throw _wasiError(fromErrno: err)
            }
            return zip(pollfds, subscriptions).map { fd, subscription in
                var state: ReadyState = []
                #if canImport(Darwin)
                    // Darwin's poll supports few devices besides ttys and flags
                    // the rest, /dev/null among them, POLLNVAL although they are
                    // open. select(2) reports such a device as always ready, so
                    // do the same; a closed descriptor still fails F_GETFD.
                    if fd.revents & Int16(POLLNVAL) != 0, fcntl(fd.fd, F_GETFD) != -1 {
                        state.insert(subscription.waitWrite ? .writable : .readable)
                        return state
                    }
                #endif
                if fd.revents & Int16(POLLIN) != 0 { state.insert(.readable) }
                if fd.revents & Int16(POLLOUT) != 0 { state.insert(.writable) }
                if fd.revents & Int16(POLLHUP) != 0 { state.insert(.hangup) }
                if fd.revents & Int16(POLLERR | POLLNVAL) != 0 { state.insert(.error) }
                return state
            }
        #elseif os(Windows)
            let start = GetTickCount64()
            while true {
                let states = try subscriptions.map(windowsReadyState)
                if states.contains(where: { !$0.isEmpty }) { return states }
                if let timeoutMilliseconds, GetTickCount64() - start >= UInt64(timeoutMilliseconds) { return nil }
                Sleep(1)
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    #if os(Windows)
        /// Probes one handle without blocking. Disk files and devices such as
        /// NUL are always ready, as poll(2) reports regular files; a pipe is
        /// readable once it holds data or its writer is gone; console input is
        /// readable once it has pending events.
        private static func windowsReadyState(_ subscription: Subscription) throws -> ReadyState {
            guard let handle = HANDLE(bitPattern: _get_osfhandle(subscription.fd)), handle != INVALID_HANDLE_VALUE else {
                return .error
            }
            let ready: ReadyState = subscription.waitWrite ? .writable : .readable
            guard !subscription.waitWrite else { return ready }
            switch Int32(GetFileType(handle)) {
            case FILE_TYPE_PIPE:
                var available: DWORD = 0
                guard PeekNamedPipe(handle, nil, 0, nil, &available, nil) else {
                    return GetLastError() == DWORD(ERROR_BROKEN_PIPE) ? .hangup : .error
                }
                return available > 0 ? ready : []
            case FILE_TYPE_CHAR:
                var mode: DWORD = 0
                guard GetConsoleMode(handle, &mode) else { return ready }
                return WaitForSingleObject(handle, 0) == WAIT_OBJECT_0 ? ready : []
            default:
                return ready
            }
        }
    #endif
}

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
    // Unshadowed libc entry point: inside `PlatformPoll.poll`, unqualified
    // `poll` would resolve to the method itself.
    private func poll_syscall(_ fds: UnsafeMutablePointer<pollfd>?, _ nfds: nfds_t, _ timeout: CInt) -> CInt {
        poll(fds, nfds, timeout)
    }
#endif
