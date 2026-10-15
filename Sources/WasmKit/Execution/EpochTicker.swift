import _CWasmKit

/// Advances an engine's epoch, from any thread.
///
/// Get one from ``Engine/epochTicker`` and send it to whichever thread should stop guest code,
/// such as a timer. Calling ``increment()`` is the only thing it does, so it can be shared without
/// sharing the engine. A ticker can outlive its engine, and incrementing it then does nothing.
///
/// ```swift
/// let ticker = engine.epochTicker
/// Thread.detachNewThread {
///     while true {
///         Thread.sleep(forTimeInterval: 0.01)
///         ticker.increment()
///     }
/// }
/// ```
public final class EpochTicker: @unchecked Sendable {  // The counter is only accessed atomically.
    /// The epoch. Stores cache its address, so it must not move.
    let counter = Cell<UInt64>(0)

    init() {}

    /// Advances the epoch by one tick.
    ///
    /// A tick is whatever the embedder makes it, typically a timer firing. Guest code at or past
    /// its store's deadline stops at its next check: a ``ResumableCall`` suspends, and any other
    /// call traps. The check does not synchronize with the increment, so a running guest notices
    /// the new epoch shortly after, not at once.
    public func increment() {
        wasmkit_epoch_increment(counter.address)
    }
}
