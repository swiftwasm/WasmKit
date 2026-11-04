/// A host function's call that a ``ResumableCall`` is suspended at, until the function's
/// continuation gives its results.
///
/// The ``HostContinuation`` completes it, the ``HostWaiter`` watches it, and the call takes the
/// completion when it resumes. Thrown by the host function to unwind to the call handler, which
/// suspends the call there.
final class PendingHostCall: Error, @unchecked Sendable {
    /// Finishes the host function's call when the call resumes, giving its results.
    typealias Completion = (borrowing Caller) throws -> [Value]

    private enum State {
        /// Waiting for the continuation, with what to call once it is resumed.
        case pending([@Sendable () -> Void])
        /// The continuation was resumed; the call has not taken the completion yet.
        case completed
        /// The call took the completion.
        case consumed
        /// The call finished without taking a completion.
        case cancelled
    }

    private var state = PlatformMutex(State.pending([]))
    /// Set once, before `state` becomes `.completed`, and taken by whoever moves it on to
    /// `.consumed`.
    private var completion: Completion?

    #if !$Embedded
        /// The asynchronous body that `ResumableCall.resume()` runs to complete the
        /// call, for a function made with ``Function/async(store:parameters:results:_:)``.
        var asyncCall: AsyncHostCall?
    #endif

    /// Records how the host function's call finishes, and calls what waits for it.
    func complete(_ completion: @escaping Completion) {
        let outcome: (waiters: [@Sendable () -> Void], resumedTwice: Bool) = state.withLock { state in
            switch state {
            case .pending(let waiters):
                self.completion = completion
                state = .completed
                return (waiters, false)
            case .cancelled:
                return ([], false)
            case .completed, .consumed:
                return ([], true)
            }
        }
        precondition(!outcome.resumedTwice, "a host continuation was resumed more than once")
        for waiter in outcome.waiters {
            waiter()
        }
    }

    /// Takes the completion, once the continuation has been resumed.
    func takeCompletion() -> Completion? {
        let taken: Bool = state.withLock { state in
            guard case .completed = state else { return false }
            state = .consumed
            return true
        }
        guard taken else { return nil }
        defer { completion = nil }
        return completion
    }

    /// Drops the completion, if any, and what waits for it: the call finished without it.
    func cancel() {
        let dropsCompletion: Bool = state.withLock { state in
            switch state {
            case .pending:
                state = .cancelled
                return false
            case .completed:
                state = .cancelled
                return true
            case .consumed, .cancelled:
                return false
            }
        }
        if dropsCompletion {
            completion = nil
        }
    }

    var isCompleted: Bool {
        state.withLock { state in
            switch state {
            case .completed, .consumed: return true
            case .pending, .cancelled: return false
            }
        }
    }

    /// Calls `body` once the continuation is resumed: now, if it already has been.
    func onCompletion(_ body: @escaping @Sendable () -> Void) {
        let now: Bool = state.withLock { state in
            switch state {
            case .pending(let waiters):
                state = .pending(waiters + [body])
                return false
            case .completed, .consumed:
                return true
            case .cancelled:
                return false
            }
        }
        if now {
            body()
        }
    }
}

/// How a host function made with ``Function/suspending(store:parameters:results:_:)`` gives its
/// results once its work is done.
///
/// Resume it exactly once, from any thread; resuming it twice traps. Resuming it records the
/// results; the guest continues only when the code driving the ``ResumableCall`` resumes the
/// call, and a completion runs then, on that code's thread. A continuation resumed after the
/// call has finished without it, such as one cancelled with
/// ``ResumableCall/resume(throwing:)``, does nothing.
public struct HostContinuation: Sendable {
    let pending: PendingHostCall

    /// Finishes the host function's call with `completion`, which runs when the call resumes, in
    /// the function's place: it can read and write memory, and returns the function's results.
    /// An error it throws is thrown from the call, where the guest can catch a
    /// ``WasmKitException``.
    public func resume(_ completion: @escaping (borrowing Caller) throws -> [Value]) {
        pending.complete(completion)
    }

    /// Finishes the host function's call with `results`.
    public func resume(returning results: [Value]) {
        pending.complete { _ in results }
    }

    /// Finishes the host function's call by throwing `error` from it, where the guest can catch a
    /// ``WasmKitException``.
    public func resume(throwing error: any Error) {
        pending.complete { _ in throw error }
    }
}

/// What a ``ResumableCall`` waiting for a host function can tell about that wait.
///
/// It belongs to one wait: a call that resumes and waits again has a new waiter. Resuming the
/// call before the waiter is ready leaves the call waiting.
public struct HostWaiter: Sendable, Equatable {
    let pending: PendingHostCall

    /// Whether the host function has given its results, so resuming the call continues it.
    ///
    /// Once true, it stays true.
    public var isReadyToResume: Bool { pending.isCompleted }

    /// Calls `body` once the host function has given its results: now, if it has, or else on the
    /// thread that resumes the function's continuation.
    ///
    /// `body` is not called if the call finishes without the results.
    public func onReady(_ body: @escaping @Sendable () -> Void) {
        pending.onCompletion(body)
    }

    public static func == (lhs: HostWaiter, rhs: HostWaiter) -> Bool {
        lhs.pending === rhs.pending
    }
}

extension Function {
    /// Creates a host function that finishes when it resumes the continuation it is given,
    /// which it may do after it returns.
    ///
    /// Until then, the ``ResumableCall`` that called it is suspended with
    /// ``Suspension/waitingForHost(_:)``. A call can be suspended only when it runs as a
    /// ``ResumableCall`` and no other host function lies between it and this one, which
    /// ``Caller/canSuspend`` tells; elsewhere, returning without resuming the continuation traps.
    /// Resuming it before returning works anywhere, and the guest continues at once.
    ///
    /// An error `body` throws is thrown from the call, as from any host function, and the
    /// continuation is no longer used.
    ///
    /// ```swift
    /// let fetch = Function.suspending(store: store, parameters: [.i32], results: [.i32]) { caller, arguments, continuation in
    ///     request.onResponse = { response in
    ///         continuation.resume { caller in
    ///             try write(response.body, to: caller)
    ///             return [.i32(UInt32(response.body.count))]
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - store: The store to allocate the function in.
    ///   - parameters: The types of the function parameters.
    ///   - results: The types of the function results.
    ///   - body: The implementation of the function.
    public static func suspending(
        store: Store,
        parameters: [ValueType], results: [ValueType] = [],
        _ body: @escaping (borrowing Caller, [Value], HostContinuation) throws -> Void
    ) -> Function {
        suspending(store: store, type: FunctionType(parameters: parameters, results: results)) { caller, arguments in
            let pending = PendingHostCall()
            try body(caller, arguments, HostContinuation(pending: pending))
            return pending
        }
    }

    /// Creates a host function from `body`, which starts the call and returns its pending state.
    static func suspending(
        store: Store, type: FunctionType,
        _ body: @escaping (borrowing Caller, [Value]) throws -> PendingHostCall
    ) -> Function {
        let results = type.results
        let implementation: RawImplementation = { caller, parameters, out in
            let pending = try body(caller, Array(parameters))
            if let completion = pending.takeCompletion() {
                return try write(completion(caller), to: out, types: results)
            }
            try wait(for: pending, caller: caller)
        }
        return Function(
            handle: store.allocator.allocate(type: type, implementation: implementation, engine: store.engine),
            store: store)
    }

    /// Unwinds to the call handler that called the host function, which suspends the call there;
    /// or traps if the call cannot be suspended.
    @inline(never)
    static func wait(for pending: PendingHostCall, caller: borrowing Caller) throws -> Never {
        guard caller.canSuspend else {
            pending.cancel()
            throw Trap(.hostSuspensionNotAllowed)
        }
        throw pending
    }
}
