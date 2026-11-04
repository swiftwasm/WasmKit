import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct GlobalUpdateFusionTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func preservedLocalAndWrapping(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (global $g (mut i32) (i32.const 0))
                  (func (export "f") (param i32) (result i32 i32) (local i32)
                    local.get 0 i32.const 16 i32.add local.tee 1 global.set $g
                    local.get 1 global.get $g)
                  (func (export "sub") (param i32) (result i32)
                    local.get 0 i32.const 16 i32.sub global.set $g global.get $g)
                  (func (export "join") (param i32 i32) (result i32)
                    block (result i32)
                      local.get 0 local.get 1 br_if 0 drop
                      local.get 0 i32.const 16 i32.add
                    end
                    global.set $g global.get $g))
                """))
        let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
        let instance = try module.instantiate(store: store)
        let f = try #require(instance.exports[function: "f"])
        let sub = try #require(instance.exports[function: "sub"])
        let join = try #require(instance.exports[function: "join"])
        for x: UInt32 in [0, 1, 16, .max, 0xffff_fff0, 0x8000_0000] {
            #expect(try f([.i32(x)]) == [.i32(x &+ 16), .i32(x &+ 16)])
            #expect(try sub([.i32(x)]) == [.i32(x &- 16)])
            #expect(try join([.i32(x), .i32(0)]) == [.i32(x &+ 16)])
            #expect(try join([.i32(x), .i32(1)]) == [.i32(x)])
        }
        #if Disassembler
            let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let dumpInstance = try module.instantiate(store: dumpStore)
            var listing = ""
            try dumpInstance.dumpFunctions(to: &listing, module: module)
            if threadingModel == .direct { #expect(listing.contains("i32AddImmGlobalSet")) }
        #endif
    }
}
