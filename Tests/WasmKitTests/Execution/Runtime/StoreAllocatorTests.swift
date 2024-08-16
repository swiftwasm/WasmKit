@testable import WasmKit
import WasmParser
import XCTest

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
}
