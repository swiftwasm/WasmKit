import WasmTypes

/// Why a ``ResumableCall`` stopped before its function returned.
public enum Suspension: Sendable, Equatable {
    /// The guest could not pay for the code it was about to run from ``Store/fuel``.
    ///
    /// The charge is all-or-nothing: `required` was not deducted. Give the store at least
    /// `required` fuel and resume, and the call retries the charge; with less, it suspends
    /// again at once.
    ///
    /// A bulk memory or table operation suspends before it does anything, and resuming runs
    /// it again from the start. If it is out of bounds, it traps then.
    case outOfFuel(required: UInt64)
    /// The engine's epoch reached the deadline set by
    /// ``Store/setEpochDeadline(ticksBeyondCurrent:)``.
    ///
    /// Set a new deadline and resume, and the call checks the epoch again where it stopped.
    case epochDeadlineReached
    /// A host function made with ``Function/suspending(store:parameters:results:_:)`` has not
    /// given its results yet.
    ///
    /// Resume the call once the waiter is ready, and it continues after the host call. Resumed
    /// earlier, it stays suspended here.
    case waitingForHost(HostWaiter)
}

/// An error raised by misusing a ``ResumableCall``. The call is left as it was.
public struct ResumableCallError: Error, CustomStringConvertible, Sendable {
    /// The description of the error.
    public let description: String

    static var alreadyRunning: ResumableCallError {
        ResumableCallError(description: "the call is already running")
    }
    static var finished: ResumableCallError {
        ResumableCallError(description: "the call has already finished")
    }
    static var resumedInsideAnotherCall: ResumableCallError {
        ResumableCallError(
            description: "a call suspended outside a running resumable call cannot be resumed inside it")
    }
    static var exceptionNotThrowable: ResumableCallError {
        ResumableCallError(description: "a WebAssembly exception cannot be thrown into a suspended call")
    }
}

/// How the guest stopped: where to continue from.
///
/// Thrown by the code that suspends, and caught by ``ResumableCall``. The frames between `sp` and
/// the root frame stay on the call's stack while it is suspended.
struct SuspensionSignal: Error, @unchecked Sendable {
    enum Reason {
        case outOfFuel(required: UInt64)
        case epochDeadlineReached
        /// Waiting at a call to `function`, whose results go to `parameterArea`.
        case hostCall(PendingHostCall, function: EntityHandle<HostFunctionEntity>, parameterArea: Sp)
    }

    let reason: Reason
    /// The frame to continue in.
    let sp: Sp
    /// The head slot to continue from.
    let resumePC: Pc
}

/// A call to a function that can be suspended and resumed.
///
/// A resumable call runs its guest on a stack of its own, which stays alive while the call is
/// suspended. With ``EngineConfiguration/fuelMetering``, running out of ``Store/fuel`` suspends
/// the guest instead of trapping, and so does reaching the epoch deadline with
/// ``EngineConfiguration/epochInterruption``. A host function made with
/// ``Function/suspending(store:parameters:results:_:)`` suspends it until the function gives its
/// results.
///
/// ```swift
/// let call = try ResumableCall(function: run, arguments: [])
/// var status = try call.resume()
/// while case .suspended(let suspension) = status {
///     switch suspension {
///     case .outOfFuel(let required):
///         store.fuel = Fuel(remaining: max(required, 10_000))
///     case .epochDeadlineReached:
///         store.setEpochDeadline(ticksBeyondCurrent: 1)
///     case .waitingForHost(let waiter):
///         waiter.onReady { scheduler.enqueue(call) }
///         return
///     }
///     status = try call.resume()
/// }
/// ```
///
/// Any number of resumable calls can be suspended on one store at a time, and resumed in any
/// order. A host function can run another resumable call too, but cannot resume one suspended
/// outside it.
///
/// A plain call made while a resumable call runs, such as a host function calling back into the
/// guest with ``Function/invoke(_:)``, cannot be suspended: running out of fuel there traps.
public final class ResumableCall {
    /// What a run of the call ended with, when it did not throw.
    public enum Status {
        /// The function returned these results. The call is finished.
        case returned([Value])
        /// The guest is suspended. Resume the call to continue it.
        case suspended(Suspension)
    }

    /// Where a suspended call is, and what it continues with.
    private struct Parked {
        enum Site {
            /// At a fuel or epoch check, to continue from `pc` in the frame `sp`.
            case guest(Suspension, sp: Sp, pc: Pc)
            /// At a call to the host function `function`, to continue from `pc` in the frame
            /// `sp` once the results are in `parameterArea`.
            case hostCall(
                PendingHostCall, function: EntityHandle<HostFunctionEntity>, sp: Sp, parameterArea: Sp, pc: Pc)
            /// In the host function the call is of.
            case rootHost(PendingHostCall)
        }
        let site: Site
        /// The resumable calls that were running when the call was suspended, outermost first,
        /// not counting it.
        let outside: [UInt64]

        var suspension: Suspension {
            switch site {
            case .guest(let suspension, _, _): return suspension
            case .hostCall(let pending, _, _, _, _), .rootHost(let pending):
                return .waitingForHost(HostWaiter(pending: pending))
            }
        }

        var pending: PendingHostCall? {
            switch site {
            case .guest: return nil
            case .hostCall(let pending, _, _, _, _), .rootHost(let pending): return pending
            }
        }
    }

    /// Where the call is, and who owns its stack: the state while the call is not running, and
    /// the run itself while it is.
    private enum State: ~Copyable {
        /// Not started; holds the arguments.
        case ready([Value], ExecutionStack)
        case running
        case suspended(Parked, ExecutionStack)
        /// Holds the stack until ``takeStack()`` takes it.
        case finished(ExecutionStack?)

        /// Returns this state, leaving `.running` in its place.
        mutating func take() -> State {
            let current = self
            self = .running
            return current
        }

        /// Takes the stack of a finished call.
        mutating func takeStack() -> ExecutionStack? {
            switch consume self {
            case .finished(let stack):
                self = .finished(nil)
                return stack
            case let other:
                self = other
                return nil
            }
        }

        /// Finishes a call that is not running, returning where it was suspended, if it was.
        mutating func finish() throws(ResumableCallError) -> Parked? {
            switch consume self {
            case .ready(_, let stack):
                self = .finished(stack)
                return nil
            case .suspended(let parked, let stack):
                self = .finished(stack)
                return parked
            case .running:
                self = .running
                throw .alreadyRunning
            case .finished(let stack):
                self = .finished(stack)
                throw .finished
            }
        }
    }

    /// The function this call runs.
    public let function: Function
    private let type: FunctionType
    private var execution: Execution
    /// The code the called function returns to.
    private let rootCode: Execution.RootCode
    private var state: State
    /// Tells this call apart from the others on its store.
    private let serial: UInt64

    /// Prepares a call of `function` with `arguments`, on a stack of its own, without running it.
    ///
    /// - Throws: A trap if `arguments` do not match the parameters of `function`.
    public convenience init(function: Function, arguments: [Value] = []) throws {
        try self.init(function: function, arguments: arguments, on: ExecutionStack(engine: function.store.engine))
    }

    /// Prepares a call of `function` with `arguments` on `stack`, without running it.
    ///
    /// The call keeps the stack while it runs and while it is suspended. Take it back with
    /// ``takeStack()`` once the call has finished, to use it again.
    ///
    /// - Throws: A trap if `arguments` do not match the parameters of `function`.
    public init(function: Function, arguments: [Value] = [], on stack: consuming ExecutionStack) throws {
        let type = function.type
        guard arguments.count == type.parameters.count,
            zip(arguments, type.parameters).allSatisfy({ $0.matches($1) })
        else {
            throw Trap(.parameterTypesMismatch(expected: type.parameters, got: arguments))
        }
        let store = function.store
        self.function = function
        self.type = type
        // `StoreRef` does not retain the store, so it must not outlive it. It cannot: the
        // execution lives as long as this call, which retains `function`, which retains its store.
        self.execution = Execution(store: StoreRef(store), stackEnd: stack.slots.advanced(by: stack.count))
        self.rootCode = Execution.RootCode(threadingModel: store.engine.configuration.threadingModel)
        self.state = .ready(arguments, stack)
        self.serial = store.nextResumableCallSerial
        store.nextResumableCallSerial += 1
    }

    deinit {
        // A host function's continuation resumed later has nothing to finish.
        switch state {
        case .suspended(let parked, _): parked.pending?.cancel()
        default: break
        }
    }

    /// Whether the function has returned, or the call failed.
    public var isFinished: Bool {
        switch state {
        case .finished: return true
        default: return false
        }
    }

    /// Why the call is suspended, or `nil` when it is not.
    public var suspension: Suspension? {
        switch state {
        case .suspended(let parked, _): return parked.suspension
        default: return nil
        }
    }

    /// Takes the call's stack back, to use it again. `nil` until the call has finished, and once
    /// the stack has been taken.
    public func takeStack() -> ExecutionStack? {
        state.takeStack()
    }

    /// Starts the call, or continues it after a suspension.
    ///
    /// A call waiting for a host function that has not given its results stays suspended, and
    /// this returns the same ``Suspension/waitingForHost(_:)`` again.
    ///
    /// - Returns: Whether the function returned or the guest was suspended again.
    /// - Throws: A trap, or another error the guest raised, which finishes the call; or a
    ///   ``ResumableCallError`` if the call cannot be resumed, which leaves it as it was.
    public func resume() throws -> Status {
        #if !$Embedded
            var status = try resumeOnce()
            // Only an awaited resume runs an asynchronous host function: elsewhere it traps.
            while case .suspended(.waitingForHost(let waiter)) = status, waiter.pending.asyncCall != nil {
                waiter.pending.asyncCall = nil
                waiter.pending.complete { _ in throw Trap(.asyncHostFunctionNotAwaited) }
                status = try resumeOnce()
            }
            return status
        #else
            try resumeOnce()
        #endif
    }

    /// Starts the call, or continues it after a suspension, once.
    func resumeOnce() throws -> Status {
        switch state.take() {
        case .ready(let arguments, let stack):
            return try start(arguments: arguments, on: stack)
        case .suspended(let parked, let stack):
            let running = function.store.runningResumableCalls
            guard running.count <= parked.outside.count, running.elementsEqual(parked.outside.prefix(running.count))
            else {
                state = .suspended(parked, stack)
                throw ResumableCallError.resumedInsideAnotherCall
            }
            switch parked.site {
            case .guest(_, let sp, let pc):
                return try run(on: stack) { execution, _ in
                    try execution.resume(sp: sp, pc: pc)
                    return nil
                }
            case .hostCall(let pending, let function, let sp, let parameterArea, let pc):
                guard let completion = pending.takeCompletion() else {
                    state = .suspended(parked, stack)
                    return .suspended(parked.suspension)
                }
                return try run(on: stack) { execution, _ in
                    try execution.resumeHostCall(
                        function: function, sp: sp, parameterArea: parameterArea, pc: pc, completion: completion)
                    return nil
                }
            case .rootHost(let pending):
                guard let completion = pending.takeCompletion() else {
                    state = .suspended(parked, stack)
                    return .suspended(parked.suspension)
                }
                let store = function.store
                let results = self.type.results
                return try run(on: stack) { _, _ in
                    let produced = try completion(Caller(instanceHandle: nil, store: store))
                    try Function.checkResults(produced, types: results)
                    return produced
                }
            }
        case .running:
            throw ResumableCallError.alreadyRunning
        case .finished(let stack):
            state = .finished(stack)
            throw ResumableCallError.finished
        }
    }

    /// Finishes a call without running any more of it, throwing `error` from where it is.
    ///
    /// This is how to cancel a call. A ``Trap`` gets the backtrace of the suspended guest. The
    /// guest cannot catch `error`, so it may not be a ``WasmKitException``. A host function the
    /// call is waiting for is left without a call to finish: its continuation does nothing.
    ///
    /// - Throws: `error`, which finishes the call; or a ``ResumableCallError`` if the call is
    ///   running or finished, or `error` is a ``WasmKitException``, which leaves it as it was.
    public func resume(throwing error: any Error) throws -> Never {
        if error is WasmKitException {
            throw ResumableCallError.exceptionNotThrowable
        }
        guard let parked = try state.finish() else { throw error }
        parked.pending?.cancel()
        if let trap = error as? Trap {
            switch parked.site {
            case .guest(_, let sp, let pc):
                // A trap site is just past the head slot of the instruction that raised it.
                throw trap.withBacktrace(Execution.captureBacktrace(sp: sp, pc: pc + 1, store: function.store))
            case .hostCall(_, _, let sp, _, let pc):
                throw trap.withBacktrace(Execution.captureBacktrace(sp: sp, pc: pc, store: function.store))
            case .rootHost:
                break
            }
        }
        throw error
    }

    private func start(arguments: [Value], on stack: consuming ExecutionStack) throws -> Status {
        let handle = function.handle
        guard handle.isWasm else {
            // A host function has no guest frames to suspend, but can wait for its continuation.
            let store = function.store
            return try run(on: stack) { _, _ in
                try handle.invokeHost(arguments, store: store, suspendable: true)
            }
        }
        let type = self.type
        let rootPC = self.rootCode.pc
        return try run(on: stack) { execution, base in
            let sp = try Execution.layOutRootFrame(at: base, type: type, arguments: arguments)
            try execution.execute(sp: sp, pc: rootPC, handle: handle, type: type)
            return nil
        }
    }

    /// Runs `body` as this call on `stack`, whose start it is given, marking the store as running
    /// a suspendable execution, and records how it stopped.
    ///
    /// `body` returns the results of a host function the call is of, or `nil` to read them from
    /// the root frame.
    private func run(
        on stack: consuming ExecutionStack, _ body: (inout Execution, Sp) throws -> [Value]?
    ) throws -> Status {
        let store = function.store
        let wasSuspendable = store.isSuspendable
        let outside = store.runningResumableCalls
        store.isSuspendable = true
        store.runningResumableCalls.append(serial)
        defer {
            store.isSuspendable = wasSuspendable
            store.runningResumableCalls = outside
        }
        let base = stack.slots
        let hostResults: [Value]?
        do {
            hostResults = try body(&execution, base)
        } catch let signal as SuspensionSignal {
            let parked = Parked(site: Self.site(of: signal), outside: outside)
            state = .suspended(parked, stack)
            return .suspended(parked.suspension)
        } catch let pending as PendingHostCall {
            // Only the root host function's wait gets here: the call handlers catch the others.
            let parked = Parked(site: .rootHost(pending), outside: outside)
            state = .suspended(parked, stack)
            return .suspended(parked.suspension)
        } catch {
            state = .finished(stack)
            throw error
        }
        let results =
            hostResults
            ?? Execution.readRootResults(sp: base.advanced(by: StackLayout.numberOfSavingSlots), type: type)
        state = .finished(stack)
        return .returned(results)
    }

    private static func site(of signal: SuspensionSignal) -> Parked.Site {
        switch signal.reason {
        case .outOfFuel(let required):
            return .guest(.outOfFuel(required: required), sp: signal.sp, pc: signal.resumePC)
        case .epochDeadlineReached:
            return .guest(.epochDeadlineReached, sp: signal.sp, pc: signal.resumePC)
        case .hostCall(let pending, let function, let parameterArea):
            return .hostCall(pending, function: function, sp: signal.sp, parameterArea: parameterArea, pc: signal.resumePC)
        }
    }
}
