import WasmTypes

extension FdTable {
    fileprivate func hostFileDescriptor(fd: WASIAbi.Fd) throws -> CInt {
        guard case .file(let entry) = self[fd], let hostFd = entry.hostFileDescriptor else {
            throw WASIAbi.Errno.EBADF
        }

        return hostFd
    }
}

extension WASIAbi.Clock {
    fileprivate func remainingDuration(now: (WASIAbi.ClockId) throws -> WASIAbi.Timestamp) throws -> WASIAbi.Timestamp {
        guard id.rawValue <= WASIAbi.ClockId.THREAD_CPUTIME_ID.rawValue, flags.isSubset(of: .isAbsoluteTime) else {
            throw WASIAbi.Errno.EINVAL
        }
        guard flags.contains(.isAbsoluteTime) else { return timeout }
        let reading = try now(id)
        return timeout > reading ? timeout - reading : 0
    }
}

func poll<M: GuestMemory>(
    subscriptions: some Sequence<WASIAbi.Subscription>,
    events: UnsafeGuestBufferPointer<WASIAbi.Event>,
    _ fdTable: FdTable,
    memory: M,
    now: (WASIAbi.ClockId) throws -> WASIAbi.Timestamp
) throws -> WASIAbi.Size {
    var pollSubscriptions = [PlatformPoll.Subscription]()
    var fdUserData = [WASIAbi.UserData]()
    var clocks: [(userData: WASIAbi.UserData, remaining: WASIAbi.Timestamp)] = []
    // nil means no clock subscription, i.e. wait until a descriptor is ready.
    var timeout: WASIAbi.Timestamp?
    // One reading per clock, so subscriptions on the same clock share a deadline.
    // Clock IDs are validated to be at most THREAD_CPUTIME_ID before they are read.
    var clockReadings = [WASIAbi.Timestamp?](repeating: nil, count: WASIAbi.ClockId.count)
    func clockReading(_ id: WASIAbi.ClockId) throws -> WASIAbi.Timestamp {
        if let reading = clockReadings[Int(id.rawValue)] { return reading }
        let reading = try now(id)
        clockReadings[Int(id.rawValue)] = reading
        return reading
    }

    for subscription in subscriptions {
        let union = subscription.union
        switch union {
        case .clock(let clock):
            let remaining = try clock.remainingDuration(now: clockReading)
            timeout = min(timeout ?? .max, remaining)
            clocks.append((userData: subscription.userData, remaining: remaining))
        case .fdRead(let fd):
            pollSubscriptions.append(.init(fd: try fdTable.hostFileDescriptor(fd: fd), waitWrite: false))
            fdUserData.append(subscription.userData)
        case .fdWrite(let fd):
            pollSubscriptions.append(.init(fd: try fdTable.hostFileDescriptor(fd: fd), waitWrite: true))
            fdUserData.append(subscription.userData)
        case .unknown:
            throw WASIAbi.Errno.EINVAL
        }
    }

    let readyStates: [PlatformPoll.ReadyState]?
    if pollSubscriptions.isEmpty, let timeout {
        // `PlatformPoll.poll` counts its timeout in whole milliseconds.
        try PlatformPoll.sleep(nanoseconds: timeout)
        readyStates = nil
    } else {
        readyStates = try PlatformPoll.poll(subscriptions: pollSubscriptions, timeoutNanoseconds: timeout)
    }
    var updatedEvents: WASIAbi.Size = 0
    for (i, state) in (readyStates ?? []).enumerated() {
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
    // A ready descriptor ends the call with its own events, without clocks.
    guard updatedEvents == 0 else { return updatedEvents }
    // Otherwise report each clock whose deadline had passed when the wait ended.
    // A wait that ended early waited for nothing, so only clocks already expired count.
    let waited: WASIAbi.Timestamp
    if readyStates != nil {
        waited = 0
    } else if pollSubscriptions.isEmpty {
        waited = timeout ?? 0
    } else {
        waited = roundedUpToMilliseconds(timeout ?? 0)
    }
    for clock in clocks where clock.remaining <= waited {
        events.write(at: updatedEvents, .init(userData: clock.userData, error: .SUCCESS, eventType: .clock, fdReadWrite: .init(nBytes: 0, flags: .init(rawValue: 0))), to: memory)
        updatedEvents += 1
    }
    return updatedEvents
}

/// Rounds up to whole milliseconds, which is the unit `poll(2)` waits in.
/// Saturates at the largest timestamp.
private func roundedUpToMilliseconds(_ nanoseconds: WASIAbi.Timestamp) -> WASIAbi.Timestamp {
    let milliseconds = nanoseconds / 1_000_000 + (nanoseconds % 1_000_000 == 0 ? 0 : 1)
    let (rounded, overflow) = milliseconds.multipliedReportingOverflow(by: 1_000_000)
    return overflow ? .max : rounded
}
