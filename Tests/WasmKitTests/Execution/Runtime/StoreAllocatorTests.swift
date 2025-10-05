#if canImport(Testing)
    import WAT
    import WasmParser
    import Testing

    @testable import WasmKit

    @Suite
    struct StoreAllocatorTests {
        @Test
        func bumpAllocatorDeallocates() {
            class NonTrivialEntity {}
            weak var weakEntity: NonTrivialEntity?
            do {
                let allocator = BumpAllocator<NonTrivialEntity>(initialCapacity: 2)
                do {
                    let entity = NonTrivialEntity()
                    // Allocate space placing non-trivial entity
                    // This `allocate` call should retain the entity
                    _ = allocator.allocate(initializing: entity)
                    // Ensure that the initial page is full
                    _ = allocator.allocate(initializing: entity)
                    _ = allocator.allocate(initializing: entity)
                    weakEntity = entity
                }
                // The entity is still alive because the allocator retains it
                #expect(weakEntity != nil)
            }
            // The entity should be deallocated when the allocator is deallocated
            #expect(weakEntity == nil)
        }

        @Test
        func storeAllocatorLeak() throws {
            weak var weakAllocator: StoreAllocator?
            do {
                let module = try parseWasm(
                    bytes: wat2wasm(
                        """
                          (module
                            (memory (;0;) 0)
                            (export "a" (memory 0)))
                        """))
                let engine = Engine()
                let store = Store(engine: engine)
                _ = try module.instantiate(store: store)
                weakAllocator = store.allocator
            }
            #expect(weakAllocator == nil)
        }
    }

#endif
