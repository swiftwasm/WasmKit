import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct XorMultiplyPairTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func retainsIntermediateAndWrappingSemantics(threadingModel: EngineConfiguration.ThreadingModel) throws {
        for shift: UInt64 in [0, 17, 63, 64, 129] {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (func (export "pair") (param i64 i64 i64) (result i64 i64) (local i64 i64)
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor local.get 1 i64.mul local.set 3
                        local.get 3 local.get 3 i64.const 31 i64.shr_u i64.xor local.get 2 i64.mul local.set 4
                        local.get 3 local.get 4)
                      (func (export "boundary") (param i64 i64 i64 i32) (result i64) (local i64)
                        block
                          local.get 3 br_if 0
                          local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor local.get 1 i64.mul local.set 4
                        end
                        local.get 4 local.get 4 i64.const 31 i64.shr_u i64.xor local.get 2 i64.mul)
                      (func (export "overwrite") (param i64 i64 i64) (result i64) (local i64)
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor local.get 1 i64.mul local.set 3
                        i64.const 7 local.set 3
                        local.get 3 local.get 3 i64.const 31 i64.shr_u i64.xor local.get 2 i64.mul))
                    """))
            let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let instance = try module.instantiate(store: store)
            for x: UInt64 in [0, 1, .max, 0x8000_0000_0000_0000, 0x1234_5678_9abc_def0] {
                for multiplier: UInt64 in [0, 1, .max, 0xbf58_476d_1ce4_e5b9] {
                    let second: UInt64 = 0x94d0_49bb_1331_11eb
                    let first = (x ^ (x &>> shift)) &* multiplier
                    let expected = (first ^ (first &>> 31)) &* second
                    #expect(try instance.exports[function: "pair"]!([.i64(x), .i64(multiplier), .i64(second)]) == [.i64(first), .i64(expected)])
                    #expect(try instance.exports[function: "boundary"]!([.i64(x), .i64(multiplier), .i64(second), .i32(0)]) == [.i64(expected)])
                    #expect(try instance.exports[function: "boundary"]!([.i64(x), .i64(multiplier), .i64(second), .i32(1)]) == [.i64(0)])
                    #expect(try instance.exports[function: "overwrite"]!([.i64(x), .i64(multiplier), .i64(second)]) == [.i64(7 &* second)])
                }
            }
            #if Disassembler
                if shift == 17 && threadingModel == .direct {
                    let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
                    let dumpInstance = try module.instantiate(store: dumpStore)
                    var listing = ""
                    try dumpInstance.dumpFunctions(to: &listing, module: module)
                    #expect(listing.contains("i64XorShiftMulPair"))
                }
            #endif
        }
    }
}
