#if !$Embedded

    /// The context an asynchronous host function is called in.
    ///
    /// Unlike ``Caller``, it stays valid across suspension points: the guest that called the
    /// function is suspended until it returns, and nothing here caches where a memory is, so a
    /// memory that grows meanwhile is found where it moved to.
    public struct AsyncCaller {
        private let instanceHandle: InternalInstance?

        /// The store associated with the caller execution context.
        public let store: Store

        /// The instance that called the host function.
        /// - Note: This property is `nil` if the function is called directly rather than from
        ///   WebAssembly.
        public var instance: Instance? {
            guard let instanceHandle else { return nil }
            return Instance(handle: instanceHandle, store: store)
        }

        /// The engine associated with the caller execution context.
        public var engine: Engine { store.engine }

        init(_ caller: borrowing Caller) {
            self.instanceHandle = caller.instanceHandle
            self.store = caller.store
        }
    }

    /// An asynchronous host function's call, which an awaited `ResumableCall.resume()`
    /// runs while the call waits for it.
    struct AsyncHostCall {
        let body: nonisolated(nonsending) (AsyncCaller, [Value]) async throws -> [Value]
        let caller: AsyncCaller
        let arguments: [Value]
    }

    extension Function {
        /// Creates a host function written as an `async` closure.
        ///
        /// It runs only in calls that are awaited: ``invokeAsync(_:)``, and a ``ResumableCall``
        /// resumed with `await`. The call waits while the closure runs, and continues with its
        /// results. Called any other way, it traps.
        ///
        /// - Parameters:
        ///   - store: The store to allocate the function in.
        ///   - parameters: The types of the function parameters.
        ///   - results: The types of the function results.
        ///   - body: The implementation of the function.
        public static func `async`(
            store: Store,
            parameters: [ValueType], results: [ValueType] = [],
            _ body: nonisolated(nonsending) @escaping (AsyncCaller, [Value]) async throws -> [Value]
        ) -> Function {
            suspending(store: store, type: FunctionType(parameters: parameters, results: results)) { caller, arguments in
                let pending = PendingHostCall()
                pending.asyncCall = AsyncHostCall(body: body, caller: AsyncCaller(caller), arguments: arguments)
                return pending
            }
        }

        /// Invokes the function with the given arguments, waiting for the host functions it calls
        /// that suspend, including those created with ``async(store:parameters:results:_:)``.
        ///
        /// Otherwise the call is like ``invoke(_:)``: running out of fuel or reaching the epoch
        /// deadline traps. To handle those, resume a ``ResumableCall`` with `await` instead.
        ///
        /// - Note: The call runs as a ``ResumableCall``, which suspends for a bulk memory or table
        ///   operation's fuel before the operation checks its bounds. Out of fuel there, it traps
        ///   for the fuel where a plain call traps for the bounds.
        ///
        /// - Returns: The results of the function.
        nonisolated(nonsending) public func invokeAsync(_ arguments: [Value] = []) async throws -> [Value] {
            let call = try ResumableCall(function: self, arguments: arguments)
            switch try await call.resume() {
            case .returned(let results):
                return results
            case .suspended(.outOfFuel):
                try call.resume(throwing: Trap(.outOfFuel))
            case .suspended(.epochDeadlineReached):
                try call.resume(throwing: Trap(.epochDeadlineReached))
            case .suspended(.waitingForHost):
                fatalError("an awaited resume does not return while the call waits for a host function")
            }
        }
    }

    extension ResumableCall {
        /// Starts the call, or continues it after a suspension, waiting for the host functions the
        /// guest calls that suspend: it runs those created with
        /// ``Function/async(store:parameters:results:_:)``, and waits for the others' continuations.
        ///
        /// - Returns: Whether the function returned or the guest was suspended for fuel or the
        ///   epoch deadline.
        /// - Throws: A trap, or another error the guest raised, which finishes the call; or a
        ///   ``ResumableCallError`` if the call cannot be resumed, which leaves it as it was.
        nonisolated(nonsending) public func resume() async throws -> Status {
            var status = try resumeOnce()
            while case .suspended(.waitingForHost(let waiter)) = status {
                let pending = waiter.pending
                if let call = pending.asyncCall {
                    pending.asyncCall = nil
                    do {
                        let results = try await call.body(call.caller, call.arguments)
                        pending.complete { _ in results }
                    } catch {
                        pending.complete { _ in throw error }
                    }
                } else if !pending.isCompleted {
                    await withCheckedContinuation { continuation in
                        pending.onCompletion { continuation.resume() }
                    }
                }
                status = try resumeOnce()
            }
            return status
        }
    }

#endif
