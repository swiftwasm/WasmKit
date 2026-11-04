import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct IntegerMixFusionTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func shiftMaskAndWrappingMultiply(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func (export "mix") (param i64 i64 i64 i64) (result i64)
                    local.get 0 local.get 1 i64.shr_u local.get 2 i64.xor local.get 3 i64.mul)
                  (func (export "reverse") (param i64 i64 i64 i64) (result i64)
                    local.get 3 local.get 2 local.get 0 local.get 1 i64.shr_u i64.xor i64.mul)
                  (func (export "constant") (param i64) (result i64)
                    local.get 0 i64.const 30 i64.shr_u local.get 0 i64.xor
                    i64.const 0xbf58476d1ce4e5b9 i64.mul)
                  (func (export "keep") (param i64 i64 i64 i64) (result i64 i64) (local i64)
                    local.get 0 local.get 1 i64.shr_u local.get 2 i64.xor local.tee 4
                    local.get 3 i64.mul local.get 4))
                """))
        let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: .eager)))
        let instance = try module.instantiate(store: store)
        let mix = try #require(instance.exports[function: "mix"])
        let reverse = try #require(instance.exports[function: "reverse"])
        let constant = try #require(instance.exports[function: "constant"])
        let keep = try #require(instance.exports[function: "keep"])
        for x: UInt64 in [0, 1, .max, 0x8000_0000_0000_0000, 0x1234_5678_9abc_def0] {
            #expect(try constant([.i64(x)]) == [.i64(((x >> 30) ^ x) &* 0xbf58_476d_1ce4_e5b9)])
            for shift: UInt64 in [0, 1, 31, 32, 63, 64, 65, 127, .max] {
                for multiplier: UInt64 in [0, 1, 3, .max, 0xffff_ffff] {
                    let z: UInt64 = 0x7654_3210_fedc_ba98
                    let intermediate = (x >> (shift & 63)) ^ z
                    let expected = Value.i64(intermediate &* multiplier)
                    let args: [Value] = [.i64(x), .i64(shift), .i64(z), .i64(multiplier)]
                    #expect(try mix(args) == [expected])
                    #expect(try reverse(args) == [expected])
                    #expect(try keep(args) == [expected, .i64(intermediate)])
                }
            }
        }
        #if Disassembler
            var listing = ""
            let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let dumpInstance = try module.instantiate(store: dumpStore)
            try dumpInstance.dumpFunctions(to: &listing, module: module)
            if threadingModel == .direct { #expect(listing.contains("i64XorShiftMulImm")) }
        #endif
    }
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func constantShiftMasks(threadingModel: EngineConfiguration.ThreadingModel) throws {
        for shift: UInt64 in [0, 31, 63, 64, 65, .max] {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module (func (export "f") (param i64 i64) (result i64)
                        local.get 0 i64.const \(shift) i64.shr_u local.get 0 i64.xor
                        local.get 1 i64.mul))
                    """))
            let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let instance = try module.instantiate(store: store)
            let f = try #require(instance.exports[function: "f"])
            for x: UInt64 in [0, 1, .max, 0x8000_0000_0000_0000] {
                for multiplier: UInt64 in [3, .max] {
                    #expect(try f([.i64(x), .i64(multiplier)]) == [.i64((x ^ (x >> (shift & 63))) &* multiplier)])
                }
            }
        }
    }

    #if Disassembler
        @Test func localTeeChain() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module (func (export "f") (param i64 i64) (result i64)
                        local.get 1 local.get 0 i64.add local.tee 0
                        i64.const 30 i64.shr_u local.get 0 i64.xor
                        i64.const 0xbf58476d1ce4e5b9 i64.mul local.tee 0
                        i64.const 27 i64.shr_u local.get 0 i64.xor
                        i64.const 0x94d049bb133111eb i64.mul local.tee 0
                        i64.const 31 i64.shr_u local.get 0 i64.xor))
                    """))
            let store = Store(engine: Engine())
            let instance = try module.instantiate(store: store)
            var listing = ""
            try instance.dumpFunctions(to: &listing, module: module)
            #expect(listing.contains("i64XorShiftMulPair"))
        }
    #endif

}
