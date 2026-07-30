import WasmTypes

extension FdTable {
    fileprivate func hostFileDescriptor(fd: WASIAbi.Fd) throws -> CInt {
        guard case .file(let entry) = self[fd], let fd = (entry as? FdWASIEntry)?.fd else {
            throw WASIAbi.Errno.EBADF
        }

        return fd.rawValue
    }
}

func poll<M: GuestMemory>(
    subscriptions: some Sequence<WASIAbi.Subscription>,
    events: UnsafeGuestBufferPointer<WASIAbi.Event>,
    _ fdTable: FdTable,
    memory: M
) throws -> WASIAbi.Size {
    var pollSubscriptions = [PlatformPoll.Subscription]()
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
            pollSubscriptions.append(.init(fd: try fdTable.hostFileDescriptor(fd: fd), waitWrite: false))
            fdUserData.append(subscription.userData)
        case .fdWrite(let fd):
            pollSubscriptions.append(.init(fd: try fdTable.hostFileDescriptor(fd: fd), waitWrite: true))
            fdUserData.append(subscription.userData)
        }
    }

    let readyStates = try PlatformPoll.poll(
        subscriptions: pollSubscriptions, timeoutMilliseconds: timeoutMilliseconds
    )
    var updatedEvents: WASIAbi.Size = 0
    guard let readyStates else {
        // Timed out with no ready descriptor.
        if let clockUserData {
            updatedEvents += 1
            events.write(at: 0, .init(userData: clockUserData, error: .SUCCESS, eventType: .clock, fdReadWrite: .init(nBytes: 0, flags: .init(rawValue: 0))), to: memory)
        }
        return updatedEvents
    }
    for (i, state) in readyStates.enumerated() {
        guard !state.isEmpty else { continue }
        let eventIndex = updatedEvents
        updatedEvents += 1
        let waitWrite = pollSubscriptions[i].waitWrite
        let hangup: WASIAbi.Event.FdReadWrite.Flags = state.contains(.hangup) ? [.hangup] : []
        if state.contains(.readable) || (!waitWrite && state.contains(.hangup)) {
            events.write(at: .init(eventIndex), .init(userData: fdUserData[i], error: .SUCCESS, eventType: .fdRead, fdReadWrite: .init(nBytes: 0, flags: hangup)), to: memory)
        } else if state.contains(.writable) || (waitWrite && state.contains(.hangup)) {
            events.write(at: .init(eventIndex), .init(userData: fdUserData[i], error: .SUCCESS, eventType: .fdWrite, fdReadWrite: .init(nBytes: 0, flags: hangup)), to: memory)
        } else if state.contains(.error) {
            let eventType: WASIAbi.EventType = waitWrite ? .fdWrite : .fdRead
            events.write(at: .init(eventIndex), .init(userData: fdUserData[i], error: .EBADF, eventType: eventType, fdReadWrite: .init(nBytes: 0, flags: [])), to: memory)
        }
    }
    return updatedEvents
}
