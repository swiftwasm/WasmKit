import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct AddressLoadFusionTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func wrapsAddressBeforeAddingMemoryOffset(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module (memory 1)
                  (data (i32.const 4) "abcd")
                  (func (export "f") (param i32) (result i32 i32) (local i32)
                    local.get 0 i32.const 16 i32.add local.tee 1
                    i32.load offset=4 local.get 1)
                  (func (export "join") (param i32 i32) (result i32)
                    block (result i32)
                      local.get 0 local.get 1 br_if 0 drop
                      local.get 0 i32.const 16 i32.add
                    end
                    i32.load offset=4))
                """))
        let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
        let instance = try module.instantiate(store: store)
        let f = try #require(instance.exports[function: "f"])
        let join = try #require(instance.exports[function: "join"])
        #expect(try f([.i32(0xffff_fff0)]) == [.i32(0x6463_6261), .i32(0)])
        #expect(try f([.i32(65512)]) == [.i32(0), .i32(65528)])
        #expect(try join([.i32(0), .i32(1)]) == [.i32(0x6463_6261)])
        #expect(try join([.i32(0xffff_fff0), .i32(0)]) == [.i32(0x6463_6261)])
        for x: UInt32 in [65513, 65516, 0xffff_ffef] {
            #expect(throws: (any Error).self) { try f([.i32(x)]) }
        }
        #if Disassembler
            let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let dumpInstance = try module.instantiate(store: dumpStore)
            var listing = ""
            try dumpInstance.dumpFunctions(to: &listing, module: module)
            if threadingModel == .direct { #expect(listing.contains("i32AddImmLoad")) }
        #endif
    }
}
