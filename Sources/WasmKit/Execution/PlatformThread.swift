#if os(macOS) || os(Linux)
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Glibc)
        import Glibc
    #else
        #error("PlatformThread requires a POSIX threads implementation")
    #endif

    package enum PlatformThreadError: Error {
        case spawnFailed(errorCode: Int32)
        case joinFailed(errorCode: Int32)
        /// `pthread_attr_setstacksize` failed, e.g. `stackSize` below `PTHREAD_STACK_MIN`.
        case stackSizeInvalid(errorCode: Int32)
    }

    /// A `pthread_t` whose ownership was handed off from a ``PlatformThread`` by
    /// ``PlatformThread/release()``. The holder must eventually pass it to
    /// ``PlatformThread/join(_:)`` or ``PlatformThread/detach(_:)``.
    ///
    /// A named wrapper rather than a bare `pthread_t` because that is an `UnsafeMutablePointer` on
    /// Darwin, hence not `Sendable`, which region isolation rejects when a handle crosses a `Mutex`
    /// boundary. Safe to send for the same reason as ``PlatformThread``.
    package struct PlatformThreadHandle: @unchecked Sendable {
        fileprivate let handle: pthread_t
    }

    /// A POSIX thread handle with unique ownership: consume it via `join()`, or let it drop, which
    /// detaches the thread.
    package struct PlatformThread: ~Copyable, @unchecked Sendable {
        // `@unchecked Sendable`: the sole stored property is a `pthread_t`, which the pthread API
        // contract lets any thread pass to `pthread_join`/`pthread_detach`/etc., and `~Copyable`
        // already prevents aliasing it.
        fileprivate let handle: pthread_t

        /// Spawn a thread running `body`. A `stackSize` of 0 uses the system default.
        package static func spawn(
            stackSize: Int,
            body: @Sendable @escaping () -> Void
        ) throws(PlatformThreadError) -> PlatformThread {
            let context = UnsafeMutablePointer<@Sendable () -> Void>.allocate(capacity: 1)
            context.initialize(to: body)

            var attr = pthread_attr_t()
            pthread_attr_init(&attr)
            defer { pthread_attr_destroy(&attr) }

            if stackSize > 0 {
                let rc = pthread_attr_setstacksize(&attr, stackSize)
                guard rc == 0 else {
                    context.deinitialize(count: 1)
                    context.deallocate()
                    throw .stackSizeInvalid(errorCode: rc)
                }
            }

            #if canImport(Darwin)
                var threadHandle: pthread_t?
                let rc = pthread_create(
                    &threadHandle, &attr,
                    { rawContext in
                        Self.runThreadBody(rawContext)
                        return nil
                    }, context)
                guard rc == 0, let threadHandle else {
                    context.deinitialize(count: 1)
                    context.deallocate()
                    throw .spawnFailed(errorCode: rc)
                }
                return PlatformThread(handle: threadHandle)
            #elseif canImport(Musl)
                var threadHandle: pthread_t?
                let rc = pthread_create(
                    &threadHandle, &attr,
                    { rawContext in
                        if let rawContext { Self.runThreadBody(rawContext) }
                        return nil
                    }, context)
                guard rc == 0, let threadHandle else {
                    context.deinitialize(count: 1)
                    context.deallocate()
                    throw .spawnFailed(errorCode: rc)
                }
                return PlatformThread(handle: threadHandle)
            #else
                var threadHandle = pthread_t()
                let rc = pthread_create(
                    &threadHandle, &attr,
                    { rawContext in
                        if let rawContext { Self.runThreadBody(rawContext) }
                        return nil
                    }, context)
                guard rc == 0 else {
                    context.deinitialize(count: 1)
                    context.deallocate()
                    throw .spawnFailed(errorCode: rc)
                }
                return PlatformThread(handle: threadHandle)
            #endif
        }

        /// Runs on the spawned thread, taking ownership of the heap-allocated closure box.
        private static func runThreadBody(_ rawContext: UnsafeMutableRawPointer) {
            let ctx = rawContext.assumingMemoryBound(to: (@Sendable () -> Void).self)
            let body = ctx.pointee
            ctx.deinitialize(count: 1)
            ctx.deallocate()
            body()
        }

        /// Block until this thread terminates. `discard self` keeps `deinit` from detaching the
        /// handle that `pthread_join` has already consumed.
        package consuming func join() throws(PlatformThreadError) {
            let h = handle
            discard self
            try Self.join(handle: h)
        }

        /// Hand ownership of the handle to the caller. `discard self` suppresses the `deinit`
        /// detach, so the returned handle stays joinable.
        package consuming func release() -> PlatformThreadHandle {
            let h = handle
            discard self
            return PlatformThreadHandle(handle: h)
        }

        package static func join(_ owned: PlatformThreadHandle) throws(PlatformThreadError) {
            try Self.join(handle: owned.handle)
        }

        package static func detach(_ owned: PlatformThreadHandle) {
            pthread_detach(owned.handle)
        }

        private static func join(handle: pthread_t) throws(PlatformThreadError) {
            let rc = pthread_join(handle, nil)
            guard rc == 0 else {
                throw .joinFailed(errorCode: rc)
            }
        }

        deinit {
            pthread_detach(handle)
        }
    }
#endif
