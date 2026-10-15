import Testing

@testable import WAT

/// `wat2wasm` compiles untrusted text. A malformed input must be a thrown
/// error, never a host abort.
@Suite
struct UntrustedTextTests {

    @Test(
        arguments: [
            // A surplus `end` popped an empty label stack.
            #"(module (func end))"#,
            #"(module (func (block end)))"#,
            #"(module (func loop end end))"#,
            #"(module (global (mut i32) i32.const 0 end))"#,
            // A NaN payload wider than the significand was assembled before it
            // was range-checked, overflowing the fixed-width arithmetic.
            #"(module (func (f32.const nan:0xffffffff)))"#,
            #"(module (func (f64.const nan:0xffffffffffffffff)))"#,
            #"(module (global f32 (f32.const nan:0x80800000)))"#,
            // A data segment naming a memory but giving no offset reached a
            // `fatalError` in the encoder.
            #"(module (memory 1) (data (memory 0) "x"))"#,
            #"(module (memory 1) (data (memory 0)))"#,
        ]
    )
    func malformedTextIsAnErrorNotAnAbort(source: String) throws {
        #expect(throws: (any Error).self) {
            _ = try wat2wasm(source)
        }
    }

    /// The payload check must not reject a NaN the format can represent.
    @Test(
        arguments: [
            #"(module (func (f32.const nan:0x400000) drop))"#,
            #"(module (func (f32.const nan:0x1) drop))"#,
            #"(module (func (f64.const nan:0x8000000000000) drop))"#,
            #"(module (func (f32.const nan) drop))"#,
            #"(module (func (f32.const -nan:0x400000) drop))"#,
        ]
    )
    func aRepresentableNaNPayloadStillAssembles(source: String) throws {
        _ = try wat2wasm(source)
    }
}
