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
    }

    /// What suspended the call.
    public let reason: Reason
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
    static var exceptionNotThrowable: ResumableCallError {
        ResumableCallError(description: "a WebAssembly exception cannot be thrown into a call suspended at a fuel check")
    }
}

/// How the guest stopped: where to continue from.
///
/// Thrown by the code that suspends, and caught by ``ResumableCall``. The frames between `sp` and
/// the root frame stay on the call's stack while it is suspended.
struct SuspensionSignal: Error, @unchecked Sendable {
    let reason: Suspension.Reason
    /// The frame to continue in.
    let sp: Sp
    /// The head slot to continue from.
    let resumePC: Pc

    var suspension: Suspension {
        Suspension(reason: reason)
    }
}

/// A call to a function that can be suspended and resumed.
///
/// A resumable call runs its guest on a stack of its own, which stays alive while the call is
/// suspended. With ``EngineConfiguration/fuelMetering``, running out of ``Store/fuel`` suspends
/// the guest instead of trapping.
///
/// ```swift
/// let call = try ResumableCall(function: run, arguments: [])
/// var status = try call.resume()
/// while case .suspended(let suspension) = status {
///     switch suspension.reason {
///     case .outOfFuel(let required):
///         store.fuel = Fuel(remaining: max(required, 10_000))
///     }
///     status = try call.resume()
/// }
/// ```
///
/// Any number of resumable calls can be suspended on one store at a time, and resumed in any
/// order. A host function can run another resumable call too.
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

    private enum State {
        /// Not started; holds the arguments.
        case ready([Value])
        case running
        case suspended(SuspensionSignal)
        case finished
    }

    /// The function this call runs.
    public let function: Function
    private let type: FunctionType
    private var stack: ExecutionStack?
    /// The start of `stack`, kept apart so that reading it does not need the stack.
    private let stackBase: Sp
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
        self.stackBase = stack.slots
        // `StoreRef` does not retain the store, so it must not outlive it. It cannot: the
        // execution lives as long as this call, which retains `function`, which retains its store.
        self.execution = Execution(store: StoreRef(store), stackEnd: stack.slots.advanced(by: stack.count))
        self.stack = consume stack
        self.rootCode = Execution.RootCode(threadingModel: store.engine.configuration.threadingModel)
        self.state = .ready(arguments)
    }

    /// Whether the function has returned, or the call failed.
    public var isFinished: Bool {
        if case .finished = state { return true }
        return false
    }

    /// Why the call is suspended, or `nil` when it is not.
    public var suspension: Suspension? {
        guard case .suspended(let signal) = state else { return nil }
        return signal.suspension
    }

    /// Takes the call's stack back, to use it again. `nil` until the call has finished, and once
    /// the stack has been taken.
    public func takeStack() -> ExecutionStack? {
        guard case .finished = state else { return nil }
        return stack.take()
    }

    /// Starts the call, or continues it after a suspension.
    ///
    /// - Returns: Whether the function returned or the guest was suspended again.
    /// - Throws: A trap, or another error the guest raised, which finishes the call; or a
    ///   ``ResumableCallError`` if the call cannot be resumed, which leaves it as it was.
    public func resume() throws -> Status {
        switch state {
        case .ready(let arguments):
            return try start(arguments: arguments)
        case .suspended(let signal):
            return try run { execution in
                try execution.resume(sp: signal.sp, pc: signal.resumePC)
            }
        case .running:
            throw ResumableCallError.alreadyRunning
        case .finished:
            throw ResumableCallError.finished
        }
    }

    /// Finishes a call without running any more of it, throwing `error` from where it is.
    ///
    /// This is how to cancel a call. A ``Trap`` gets the backtrace of the suspended guest. The
    /// guest cannot catch `error`, so it may not be a ``WasmKitException``.
    ///
    /// - Throws: `error`, which finishes the call; or a ``ResumableCallError`` if the call is
    ///   running or finished, or `error` is a ``WasmKitException``, which leaves it as it was.
    public func resume(throwing error: any Error) throws -> Never {
        let signal: SuspensionSignal?
        switch state {
        case .ready:
            signal = nil
        case .suspended(let suspended):
            signal = suspended
        case .running:
            throw ResumableCallError.alreadyRunning
        case .finished:
            throw ResumableCallError.finished
        }
        if error is WasmKitException {
            throw ResumableCallError.exceptionNotThrowable
        }
        state = .finished
        if let signal, let trap = error as? Trap {
            // A trap site is just past the head slot of the instruction that raised it.
            throw trap.withBacktrace(
                Execution.captureBacktrace(sp: signal.sp, pc: signal.resumePC + 1, store: function.store))
        }
        throw error
    }

    private func start(arguments: [Value]) throws -> Status {
        let handle = function.handle
        guard handle.isWasm else {
            // A host function has no guest frames to suspend.
            state = .running
            defer { state = .finished }
            return .returned(try handle.invokeHost(arguments, store: function.store))
        }
        let sp = try Execution.layOutRootFrame(at: stackBase, type: type, arguments: arguments)
        let type = self.type
        let rootPC = self.rootCode.pc
        return try run { execution in
            try execution.execute(sp: sp, pc: rootPC, handle: handle, type: type)
        }
    }

    /// Runs `body` as this call, marking the store as running a suspendable execution, and
    /// records how it stopped.
    private func run(_ body: (inout Execution) throws -> Void) throws -> Status {
        let store = function.store
        let wasSuspendable = store.isSuspendable
        store.isSuspendable = true
        defer { store.isSuspendable = wasSuspendable }
        state = .running
        do {
            try body(&execution)
        } catch let signal as SuspensionSignal {
            state = .suspended(signal)
            return .suspended(signal.suspension)
        } catch {
            state = .finished
            throw error
        }
        state = .finished
        return .returned(Execution.readRootResults(sp: stackBase.advanced(by: StackLayout.numberOfSavingSlots), type: type))
    }
}
