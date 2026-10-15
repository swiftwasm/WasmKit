import CWasmKitWASIThreads

/// The Swift side of the pthread ownership transfer. The C shim knows only an
/// opaque pointer; the retained box is released exactly once by either the
/// callback or the failed caller path.
enum PlatformThread {
    fileprivate final class Box: @unchecked Sendable {
        let body: @Sendable () -> Void

        init(body: @escaping @Sendable () -> Void) {
            self.body = body
        }
    }

    static func start(stackSize: Int?, body: @escaping @Sendable () -> Void) -> Int32 {
        let opaque = Unmanaged.passRetained(Box(body: body)).toOpaque()
        let result = wasmkit_wasi_threads_start(wasiThreadsThreadEntry, opaque, numericCast(stackSize ?? 0))
        if result != 0 {
            Unmanaged<Box>.fromOpaque(opaque).release()
        }
        return result
    }
}

private let wasiThreadsThreadEntry: @convention(c) (UnsafeMutableRawPointer?) -> Void = { opaque in
    guard let opaque else { return }
    let box = Unmanaged<PlatformThread.Box>.fromOpaque(opaque).takeRetainedValue()
    box.body()
}
