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
    /// - Returns: Whether the function returned or the guest was suspended again.
    /// - Throws: A trap, or another error the guest raised, which finishes the call; or a
    ///   ``ResumableCallError`` if the call cannot be resumed, which leaves it as it was.
    public func resume() throws -> Status {
        switch state.take() {
        case .ready(let arguments, let stack):
            return try start(arguments: arguments, on: stack)
        case .suspended(let signal, let stack):
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

    /// Finishes a call without running any more of it, throwing `error` from where it is.
    ///
    /// This is how to cancel a call. A ``Trap`` gets the backtrace of the suspended guest. The
    /// guest cannot catch `error`, so it may not be a ``WasmKitException``.
    ///
    /// - Throws: `error`, which finishes the call; or a ``ResumableCallError`` if the call is
    ///   running or finished, or `error` is a ``WasmKitException``, which leaves it as it was.
    public func resume(throwing error: any Error) throws -> Never {
        if error is WasmKitException {
            throw ResumableCallError.exceptionNotThrowable
        }
        if let signal = try state.finish(), let trap = error as? Trap {
            // A trap site is just past the head slot of the instruction that raised it.
            throw trap.withBacktrace(
                Execution.captureBacktrace(sp: signal.sp, pc: signal.resumePC + 1, store: function.store))
        }
        throw error
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
