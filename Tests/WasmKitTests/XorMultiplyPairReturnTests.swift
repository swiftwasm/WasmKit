import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct XorMultiplyPairReturnTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func wrappingReturnsAndMemoryRestoration(threadingModel: EngineConfiguration.ThreadingModel) throws {
        for shift: UInt64 in [0, 17, 63, 64, 129] {
            let prefix = """
                local.get 0 local.get 0 i64.const \(shift) i64.shr_u i64.xor local.get 1 i64.mul local.set 4
                local.get 4 local.get 4 i64.const 27 i64.shr_u i64.xor local.get 2 i64.mul local.set 5
                """
            let suffix = "local.get 5 local.get 5 i64.const \(shift) i64.shr_u i64.xor"
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module (memory 1) (data (i32.const 0) "wxyz")
                      (func $mix (export "mix") (param i64 i64 i64) (result i64) (local i32 i64 i64)
                        \(prefix) \(suffix))
                      (func (export "explicit") (param i64 i64 i64) (result i64) (local i32 i64 i64)
                        \(prefix) \(suffix) return)
                      (func (export "nested") (param i64 i64 i64) (result i64)
                        local.get 0 local.get 1 local.get 2 call $mix)
                      (func (export "branch") (param i64 i64 i64 i32) (result i64) (local i64 i64)
                        block local.get 3 br_if 0 \(prefix) end \(suffix)))
                    """))
            for mode in [EngineConfiguration.CompilationMode.lazy, .eager] {
                let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: mode)))
                let instance = try module.instantiate(store: store)
                var imports = Imports()
                imports.define(module: "other", name: "mix", try #require(instance.exports[function: "mix"]))
                let caller = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module (import "other" "mix" (func $mix (param i64 i64 i64) (result i64)))
                          (memory 1) (data (i32.const 0) "abcd")
                          (func (export "cross") (param i64 i64 i64) (result i64 i32)
                            local.get 0 local.get 1 local.get 2 call $mix
                            i32.const 0 i32.load))
                        """)
                ).instantiate(store: store, imports: imports)
                for x: UInt64 in [0, 1, .max, 0x8000_0000_0000_0000, 0x1234_5678_9abc_def0] {
                    for multiplier: UInt64 in [0, 1, .max, 0xbf58_476d_1ce4_e5b9] {
                        let m1: UInt64 = 0x94d0_49bb_1331_11eb
                        let first = (x ^ (x &>> shift)) &* multiplier
                        let second = (first ^ (first &>> 27)) &* m1
                        let expected = second ^ (second &>> shift)
                        let args: [Value] = [.i64(x), .i64(multiplier), .i64(m1)]
                        for name in ["mix", "explicit", "nested"] {
                            #expect(try instance.exports[function: name]!(args) == [.i64(expected)])
                        }
                        #expect(try instance.exports[function: "branch"]!(args + [.i32(0)]) == [.i64(expected)])
                        #expect(try instance.exports[function: "branch"]!(args + [.i32(1)]) == [.i64(0)])
                        #expect(try caller.exports[function: "cross"]!(args) == [.i64(expected), .i32(0x6463_6261)])
                    }
                }
            }
            #if Disassembler
                if shift == 17 && threadingModel == .direct {
                    let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
                    let instance = try module.instantiate(store: store)
                    var listing = ""
                    try instance.dumpFunctions(to: &listing, module: module)
                    #expect(listing.contains("i64XorShiftMulPairReturn"))
                }
            #endif
        }
    }
}
