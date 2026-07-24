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

    /// A wrapper around a POSIX thread handle.
    ///
    /// `~Copyable` because a `pthread_t` handle is a unique OS resource.
    /// You must either consume it via `join()` or let it drop (which detaches
    /// the thread as a safety net so the OS reclaims resources when it terminates).
    package struct PlatformThread: ~Copyable, @unchecked Sendable {
        // `@unchecked Sendable`: the sole stored property is a `pthread_t` handle,
        // which is safe to transfer across threads by pthread API contract: every
        // `pthread_*` call (join, detach, kill, ...) accepts a handle from any thread.
        // `~Copyable` already enforces unique ownership of the handle.
        fileprivate let handle: pthread_t

        /// Spawn a thread running `body`. A `stackSize` of 0 uses the system default.
        package static func spawn(
            stackSize: Int,
            body: @Sendable @escaping () -> Void
        ) throws(PlatformThreadError) -> PlatformThread {
            // Heap-allocate the closure so it can be passed through the C trampoline.
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

        /// Runs on the spawned thread; unboxes and frees the heap closure before invoking it.
        private static func runThreadBody(_ rawContext: UnsafeMutableRawPointer) {
            let ctx = rawContext.assumingMemoryBound(to: (@Sendable () -> Void).self)
            let body = ctx.pointee
            ctx.deinitialize(count: 1)
            ctx.deallocate()
            body()
        }

        /// Block until this thread terminates. `consuming`, so `deinit` does not
        /// afterward detach the handle.
        package consuming func join() throws(PlatformThreadError) {
            let h = handle
            discard self
            let rc = pthread_join(h, nil)
            guard rc == 0 else {
                throw .joinFailed(errorCode: rc)
            }
        }

        deinit {
            pthread_detach(handle)
        }
    }
#endif
