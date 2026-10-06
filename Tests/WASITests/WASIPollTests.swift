import Foundation
import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// Clock subscriptions of `poll_oneoff`: how long the call waits, and which
/// clocks it reports.
@Suite struct WASIPollTests {

    // An absolute-timeout test catches a read of the wrong clock only while
    // the two readings are at least 1 s apart.
    struct StoppedMonotonicClock: MonotonicClock {
        static let reading: WASIAbi.Timestamp = 2_000_000_000
        func now() throws -> MonotonicClock.Instant { Self.reading }
        func resolution() throws -> MonotonicClock.Duration { 1 }
    }

    struct StoppedWallClock: WallClock {
        static let reading: WASIAbi.Timestamp = 3_000_000_000
        func now() throws -> WallClock.Duration { (seconds: Self.reading / 1_000_000_000, nanoseconds: UInt32(Self.reading % 1_000_000_000)) }
        func resolution() throws -> WallClock.Duration { (seconds: 0, nanoseconds: 1) }
    }

    private static func stoppedReading(of id: WASIAbi.ClockId) -> WASIAbi.Timestamp {
        id == .REALTIME ? StoppedWallClock.reading : StoppedMonotonicClock.reading
    }

    private static func clock(
        _ userData: WASIAbi.UserData, _ id: WASIAbi.ClockId, timeout: WASIAbi.Timestamp, flags: WASIAbi.Clock.Flags = []
    ) -> WASIAbi.Subscription {
        .init(userData: userData, union: .clock(.init(id: id, timeout: timeout, precision: 0, flags: flags)))
    }

    private static func clockEvent(_ userData: WASIAbi.UserData) -> WASIAbi.Event {
        .init(userData: userData, error: .SUCCESS, eventType: .clock, fdReadWrite: .init(nBytes: 0, flags: []))
    }

    private func withSystemClocks(_ body: (WASIImplementation) throws -> Void) throws {
        let bridge = try WASIBridgeToHost(fileSystem: .memory(MemoryFileSystem()))
        try bridge.runAndClose { try body($0.underlying) }
    }

    private func withStoppedClocks(_ body: (WASIImplementation) throws -> Void) throws {
        let bridge = try WASIBridgeToHost(fileSystem: .memory(MemoryFileSystem()), wallClock: StoppedWallClock(), monotonicClock: StoppedMonotonicClock())
        try bridge.runAndClose { try body($0.underlying) }
    }

    private func pollOneoff(
        _ wasi: WASIImplementation, _ subscriptions: [WASIAbi.Subscription]
    ) throws -> (events: [WASIAbi.Event], elapsed: Duration) {
        let memory = TestSupport.TestGuestMemory()
        let input = UnsafeGuestBufferPointer<WASIAbi.Subscription>(baseAddress: .init(offset: 0), count: UInt32(subscriptions.count))
        for (index, subscription) in subscriptions.enumerated() {
            input.write(at: UInt32(index), subscription, to: memory)
        }
        let output = UnsafeGuestBufferPointer<WASIAbi.Event>(baseAddress: .init(offset: 4096), count: input.count)
        var count: WASIAbi.Size = 0
        let elapsed = try ContinuousClock().measure {
            count = try wasi.poll_oneoff(subscriptions: input, events: output, memory: memory)
        }
        return ((0..<count).map { output.read(at: $0, in: memory) }, elapsed)
    }

    // MARK: - Waiting

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"), arguments: [WASIAbi.ClockId.MONOTONIC, .REALTIME])
    func aRelativeTimeoutIsWaitedOutInFull(id: WASIAbi.ClockId) throws {
        try withSystemClocks { wasi in
            let (events, elapsed) = try pollOneoff(wasi, [Self.clock(1, id, timeout: 500_000)])
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed >= .microseconds(500))
        }
    }

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"), arguments: [WASIAbi.ClockId.MONOTONIC, .REALTIME])
    func anAbsoluteTimeoutTheClockHasPassedFiresAtOnce(id: WASIAbi.ClockId) throws {
        try withStoppedClocks { wasi in
            let (events, elapsed) = try pollOneoff(wasi, [Self.clock(1, id, timeout: Self.stoppedReading(of: id) - 500_000_000, flags: .isAbsoluteTime)])
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed < .seconds(1))
        }
    }

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"), arguments: [WASIAbi.ClockId.MONOTONIC, .REALTIME])
    func anAbsoluteTimeoutWaitsOnlyForWhatRemains(id: WASIAbi.ClockId) throws {
        try withStoppedClocks { wasi in
            let (events, elapsed) = try pollOneoff(wasi, [Self.clock(1, id, timeout: Self.stoppedReading(of: id) + 30_000_000, flags: .isAbsoluteTime)])
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed >= .milliseconds(30))
            #expect(elapsed < .seconds(1))
        }
    }

    // MARK: - Reported clocks

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
    func onlyTheEarliestClockFires() throws {
        try withSystemClocks { wasi in
            let subscriptions = [
                Self.clock(1, .MONOTONIC, timeout: 20_000_000),
                Self.clock(2, .MONOTONIC, timeout: 2_000_000_000),
            ]
            let (events, elapsed) = try pollOneoff(wasi, subscriptions)
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed < .seconds(1))
        }
    }

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
    func clocksThatExpireTogetherAllFireInSubscriptionOrder() throws {
        try withSystemClocks { wasi in
            let subscriptions = [
                Self.clock(1, .MONOTONIC, timeout: 20_000_000),
                Self.clock(2, .MONOTONIC, timeout: 20_000_000),
            ]
            let (events, _) = try pollOneoff(wasi, subscriptions)
            #expect(events == [Self.clockEvent(1), Self.clockEvent(2)])
        }
    }

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
    func anAbsoluteTimeoutIsComparedByWhatRemains() throws {
        try withStoppedClocks { wasi in
            let subscriptions = [
                Self.clock(1, .MONOTONIC, timeout: StoppedMonotonicClock.reading - 500_000_000, flags: .isAbsoluteTime),
                Self.clock(2, .MONOTONIC, timeout: 2_000_000_000),
            ]
            let (events, elapsed) = try pollOneoff(wasi, subscriptions)
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed < .seconds(1))
        }
    }

    // MARK: - Clock arguments

    @Test(arguments: [WASIAbi.Clock.Flags(), .isAbsoluteTime])
    func anUnknownClockIsRejected(flags: WASIAbi.Clock.Flags) throws {
        try withSystemClocks { wasi in
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try pollOneoff(wasi, [Self.clock(1, .init(rawValue: 4), timeout: 0, flags: flags)])
            }
        }
    }

    @Test func anUnknownClockFailsTheWholeCall() throws {
        try withSystemClocks { wasi in
            let subscriptions = [
                Self.clock(1, .MONOTONIC, timeout: 0),
                Self.clock(2, .init(rawValue: 4), timeout: 0),
            ]
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try pollOneoff(wasi, subscriptions)
            }
        }
    }

    @Test(arguments: [UInt16(2), 0xffff])
    func undefinedClockFlagsAreRejected(rawFlags: UInt16) throws {
        try withSystemClocks { wasi in
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try pollOneoff(wasi, [Self.clock(1, .MONOTONIC, timeout: 0, flags: .init(rawValue: rawFlags))])
            }
        }
    }

    /// `clock_time_get` cannot read the CPU-time clocks.
    @Test(arguments: [WASIAbi.ClockId.PROCESS_CPUTIME_ID, .THREAD_CPUTIME_ID])
    func anAbsoluteTimeoutOnACPUTimeClockIsUnsupported(id: WASIAbi.ClockId) throws {
        try withSystemClocks { wasi in
            #expect(throws: WASIAbi.Errno.ENOTSUP) {
                _ = try pollOneoff(wasi, [Self.clock(1, id, timeout: 0, flags: .isAbsoluteTime)])
            }
        }
    }

    @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
    func aRelativeTimeoutOnACPUTimeClockIsWaitedOut() throws {
        try withSystemClocks { wasi in
            let (events, elapsed) = try pollOneoff(wasi, [Self.clock(1, .PROCESS_CPUTIME_ID, timeout: 1_000_000)])
            #expect(events == [Self.clockEvent(1)])
            #expect(elapsed >= .milliseconds(1))
        }
    }

    // MARK: - Clocks beside descriptors

    #if !os(WASI) && !os(Windows)
        private func withPipeAsStdin(_ body: (WASIImplementation, FileHandle) throws -> Void) throws {
            let pipe = Pipe()
            try withExtendedLifetime(pipe) {
                let bridge = try WASIBridgeToHost(fileSystem: .host().withStdio(stdin: pipe.fileHandleForReading.fileDescriptor))
                try bridge.runAndClose { try body($0.underlying, pipe.fileHandleForWriting) }
            }
        }

        @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
        func aClockFiresBesideADescriptorThatIsNeverReady() throws {
            try withPipeAsStdin { wasi, _ in
                let subscriptions = [
                    WASIAbi.Subscription(userData: 1, union: .fdRead(0)),
                    Self.clock(2, .MONOTONIC, timeout: 1_500_000),
                ]
                let (events, elapsed) = try pollOneoff(wasi, subscriptions)
                #expect(events == [Self.clockEvent(2)])
                #expect(elapsed >= .microseconds(1500))
            }
        }

        @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
        func aReadyDescriptorIsReportedWithoutTheClocksBesideIt() throws {
            try withPipeAsStdin { wasi, writeEnd in
                try writeEnd.write(contentsOf: Data("x".utf8))
                let subscriptions = [
                    WASIAbi.Subscription(userData: 1, union: .fdRead(0)),
                    Self.clock(2, .MONOTONIC, timeout: 0),
                    Self.clock(3, .MONOTONIC, timeout: 0, flags: .isAbsoluteTime),
                ]
                let (events, _) = try pollOneoff(wasi, subscriptions)
                #expect(events == [.init(userData: 1, error: .SUCCESS, eventType: .fdRead, fdReadWrite: .init(nBytes: 0, flags: []))])
            }
        }
    #endif
}
