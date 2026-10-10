import Foundation
import Synchronization
import Testing

@testable import WASI

@Suite
struct PALPollTests {
    #if !os(WASI) && !os(Windows)
        private func pollForReading(_ pipe: Pipe, timeoutNanoseconds: UInt64) throws -> (states: [PlatformPoll.ReadyState]?, elapsed: Duration) {
            try withExtendedLifetime(pipe) {
                let subscription = PlatformPoll.Subscription(fd: pipe.fileHandleForReading.fileDescriptor, waitWrite: false)
                var states: [PlatformPoll.ReadyState]?
                let elapsed = try ContinuousClock().measure {
                    states = try PlatformPoll.poll(subscriptions: [subscription], timeoutNanoseconds: timeoutNanoseconds, maxMillisecondsPerCall: 1)
                }
                return (states, elapsed)
            }
        }

        @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
        func aTimeoutLongerThanOneCallIsWaitedOutInFull() throws {
            let (states, elapsed) = try pollForReading(Pipe(), timeoutNanoseconds: 10_000_000)
            #expect(states == nil)
            #expect(elapsed >= .milliseconds(10))
            #expect(elapsed < .seconds(1))
        }

        @Test(.disabled(if: TestSupport.pollUnavailable, "poll is not available on this platform"))
        func aDescriptorThatBecomesReadyDuringALaterCallIsReported() throws {
            let pipe = Pipe()
            let outcome = Mutex<Result<Void, any Error>?>(nil)
            Thread.detachNewThread {
                Thread.sleep(forTimeInterval: 0.02)
                let result = Result { try pipe.fileHandleForWriting.write(contentsOf: Data("x".utf8)) }
                outcome.withLock { $0 = result }
            }
            let (states, elapsed) = try pollForReading(pipe, timeoutNanoseconds: 2_000_000_000)

            let deadline = ContinuousClock.now + .seconds(1)
            var result: Result<Void, any Error>?
            while ContinuousClock.now < deadline {
                result = outcome.withLock { $0 }
                if result != nil { break }
                Thread.sleep(forTimeInterval: 0.001)
            }
            try #require(result).get()
            #expect(states == [.readable])
            #expect(elapsed < .seconds(1))
        }
    #endif
}
