@testable import WasmKit
import WasmParser
import XCTest
import WAT

final class StoreAllocatorTests: XCTestCase {
    func testBumpAllocatorDeallocates() {
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
            XCTAssertNotNil(weakEntity)
        }
        // The entity should be deallocated when the allocator is deallocated
        XCTAssertNil(weakEntity)
    }

    func testStoreAllocatorLeak() throws {
        weak var weakAllocator: StoreAllocator?
        do {
            let module = try parseWasm(bytes: wat2wasm("""
              (module
                (memory (;0;) 0)
                (export "a" (memory 0)))
            """))
            let runtime = Runtime()
            _ = try runtime.instantiate(module: module)
            weakAllocator = runtime.store.allocator
        }
        XCTAssertNil(weakAllocator)
    }
}
