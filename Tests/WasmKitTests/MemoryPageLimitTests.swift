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

    /// A memory64 minimum can name far more pages than `Int` can hold bytes for.
    /// `Int(memoryType.min) * pageSize` overflowed and trapped the host process
    /// instead of reporting that the guest asked for too much memory.
    @Test func aMemory64MinimumBeyondTheByteRangeIsRejected() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,  // magic and version
            // memory: [0] = memory64, min = 15719607437819261 pages, no max
            0x05, 0x0A, 0x01, 0x04, 0xFD, 0xFA, 0xDB, 0x8A, 0xE5, 0x9C, 0xF6, 0x1B,
        ]
        let module = try parseWasm(bytes: bytes, features: .all)
        let store = Store(engine: Engine())
        #expect(throws: (any Error).self) {
            try module.instantiate(store: store)
        }
    }
}
