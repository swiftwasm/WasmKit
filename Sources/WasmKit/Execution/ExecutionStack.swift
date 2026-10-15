/// The stack a guest runs on.
///
/// Every call into a guest needs one, and by default ``Function/invoke(_:)``
/// allocates one for the call and frees it again.
///
/// An embedder that calls in repeatedly (e.g. a game calling exported `update`
/// once a frame) can instead make one of these and hand it to
/// ``Function/invoke(_:on:)``, which is worth doing where allocation is expensive.
public struct ExecutionStack: ~Copyable {
    let slots: UnsafeMutablePointer<StackSlot>
    let count: Int

    /// Allocates a stack of the size `engine` is configured for.
    ///
    /// Taking the engine rather than a size is deliberate: a stack shorter than
    /// the engine expects would be written past rather than reported, and the
    /// size that is right for an engine is already part of its configuration.
    public init(engine: Engine) {
        count = engine.configuration.stackSize / MemoryLayout<StackSlot>.stride
        slots = .allocate(capacity: count)
    }

    deinit {
        slots.deallocate()
    }
}
