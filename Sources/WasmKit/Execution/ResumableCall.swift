import WasmTypes

/// Why a ``ResumableCall`` stopped before its function returned.
public struct Suspension: Sendable {
    /// What suspended the call.
    public enum Reason: Sendable, Equatable {
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
        /// A host function that the guest called threw a ``SuspensionRequest``.
        ///
        /// `tag` is the request's tag, and `arguments` is a copy of what the guest passed to the
        /// host function. The host function does not run again. Complete its call with
        /// ``ResumableCall/resume(returning:answering:)`` or
        /// ``ResumableCall/resume(failing:answering:)``, and the guest continues after it. To end
        /// the call instead, cancel it with ``ResumableCall/resume(throwing:)``.
        ///
        /// A reference among the arguments is the same value a synchronous host function would
        /// get. Copying the array copies the references and keeps nothing they name alive. A
        /// function reference names a function of the call's store. It is valid only in that
        /// store, while the store lives. An exception reference names an exception that this
        /// call's guest caught, and it is valid only in this call. The same holds for references
        /// in an answer. ``ResumableCall/resume(returning:answering:)`` checks the type of each
        /// result, including whether it may be null, and the suspension it answers. It does not
        /// check where a reference came from, so keeping each reference within its store and call
        /// is up to the embedder.
        ///
        /// Neither the suspension nor an answer charges ``Store/fuel`` or checks the epoch
        /// deadline. After an answer the guest runs under the usual rules, and it reaches its next
        /// fuel charge or epoch check where it would after a synchronous host function. It can
        /// have side effects before then. A deadline that passed during the suspension stops the
        /// guest at the next epoch check. If the guest returns before it reaches one, the call
        /// returns its results although the deadline has passed.
        case hostCall(tag: UInt64, arguments: [Value])
    }

    /// What suspended the call.
    public let reason: Reason

    /// The identity of a suspension at a host call, which an answer to it has to name.
    let hostCallIdentity: HostCallIdentity?

    init(reason: Reason, hostCallIdentity: HostCallIdentity? = nil) {
        self.reason = reason
        self.hostCallIdentity = hostCallIdentity
    }
}

/// Thrown by a host function to suspend the ``ResumableCall`` whose guest called it.
///
/// The call suspends at the host call with ``Suspension/Reason/hostCall(tag:arguments:)``. The
/// embedder then does the host function's work outside of it, and continues the guest with
/// ``ResumableCall/resume(returning:answering:)`` as if the host function had returned.
///
/// Only the guest of a ``ResumableCall`` can be suspended this way. A request from a host
/// function that a plain call such as ``Function/invoke(_:)`` reached, or that was called with no
/// guest in between, traps instead.
///
/// The host function's ``Caller`` and the buffers it was given are valid only while it runs. The
/// suspension keeps none of them, and carries a copy of the arguments instead.
public struct SuspensionRequest: Error, Sendable, Equatable {
    /// A value the host function chooses, so that the embedder can tell requests apart.
    ///
    /// The call passes it on in ``Suspension/Reason/hostCall(tag:arguments:)`` and does not use it
    /// otherwise. An answer is matched to its suspension by the ``Suspension`` it names.
    public var tag: UInt64

    /// Creates a request to suspend, tagged with `tag`.
    public init(tag: UInt64 = 0) {
        self.tag = tag
    }
}

/// An error raised by misusing a ``ResumableCall``.
///
/// A call raises it when it refuses a request, such as an answer to another suspension. The
/// refusal comes before anything runs or is written, so the call that refused is left as it was.
///
/// An error of this type that comes from elsewhere is not a refusal. A host function that the
/// guest calls can throw one, for example from a nested call it misused, and it can be the error
/// given to ``ResumableCall/resume(failing:answering:)`` or ``ResumableCall/resume(throwing:)``.
/// Such an error finishes the call like any other error. ``ResumableCall/isFinished`` tells
/// whether a call has ended.
public struct ResumableCallError: Error, CustomStringConvertible, Sendable {
    /// The description of the error.
    public let description: String

    static var alreadyRunning: ResumableCallError {
        ResumableCallError(description: "the call is already running")
    }
    static var finished: ResumableCallError {
        ResumableCallError(description: "the call has already finished")
    }
    static var exceptionNotThrowable: ResumableCallError {
        ResumableCallError(description: "a WebAssembly exception cannot be thrown into a suspended call to cancel it")
    }
    static var requestNotThrowable: ResumableCallError {
        ResumableCallError(description: "a suspension request cannot be thrown into a suspended call")
    }
    static var suspendedAtHostCall: ResumableCallError {
        ResumableCallError(description: "the call is suspended at a host call, which needs the host function's results")
    }
    static var notSuspendedAtHostCall: ResumableCallError {
        ResumableCallError(description: "the call is not suspended at a host call")
    }
    static var otherSuspension: ResumableCallError {
        ResumableCallError(description: "the answer is for another suspension")
    }
    static func resultTypesMismatch(expected: [ValueType], got: [Value]) -> ResumableCallError {
        ResumableCallError(description: "the host function returns \(expected), not \(got)")
    }
}

/// How the guest stopped: where to continue from.
///
/// Thrown by the code that suspends, and caught by ``ResumableCall``. The frames between `sp` and
/// the root frame stay on the call's stack while it is suspended.
///
/// It is `Sendable` only because `Error` requires it. A signal never leaves the call that threw
/// it. The call catches it on the thread that runs the guest and keeps it in its own state. Its
/// pointers lead into the call's stack and into code that the call's store keeps, and the call
/// holds both for as long as it holds the signal.
struct SuspensionSignal: Error, @unchecked Sendable {
    let reason: Suspension.Reason
    /// The frame to continue in.
    let sp: Sp
    /// The head slot to continue from.
    let resumePC: Pc
    /// The host call the guest is suspended in, when a host function asked to suspend.
    let hostCall: SuspendedHostCall?

    init(reason: Suspension.Reason, sp: Sp, resumePC: Pc, hostCall: SuspendedHostCall? = nil) {
        self.reason = reason
        self.sp = sp
        self.resumePC = resumePC
        self.hostCall = hostCall
    }

    var suspension: Suspension {
        Suspension(reason: reason, hostCallIdentity: hostCall?.identity)
    }

    /// Where a trap thrown into the suspended guest is raised, for its backtrace.
    ///
    /// A synchronous host function's trap is reported just past its call, which is where a
    /// suspended host call continues. A check is reported just past its own head slot.
    var trapSite: Pc {
        hostCall == nil ? resumePC + 1 : resumePC
    }
}

/// A host call that a guest is suspended in.
///
/// `parameterArea` is on the suspended call's own stack, which the call keeps while it is
/// suspended. The host function belongs to the call's store, which the call retains.
struct SuspendedHostCall {
    /// The host function, whose result types and layout an answer has to match.
    let function: EntityHandle<HostFunctionEntity>
    /// Where the call's results go.
    let parameterArea: Sp
    /// The identity of this suspension, compared by reference.
    let identity: HostCallIdentity
}

/// An object whose identity names one suspension at a host call.
///
/// A ``Suspension`` keeps it alive, so its address is not reused while an answer can still name
/// it.
final class HostCallIdentity: Sendable {}

/// A call to a function that can be suspended and resumed.
///
/// A resumable call runs its guest on a stack of its own, which stays alive while the call is
/// suspended. With ``EngineConfiguration/fuelMetering``, running out of ``Store/fuel`` suspends
/// the guest instead of trapping, and so does reaching the epoch deadline with
/// ``EngineConfiguration/epochInterruption``. A host function that the guest calls can suspend it
/// too, by throwing a ``SuspensionRequest``.
///
/// ```swift
/// let call = try ResumableCall(function: run, arguments: [])
/// var status = try call.resume()
/// while case .suspended(let suspension) = status {
///     switch suspension.reason {
///     case .outOfFuel(let required):
///         store.fuel = Fuel(remaining: max(required, 10_000))
///         status = try call.resume()
///     case .epochDeadlineReached:
///         store.setEpochDeadline(ticksBeyondCurrent: 1)
///         status = try call.resume()
///     case .hostCall(let tag, let arguments):
///         let results = try await work(tag, arguments)
///         status = try call.resume(returning: results, answering: suspension)
///     }
/// }
/// ```
///
/// Any number of resumable calls can be suspended on one store at a time, and resumed in any
/// order. A host function can run another resumable call too.
///
/// A plain call made while a resumable call runs, such as a host function calling back into the
/// guest with ``Function/invoke(_:)``, cannot be suspended: running out of fuel there traps, and
/// so does a ``SuspensionRequest``.
///
/// A call suspended at a host call waits for its answer like any other suspended call. Its store
/// stays usable meanwhile. ``Suspension`` is `Sendable`, so the work behind an answer can happen
/// on another thread. That does not let two threads use one store at once. A store and its calls
/// are used by one thread at a time, and the embedder resumes the calls of a store one after
/// another.
public final class ResumableCall {
    /// What a run of the call ended with, when it did not throw.
    public enum Status {
        /// The function returned these results. The call is finished.
        case returned([Value])
        /// The guest is suspended. Resume the call to continue it.
        case suspended(Suspension)
    }

    /// Where the call is, and who owns its stack: the state while the call is not running, and
    /// the run itself while it is.
    private enum State: ~Copyable {
        /// Not started; holds the arguments.
        case ready([Value], ExecutionStack)
        case running
        case suspended(SuspensionSignal, ExecutionStack)
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
        mutating func finish() throws(ResumableCallError) -> SuspensionSignal? {
            switch consume self {
            case .ready(_, let stack):
                self = .finished(stack)
                return nil
            case .suspended(let signal, let stack):
                self = .finished(stack)
                return signal
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
        case .suspended(let signal, _): return signal.suspension
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
    /// A call suspended at a host call cannot continue this way, because the guest needs the
    /// host function's results. Complete it with ``resume(returning:answering:)``, even when the
    /// host function returns nothing.
    ///
    /// - Returns: Whether the function returned or the guest was suspended again.
    /// - Throws: An error that leaves the guest, such as a trap, which finishes the call. That
    ///   includes an error a host function threw, even a ``ResumableCallError``. The method
    ///   refuses with a ``ResumableCallError`` of its own when the call is running, has finished,
    ///   or is suspended at a host call. A refusal comes before anything runs and leaves the call
    ///   as it was.
    public func resume() throws -> Status {
        switch state.take() {
        case .ready(let arguments, let stack):
            return try start(arguments: arguments, on: stack)
        case .suspended(let signal, let stack):
            guard signal.hostCall == nil else {
                state = .suspended(signal, stack)
                throw ResumableCallError.suspendedAtHostCall
            }
            return try run(on: stack) { execution, _ in
                try execution.resume(sp: signal.sp, pc: signal.resumePC)
            }
        case .running:
            throw ResumableCallError.alreadyRunning
        case .finished(let stack):
            state = .finished(stack)
            throw ResumableCallError.finished
        }
    }

    /// Completes the host call that the guest is suspended in with `results`, and continues the
    /// guest after it.
    ///
    /// The guest continues as if the host function had returned `results`. The host function
    /// does not run again. A host function without results is completed with an empty array,
    /// because ``resume()`` refuses a call suspended at a host call.
    ///
    /// Each result is checked against the host function's result type, including whether it may
    /// be null. Where a reference came from is not checked. A function reference has to name a
    /// function of the call's store, and an exception reference an exception this call's guest
    /// caught, as ``Suspension/Reason/hostCall(tag:arguments:)`` describes.
    ///
    /// Accepting the answer neither charges ``Store/fuel`` nor checks the epoch deadline. The
    /// guest then runs under the usual rules, and it reaches its next fuel charge or epoch check
    /// where it would after a synchronous host function. It can have side effects before then.
    /// If it returns before it reaches an epoch check, the call returns its results even when
    /// the deadline passed during the suspension.
    ///
    /// - Parameters:
    ///   - results: The host function's results, matching its result types.
    ///   - suspension: The suspension this answers, which must be the one the call is suspended
    ///     with. An answer meant for an earlier suspension of this call, or for another call, is
    ///     refused.
    /// - Returns: Whether the function returned or the guest was suspended again.
    /// - Throws: An error that leaves the guest, such as a trap, which finishes the call. That
    ///   includes an error a host function threw after the answer, even a
    ///   ``ResumableCallError``. The method refuses with a ``ResumableCallError`` of its own when
    ///   the call is not suspended at a host call, `suspension` is not its suspension, or
    ///   `results` do not match. A refusal comes before anything is written or runs and leaves the
    ///   call as it was.
    public func resume(returning results: [Value], answering suspension: Suspension) throws -> Status {
        try completeHostCall(answering: suspension) { hostCall in
            let resultTypes = hostCall.function.resultTypes
            guard results.count == resultTypes.count,
                zip(results, resultTypes).allSatisfy({ $0.matches($1) })
            else {
                throw ResumableCallError.resultTypesMismatch(expected: resultTypes, got: results)
            }
        } continuing: { execution, signal, hostCall in
            let function = hostCall.function
            for (index, result) in results.enumerated() {
                hostCall.parameterArea.storeValue(
                    result, at: function.layout.resultReg(index), type: function.resultTypes[index])
            }
            try execution.resume(sp: signal.sp, pc: signal.resumePC)
        }
    }

    /// Completes the host call that the guest is suspended in by throwing `error` from it.
    ///
    /// The guest sees `error` as if the host function had thrown it. A ``WasmKitException``
    /// reaches the guest's exception handlers, and a handler that catches it continues the call.
    /// A ``Trap`` gets the backtrace a synchronous trap at that host call would get, and finishes
    /// the call. Any other error finishes the call as it is. This completes the host call. To
    /// finish a call without letting the guest catch anything, cancel it with
    /// ``resume(throwing:)``.
    ///
    /// Accepting the error neither charges ``Store/fuel`` nor checks the epoch deadline. A
    /// handler that catches it runs under the usual rules, as the guest does after
    /// ``resume(returning:answering:)``.
    ///
    /// - Parameters:
    ///   - error: What the host function throws. It may not be a ``SuspensionRequest``, because
    ///     the host call it completes cannot be suspended again.
    ///   - suspension: The suspension this answers, which must be the one the call is suspended
    ///     with.
    /// - Returns: Whether the function returned or the guest was suspended again, after a guest
    ///   exception handler caught `error`.
    /// - Throws: `error` when the guest does not catch it, or another error that leaves the guest,
    ///   which finishes the call. That holds when `error` is a ``ResumableCallError`` too. The
    ///   method refuses with a ``ResumableCallError`` of its own when the call is not suspended at
    ///   a host call, `suspension` is not its suspension, or `error` is a ``SuspensionRequest``. A
    ///   refusal comes before anything runs and leaves the call as it was.
    public func resume(failing error: any Error, answering suspension: Suspension) throws -> Status {
        let store = function.store
        return try completeHostCall(answering: suspension) { _ in
            if error is SuspensionRequest {
                throw ResumableCallError.requestNotThrowable
            }
        } continuing: { execution, signal, _ in
            if let exception = error as? WasmKitException {
                var sp = signal.sp
                var pc = signal.resumePC
                var md: Md = nil
                var ms: Ms = 0
                guard execution.handleException(exception, sp: &sp, pc: &pc, md: &md, ms: &ms) else {
                    throw exception
                }
                try execution.resume(sp: sp, pc: pc)
            } else if let trap = error as? Trap {
                throw trap.withBacktrace(Execution.captureBacktrace(sp: signal.sp, pc: signal.trapSite, store: store))
            } else {
                throw error
            }
        }
    }

    /// Finishes a call without running any more of it, throwing `error` from where it is.
    ///
    /// This is how to cancel a call, before it starts or whatever it is suspended for. A ``Trap``
    /// gets the backtrace of the suspended guest. At a host call, that is the backtrace a
    /// synchronous trap there would get. The guest cannot catch `error`, so it may not be a
    /// ``WasmKitException``. It may not be a ``SuspensionRequest`` either, which a host function
    /// that cancels a call and rethrows would otherwise pass on as a request to suspend its own
    /// caller.
    ///
    /// - Throws: `error`, which finishes the call, even when it is a ``ResumableCallError``. The
    ///   method refuses with a ``ResumableCallError`` of its own when the call is running or
    ///   finished, or `error` is a ``WasmKitException`` or a ``SuspensionRequest``. A refusal
    ///   leaves the call as it was.
    public func resume(throwing error: any Error) throws -> Never {
        if error is WasmKitException {
            throw ResumableCallError.exceptionNotThrowable
        }
        if error is SuspensionRequest {
            throw ResumableCallError.requestNotThrowable
        }
        if let signal = try state.finish(), let trap = error as? Trap {
            throw trap.withBacktrace(
                Execution.captureBacktrace(sp: signal.sp, pc: signal.trapSite, store: function.store))
        }
        throw error
    }

    /// Completes the host call that the guest is suspended in, when `check` accepts the answer,
    /// and continues the guest.
    ///
    /// Nothing runs and nothing is written unless the call is suspended at a host call,
    /// `suspension` is that suspension, and `check` returns. Otherwise the call is left as it was.
    ///
    /// - Parameters:
    ///   - suspension: The suspension the answer names.
    ///   - check: Validates the answer against the host call, throwing a ``ResumableCallError``
    ///     to refuse it.
    ///   - body: Writes the answer and continues the guest on the call's execution.
    private func completeHostCall(
        answering suspension: Suspension,
        check: (SuspendedHostCall) throws -> Void,
        continuing body: (inout Execution, SuspensionSignal, SuspendedHostCall) throws -> Void
    ) throws -> Status {
        switch state.take() {
        case .suspended(let signal, let stack):
            let hostCall: SuspendedHostCall
            do {
                guard let suspended = signal.hostCall else {
                    throw ResumableCallError.notSuspendedAtHostCall
                }
                guard suspended.identity === suspension.hostCallIdentity else {
                    throw ResumableCallError.otherSuspension
                }
                try check(suspended)
                hostCall = suspended
            } catch {
                state = .suspended(signal, stack)
                throw error
            }
            return try run(on: stack) { execution, _ in
                try body(&execution, signal, hostCall)
            }
        case .ready(let arguments, let stack):
            state = .ready(arguments, stack)
            throw ResumableCallError.notSuspendedAtHostCall
        case .running:
            throw ResumableCallError.alreadyRunning
        case .finished(let stack):
            state = .finished(stack)
            throw ResumableCallError.finished
        }
    }

    private func start(arguments: [Value], on stack: consuming ExecutionStack) throws -> Status {
        let handle = function.handle
        guard handle.isWasm else {
            // A host function has no guest frames to suspend.
            let results: [Value]
            do {
                results = try handle.invokeHost(arguments, store: function.store)
            } catch {
                state = .finished(stack)
                throw error
            }
            state = .finished(stack)
            return .returned(results)
        }
        let type = self.type
        let rootPC = self.rootCode.pc
        return try run(on: stack) { execution, base in
            let sp = try Execution.layOutRootFrame(at: base, type: type, arguments: arguments)
            try execution.execute(sp: sp, pc: rootPC, handle: handle, type: type)
        }
    }

    /// Runs `body` as this call on `stack`, whose start it is given, marking the store as running
    /// a suspendable execution, and records how it stopped.
    private func run(on stack: consuming ExecutionStack, _ body: (inout Execution, Sp) throws -> Void) throws -> Status {
        let store = function.store
        let wasSuspendable = store.isSuspendable
        store.isSuspendable = true
        defer { store.isSuspendable = wasSuspendable }
        let base = stack.slots
        do {
            try body(&execution, base)
        } catch let signal as SuspensionSignal {
            state = .suspended(signal, stack)
            return .suspended(signal.suspension)
        } catch {
            state = .finished(stack)
            throw error
        }
        let results = Execution.readRootResults(sp: base.advanced(by: StackLayout.numberOfSavingSlots), type: type)
        state = .finished(stack)
        return .returned(results)
    }
}
