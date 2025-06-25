import SystemPackage

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#else
    #error("Unsupported Platform")
#endif

extension FdTable {
    func fileDescriptor(fd: WASIAbi.Fd) throws -> FileDescriptor {
        guard case let .file(entry) = self[fd], let fd = (entry as? FdWASIEntry)?.fd else {
            throw WASIAbi.Errno.EBADF
        }

        return fd
    }
}

func poll(
    subscriptions: some Sequence<WASIAbi.Subscription>,
    _ fdTable: FdTable
) throws {
    #if os(Windows)
        throw WASIAbi.Errno.ENOTSUP
    #else
        var pollfds = [pollfd]()
        var timeoutMilliseconds = UInt.max

        for subscription in subscriptions {
            let union = subscription.union
            switch union {
            case .clock(let clock):
                timeoutMilliseconds = min(timeoutMilliseconds, .init(clock.timeout / 1_000_000))
            case .fdRead(let fd):
                pollfds.append(.init(fd: try fdTable.fileDescriptor(fd: fd).rawValue, events: .init(POLLIN), revents: 0))
            case .fdWrite(let fd):
                pollfds.append(.init(fd: try fdTable.fileDescriptor(fd: fd).rawValue, events: .init(POLLOUT), revents: 0))

            }
        }

        poll(&pollfds, .init(pollfds.count), .init(timeoutMilliseconds))
    #endif
}
