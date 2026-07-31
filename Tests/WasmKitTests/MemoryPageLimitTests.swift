import Testing

@testable import WasmKit

@Suite struct MemoryPageLimitTests {
    /// A 32-bit wasm memory addresses 4 GiB, which is 65536 pages of 64 KiB.
    ///
    /// Regression guard: computing this as `UInt64(1 << 32)` evaluates the
    /// shift as `Int`, which is 32 bits wide on targets like riscv32. It wraps
    /// to zero there, so the validator rejected every guest that declared a
    /// memory -- while remaining correct on 64-bit hosts, where this test runs.
    /// Keep the shift in the UInt64 domain.
    @Test func aThirtyTwoBitMemoryAllowsTheFullPageRange() {
        #expect(MemoryEntity.maxPageCount(isMemory64: false) == 65536)
    }

    @Test func aSixtyFourBitMemoryIsUnbounded() {
        #expect(MemoryEntity.maxPageCount(isMemory64: true) == UInt64.max)
    }
}
