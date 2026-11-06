import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct XorShiftReturnTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func arithmeticReturnsAndBranchBoundaries(threadingModel: EngineConfiguration.ThreadingModel) throws {
        for shift: UInt64 in [0, 1, 17, 63, 64, 129] {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (func $mix (export "mix") (param i64) (result i64)
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor)
                      (func (export "call") (param i64) (result i64)
                        local.get 0 call $mix)
                      (func (export "explicit") (param i64) (result i64)
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor return)
                      (func (export "branch") (param i64 i32) (result i64)
                        block (result i64)
                          i64.const 7 local.get 1 br_if 0 drop
                          local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor
                        end)
                      (func (export "local") (param i64) (result i64) (local i64)
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor
                        local.tee 1)
                      (func (export "pair") (param i64) (result i64 i64)
                        local.get 0
                        local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor))
                    """))
            for mode in [EngineConfiguration.CompilationMode.lazy, .eager] {
                let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: mode)))
                let instance = try module.instantiate(store: store)
                for x: UInt64 in [0, 1, .max, 0x8000_0000_0000_0000, 0x1234_5678_9abc_def0] {
                    let expected = x ^ (x &>> shift)
                    for name in ["mix", "call", "explicit", "local"] {
                        let function = try #require(instance.exports[function: name])
                        #expect(try function([.i64(x)]) == [.i64(expected)])
                    }
                    let branch = try #require(instance.exports[function: "branch"])
                    #expect(try branch([.i64(x), .i32(0)]) == [.i64(expected)])
                    #expect(try branch([.i64(x), .i32(1)]) == [.i64(7)])
                    let pair = try #require(instance.exports[function: "pair"])
                    #expect(try pair([.i64(x)]) == [.i64(x), .i64(expected)])
                }
            }
            #if Disassembler
                if shift == 17 && threadingModel == .direct {
                    let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
                    let instance = try module.instantiate(store: store)
                    var listing = ""
                    try instance.dumpFunctions(to: &listing, module: module)
                    #expect(listing.contains("i64XorShiftReturn"))
                }
            #endif
        }
    }
}
