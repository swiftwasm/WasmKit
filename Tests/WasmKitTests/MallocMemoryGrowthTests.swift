import Testing
import WAT
import WasmParser

@testable import WasmKit

/// A memory under software bounds checking lives in a malloc'd block. Growing it extends the
/// block when the growth is smaller than the memory and allocates a new zeroed one otherwise;
/// either way the old bytes are kept and the new ones are zero.
@Suite
struct MallocMemoryGrowthTests {
    static let wat = """
        (module
          (memory (export "memory") 1)
          (func (export "grow") (param i32) (result i32) (memory.grow (local.get 0)))
          (func (export "load") (param i32) (result i32) (i32.load (local.get 0)))
          (func (export "store") (param i32 i32) (i32.store (local.get 0) (local.get 1)))
          ;; Whether every byte in [from, to) is zero; both multiples of 8.
          (func (export "isZero") (param $from i32) (param $to i32) (result i32)
            (loop $next
              (if (i32.ge_u (local.get $from) (local.get $to)) (then (return (i32.const 1))))
              (if (i64.ne (i64.load (local.get $from)) (i64.const 0)) (then (return (i32.const 0))))
              (local.set $from (i32.add (local.get $from) (i32.const 8)))
              (br $next))
            (i32.const 0))
          (func (export "fill") (param $from i32) (param $to i32) (param $byte i32)
            (memory.fill (local.get $from) (local.get $byte) (i32.sub (local.get $to) (local.get $from))))
        )
        """

    struct Fixture {
        let store: Store
        let instance: Instance

        init() throws {
            store = Store(engine: Engine(configuration: .init(memoryBoundsChecking: .software)))
            instance = try parseWasm(bytes: wat2wasm(MallocMemoryGrowthTests.wat)).instantiate(store: store)
        }

        func callAsFunction(_ name: String, _ arguments: [Value]) throws -> [Value] {
            let function = try #require(instance.exports[function: name])
            return try function(arguments)
        }
    }

    static let page = 65536

    @Test
    func growingAPageAtATimeKeepsTheBytesAndZeroesTheNewPages() throws {
        // Leave dirty blocks behind for the allocator to hand out again.
        for _ in 0..<4 {
            let dirty = try Fixture()
            _ = try dirty("grow", [.i32(63)])
            _ = try dirty("fill", [.i32(0), .i32(UInt32(64 * Self.page)), .i32(0xAB)])
        }

        let fixture = try Fixture()
        for pages in 1..<300 {
            #expect(try fixture("grow", [.i32(1)]) == [.i32(UInt32(pages))])
            let start = UInt32(pages * Self.page)
            #expect(try fixture("isZero", [.i32(start), .i32(start + UInt32(Self.page))]) == [.i32(1)])
            // Mark the new page, and check the marks of every page before it.
            _ = try fixture("store", [.i32(start), .i32(UInt32(pages))])
            if pages % 50 == 0 {
                for earlier in 1...pages {
                    #expect(try fixture("load", [.i32(UInt32(earlier * Self.page))]) == [.i32(UInt32(earlier))])
                }
            }
        }
        #expect(try fixture.instance.exports[memory: "memory"]?.byteCount == 300 * Self.page)
    }

    @Test
    func growingByAtLeastTheMemorysSizeKeepsTheBytesAndZeroesTheNewPages() throws {
        let fixture = try Fixture()
        _ = try fixture("store", [.i32(8), .i32(0x1234_5678)])
        var pages = 1
        for _ in 0..<6 {
            // By the whole size, then by more than it.
            let delta = pages == 4 ? pages * 3 : pages
            #expect(try fixture("grow", [.i32(UInt32(delta))]) == [.i32(UInt32(pages))])
            let oldEnd = UInt32(pages * Self.page)
            pages += delta
            #expect(try fixture("isZero", [.i32(oldEnd), .i32(UInt32(pages * Self.page))]) == [.i32(1)])
            #expect(try fixture("load", [.i32(8)]) == [.i32(0x1234_5678)])
            #expect(throws: Trap.self) { try fixture("load", [.i32(UInt32(pages * Self.page))]) }
        }
    }

    @Test
    func manyGrowthsKeepEarlierBytes() throws {
        let fixture = try Fixture()
        let memory = try #require(fixture.instance.exports[memory: "memory"])
        _ = try fixture("store", [.i32(16), .i32(77)])
        for _ in 0..<100 {
            #expect(try fixture("grow", [.i32(1)]).first != .i32(UInt32(bitPattern: -1)))
        }
        #expect(memory.byteCount == 101 * Self.page)
        #expect(try fixture("load", [.i32(16)]) == [.i32(77)])
        #expect(try fixture("isZero", [.i32(UInt32(Self.page)), .i32(UInt32(101 * Self.page))]) == [.i32(1)])
    }
}
