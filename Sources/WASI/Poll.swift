import SystemPackage
import WasmTypes

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
    events: UnsafeGuestBufferPointer<WASIAbi.Event>,
    _ fdTable: FdTable
) throws -> WASIAbi.Size {
    #if os(Windows)
        throw WASIAbi.Errno.ENOTSUP
    #else
        var pollfds = [pollfd]()
        var fdUserData = [WASIAbi.UserData]()
        var timeoutMilliseconds = UInt.max
        var clockUserData: WASIAbi.UserData?

        for subscription in subscriptions {
            let union = subscription.union
            switch union {
            case .clock(let clock):
                timeoutMilliseconds = min(timeoutMilliseconds, .init(clock.timeout / 1_000_000))
                clockUserData = subscription.userData
            case .fdRead(let fd):
                pollfds.append(.init(fd: try fdTable.fileDescriptor(fd: fd).rawValue, events: .init(POLLIN), revents: 0))
                fdUserData.append(subscription.userData)
            case .fdWrite(let fd):
                pollfds.append(.init(fd: try fdTable.fileDescriptor(fd: fd).rawValue, events: .init(POLLOUT), revents: 0))
                fdUserData.append(subscription.userData)
            }
        }

        let result = poll(&pollfds, .init(pollfds.count), .init(timeoutMilliseconds))
        let err = errno // Preserve `errno` global immediately after `poll`
        var updatedEvents: WASIAbi.Size = 0
        if result == 0, let clockUserData {
            updatedEvents += 1
            events[0] = .init(userData: clockUserData, error: .SUCCESS, eventType: .clock, fdReadWrite: .init(nBytes: 0, flags: .init(rawValue: 0)))
        } else if result > 0 {
            for (i, fd) in pollfds.enumerated() {
                updatedEvents += 1
                switch fd.revents {
                case .init(POLLIN):
                    events[.init(i)] = .init(userData: fdUserData[i], error: .SUCCESS, eventType: .fdRead, fdReadWrite: .init(nBytes: 0, flags: []))
                case .init(POLLOUT):
                    events[.init(i)] = .init(userData: fdUserData[i], error: .SUCCESS, eventType: .fdWrite, fdReadWrite: .init(nBytes: 0, flags: []))
                default: throw WASIAbi.Errno.ENOTSUP
                }
            }
        } else {
            switch err {
            case ENOMEM: throw WASIAbi.Errno.ENOMEM
            case EINTR: throw WASIAbi.Errno.EINTR
            case EINVAL: throw WASIAbi.Errno.EINVAL
            default: throw WASIAbi.Errno.ENOTSUP
            }
        }
        return updatedEvents
    #endif
}
