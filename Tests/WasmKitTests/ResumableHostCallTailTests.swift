import Testing
import WAT
import WasmParser

@testable import WasmKit

/// Suspensions at host calls that the guest reaches through a tail call.
///
/// The guest is ``TailCallHostTrapTests/wat``. A tail call to a host function moves its arguments
/// and runs the host function in a frame above them. A call suspended there continues in that
/// moved frame, so the caller's saved slots, which a trap writes back, have to stay as the move
/// left them. Each path suspends once, and the tests check that the host function then ran once.
@Suite
struct ResumableHostCallTailTests {
    typealias Path = TailCallHostTrapTests.Path

    /// An engine configuration for one run of the guest.
    struct Configuration: Sendable, CustomTestStringConvertible {
        let threadingModel: EngineConfiguration.ThreadingModel
        let epochInterruption: Bool
        var testDescription: String {
            "\(threadingModel) \(epochInterruption ? "epoch" : "no epoch")"
        }
    }

    /// Every tested threading model, with and without epoch interruption.
    static let configurations: [Configuration] = testedThreadingModels.flatMap { model in
        [false, true].map { Configuration(threadingModel: model, epochInterruption: $0) }
    }

    /// The guest, with host functions that suspend on their first call and on every call while
    /// `suspends` is true, and otherwise throw `failure` or return the sum of their arguments.
    final class Host {
        var suspends = true
        var failure: (any Error)?
    }

    static func makeGuest(_ configuration: Configuration, host: Host) throws -> TailCallHostTrapTests.Guest {
        try TailCallHostTrapTests.makeGuest(
            configuration.threadingModel, epochInterruption: configuration.epochInterruption
        ) { arguments, call in
            if host.suspends { throw SuspensionRequest(tag: UInt64(call)) }
            if let failure = host.failure { throw failure }
            return [.i32(TailCallHostTrapTests.sum(arguments))]
        }
    }

    /// Starts a resumable call of `path`'s runner and checks that it suspends at the host call
    /// with the path's arguments, once.
    static func suspend(
        _ guest: TailCallHostTrapTests.Guest, path: Path, on stack: consuming ExecutionStack? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> (ResumableCall, Suspension) {
        let runner = try guest.export(path.runner)
        let count = guest.calls.arguments[path.host]?.count ?? 0
        let call: ResumableCall
        if let stack = consume stack {
            call = try ResumableCall(function: runner, arguments: [.i32(9)], on: stack)
        } else {
            call = try ResumableCall(function: runner, arguments: [.i32(9)])
        }
        let suspension = try ResumableHostCallTests.suspension(try call.resume(), sourceLocation: sourceLocation)
        #expect(
            suspension.reason == .hostCall(tag: UInt64(count + 1), arguments: path.arguments),
            sourceLocation: sourceLocation)
        #expect(guest.calls.arguments[path.host]?.count == count + 1, sourceLocation: sourceLocation)
        return (call, suspension)
    }

    /// Answers a suspension through every path, and runs the next call on the same stack.
    @Test(arguments: configurations, Path.allCases)
    func anAnswerContinuesInTheMovedFrame(_ configuration: Configuration, path: Path) throws {
        let guest = try Self.makeGuest(configuration, host: Host())
        let answer = TailCallHostTrapTests.sum(path.arguments)
        let (call, suspension) = try Self.suspend(guest, path: path)
        let results = try ResumableHostCallTests.results(
            try call.resume(returning: [.i32(answer)], answering: suspension))
        #expect(results == [.i32(answer &* 3)])
        #expect(guest.calls.arguments[path.host] == [path.arguments])
        // The finished call hands its stack to the next one, which suspends and finishes there too.
        guard let stack = call.takeStack() else {
            Issue.record("expected the stack of the finished call")
            return
        }
        let (next, nextSuspension) = try Self.suspend(guest, path: path, on: stack)
        #expect(
            try ResumableHostCallTests.results(try next.resume(returning: [.i32(1)], answering: nextSuspension))
                == [.i32(3)])
        #expect(guest.calls.arguments[path.host]?.count == 2)
    }

    /// The case that fork tests caught the trap-only restore with. Three arguments leave the
    /// caller's saved PC and SP in place, but the host frame's saved SP lies on the caller's saved
    /// function. Writing the caller's slots back at the suspension would replace that saved SP,
    /// and the answered call would return through a broken frame. `spill` cannot show this,
    /// because that host frame's saved slots lie above the caller's.
    @Test(arguments: configurations)
    func aPauseAfterThePartialOverlapResumesInTheMovedFrame(_ configuration: Configuration) throws {
        let host = Host()
        let guest = try Self.makeGuest(configuration, host: host)
        let (answered, answeredSuspension) = try Self.suspend(guest, path: .partial)
        #expect(
            try ResumableHostCallTests.results(try answered.resume(returning: [.i32(14)], answering: answeredSuspension))
                == [.i32(42)])
        let (failed, failedSuspension) = try Self.suspend(guest, path: .partial)
        let trap = #expect(throws: Trap.self) {
            try failed.resume(failing: TailCallHostTrapTests.hostTrap, answering: failedSuspension)
        }
        TailCallHostTrapTests.expectHostTrap(trap, frames: ["partial", "run_partial"])
        #expect(guest.calls.arguments["three"]?.count == 2)
        // The store still runs the same call synchronously.
        host.suspends = false
        #expect(try guest.export("run_partial")([.i32(9)]) == [.i32(36)])
    }

    /// A trap delivered into a suspended host call, or a cancellation with one, is reported like
    /// a synchronous host function's trap at that call.
    ///
    /// The frames and the trap site match. The outermost frame's address differs, because a
    /// plain call and a resumable call return to root code of their own.
    @Test(arguments: configurations, Path.allCases)
    func aTrapAtTheSuspensionNamesTheFramesASynchronousTrapNames(_ configuration: Configuration, path: Path) throws {
        let host = Host()
        let guest = try Self.makeGuest(configuration, host: host)
        let runner = try guest.export(path.runner)
        host.suspends = false
        host.failure = TailCallHostTrapTests.hostTrap
        let synchronousTrap = #expect(throws: Trap.self) { try runner([.i32(9)]) }
        TailCallHostTrapTests.expectHostTrap(synchronousTrap, frames: [path.rawValue, path.runner])
        let synchronous = try #require(synchronousTrap?.backtrace)
        host.suspends = true
        for cancels in [false, true] {
            let (call, suspension) = try Self.suspend(guest, path: path)
            let trap = #expect(throws: Trap.self) {
                if cancels {
                    try call.resume(throwing: TailCallHostTrapTests.hostTrap)
                } else {
                    _ = try call.resume(failing: TailCallHostTrapTests.hostTrap, answering: suspension)
                }
            }
            TailCallHostTrapTests.expectHostTrap(trap, frames: [path.rawValue, path.runner])
            let backtrace = try #require(trap?.backtrace)
            #expect(backtrace.trapSite == synchronous.trapSite, "cancels: \(cancels)")
            #expect(backtrace.symbols.dropLast().map(\.address) == synchronous.symbols.dropLast().map(\.address))
            #expect(call.isFinished)
            let tookStack = !ResumableHostCallTests.isNone(call.takeStack())
            #expect(tookStack)
        }
        #expect(guest.calls.arguments[path.host]?.count == 3)
    }

    /// An exception delivered into a host call that `spill` suspended in reaches the handler
    /// below the tail caller, as a synchronous host function's exception does, and other errors
    /// pass through unchanged.
    @Test(arguments: configurations)
    func otherFailuresFollowTheSynchronousRules(_ configuration: Configuration) throws {
        let host = Host()
        let guest = try Self.makeGuest(configuration, host: host)
        let exception = #expect(throws: WasmKitException.self) { try guest.export("raise")([.i32(77)]) }
        let raised = try #require(exception)

        let caught = try ResumableCall(function: try guest.export("caught"), arguments: [.i32(9)])
        let suspension = try ResumableHostCallTests.suspension(try caught.resume())
        #expect(suspension.reason == .hostCall(tag: 1, arguments: Path.spill.arguments))
        #expect(try ResumableHostCallTests.results(try caught.resume(failing: raised, answering: suspension)) == [.i32(77)])

        let (failed, failedSuspension) = try Self.suspend(guest, path: .spill)
        #expect(throws: TailCallHostTrapTests.HostFailure()) {
            try failed.resume(failing: TailCallHostTrapTests.HostFailure(), answering: failedSuspension)
        }
        #expect(failed.isFinished)
        // A synchronous run gets the same exception to the same handler.
        host.suspends = false
        host.failure = raised
        #expect(try guest.export("caught")([.i32(9)]) == [.i32(77)])
        #expect(guest.calls.arguments["wide"]?.count == 3)
    }
}
