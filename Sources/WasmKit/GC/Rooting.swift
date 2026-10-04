// # Rooting
//
// The collector moves objects, so the host never holds an object's offset.
// When a reference to an object leaves Wasm for the host -- as the result of
// `Function.invoke`, a parameter of a host function, the value of a global or
// an element of a table -- the store records the object in its list of host
// roots, and the host gets a handle to the entry: an `AnyRef` (or, for an
// exception, an `ExceptionAddress`) with bit 62 set, the entry's index in bits
// 2 to 33 and its generation above them. The low two bits stay clear, so a
// handle is not mistaken for an i31 or a host value. The collector treats the entries
// as roots and updates them. When a handle comes back, the store looks the
// entry up and checks the generation, so a stale handle is an error instead of
// a reference to another object.
//
// Entries are released in LIFO order, as in wasmtime: when the closure given
// to `Store.withRootScope` returns, every entry made inside it goes away, and so
// do the parameters' entries when a host function returns. Entries made outside
// any scope live as long as the store.

extension GCHeap {
    private static var rootHandleBit: UInt64 { 1 << 62 }

    /// Whether `storage` is the bits of an object reference rather than of a
    /// root handle, an i31 or a host value.
    private static func isRawObject(_ storage: UInt64) -> Bool {
        storage & (rootHandleBit | 0b11) == 0 && storage != 0
    }

    /// Records `object` as held by the host and returns a handle to it.
    func makeRoot(_ object: UInt32) -> UInt64 {
        let generation = nextRootGeneration & 0x0FFF_FFFF
        nextRootGeneration = nextRootGeneration &+ 1
        hostRoots.append((object, generation))
        return Self.rootHandleBit | UInt64(generation) << 34 | UInt64(hostRoots.count - 1) << 2
    }

    /// The object a root handle refers to.
    func resolveRoot(_ handle: UInt64) throws -> UInt32 {
        let index = Int((handle >> 2) & 0xFFFF_FFFF)
        let generation = UInt32(truncatingIfNeeded: handle >> 34) & 0x0FFF_FFFF
        guard index < hostRoots.count, hostRoots[index].generation == generation else {
            throw WasmKitError("attempted to use a garbage-collected object that has been unrooted")
        }
        return hostRoots[index].object
    }

    /// Runs `body`, then releases the roots made while it ran.
    func withRootScope<R>(_ body: () throws -> R) rethrows -> R {
        let count = hostRoots.count
        defer { hostRoots.removeSubrange(count...) }
        return try body()
    }

    /// The value as the host holds it: a reference to an object becomes a handle.
    func exporting(_ value: Value) -> Value {
        switch value {
        case .ref(.any(let reference?)) where Self.isRawObject(reference.storage):
            return .ref(.any(AnyRef(storage: makeRoot(UInt32(truncatingIfNeeded: reference.storage)))))
        case .ref(.externalized(let reference)) where Self.isRawObject(reference.storage):
            return .ref(.externalized(AnyRef(storage: makeRoot(UInt32(truncatingIfNeeded: reference.storage)))))
        case .ref(.exception(let address?)) where MemoryLayout<Int>.size == 8:
            return .ref(.exception(Int(truncatingIfNeeded: makeRoot(UInt32(truncatingIfNeeded: address)))))
        default:
            return value
        }
    }

    /// The value as Wasm holds it: a handle becomes the reference to its object.
    func importing(_ value: Value) throws -> Value {
        switch value {
        case .ref(.any(let reference?)) where reference.storage & Self.rootHandleBit != 0:
            return .ref(.any(AnyRef(storage: UInt64(try resolveRoot(reference.storage)))))
        case .ref(.externalized(let reference)) where reference.storage & Self.rootHandleBit != 0:
            return .ref(.externalized(AnyRef(storage: UInt64(try resolveRoot(reference.storage)))))
        case .ref(.exception(let address?)) where MemoryLayout<Int>.size == 8 && UInt64(UInt(bitPattern: address)) & Self.rootHandleBit != 0:
            return .ref(.exception(Int(try resolveRoot(UInt64(UInt(bitPattern: address))))))
        default:
            return value
        }
    }
}

extension Store {
    /// Runs `body`, then releases the references to GC objects that the host
    /// received while it ran.
    ///
    /// A reference to a struct, an array or an exception that the host gets
    /// from WebAssembly keeps the object alive until the innermost enclosing
    /// call to this method returns, or as long as the store if there is none.
    /// Using it afterwards throws.
    public func withRootScope<R>(_ body: () throws -> R) rethrows -> R {
        try allocator.gcHeap.withRootScope(body)
    }
}
