/// A value stored inline in whatever contains it, addressable without copying it.
///
/// `@_rawLayout` gives the type the layout of `Value` and no stored properties of its own, so a
/// cell held by a class lives at a fixed offset inside that object rather than in an allocation of
/// its own, and its address can be taken from a borrow. Reaching a value that way costs neither
/// the retain and release that writing a stored property through an unmanaged reference does, nor
/// the allocation that a pointer to separate storage would.
@_rawLayout(like: Value, movesAsLike)
struct Cell<Value: ~Copyable>: ~Copyable {
    /// The address of the stored value, valid for as long as the cell is alive.
    ///
    /// The cell is non-copyable and has no stored properties, so this is the raw-layout storage
    /// itself rather than a temporary copy of it.
    @inline(__always)
    var address: UnsafeMutablePointer<Value> {
        UnsafeMutablePointer(
            mutating: withUnsafePointer(to: self) {
                UnsafeRawPointer($0).assumingMemoryBound(to: Value.self)
            }
        )
    }

    /// The stored value.
    @inline(__always)
    var value: Value {
        _read { yield address.pointee }
        nonmutating _modify { yield &address.pointee }
    }

    init(_ initialValue: consuming Value) {
        address.initialize(to: initialValue)
    }

    deinit {
        address.deinitialize(count: 1)
    }
}
