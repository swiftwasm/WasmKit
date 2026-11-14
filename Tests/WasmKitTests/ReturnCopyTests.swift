import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct ReturnCopyTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func preservesSwappedResultsAndBranches(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func $swap (param i64 i64) (result i64 i64)
                    local.get 1 local.get 0 return)
                  (func (export "f") (param i64 i64) (result i64 i64)
                    local.get 0 local.get 1 call $swap)
                  (func (export "branch") (param i32) (result i32)
                    block (result i32)
                      i32.const 7 local.get 0 br_if 0 drop
                      i32.const 8
                    end))
                """))
        let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
        let instance = try module.instantiate(store: store)
        let f = try #require(instance.exports[function: "f"])
        let branch = try #require(instance.exports[function: "branch"])
        for x: UInt64 in [0, 1, .max] {
            #expect(try f([.i64(x), .i64(17)]) == [.i64(17), .i64(x)])
        }
        #expect(try branch([.i32(0)]) == [.i32(8)])
        #expect(try branch([.i32(1)]) == [.i32(7)])
        #if Disassembler
            let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let dumpInstance = try module.instantiate(store: dumpStore)
            var listing = ""
            try dumpInstance.dumpFunctions(to: &listing, module: module)
            #expect(listing.contains("returnCopy"))
        #endif
    }
}
