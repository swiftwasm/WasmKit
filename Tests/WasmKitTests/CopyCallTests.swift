import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct CopyCallTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func copiesBeforeFirstAndRepeatedCalls(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func $identity (param i64) (result i64) local.get 0)
                  (func $subtract (param i64 i64) (result i64)
                    local.get 0 local.get 1 i64.sub)
                  (func $large (param i64) (result i64)
                    (local i64 i64 i64 i64 i64 i64 i64 i64 i64 i64
                           i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)
                    local.get 0 local.get 20 i64.add)
                  (func (export "single") (param i64) (result i64)
                    local.get 0 call $identity)
                  (func (export "swap") (param i64 i64) (result i64)
                    local.get 1 local.get 0 call $subtract)
                  (func (export "large") (param i64) (result i64)
                    local.get 0 call $large)
                  (func (export "branch") (param i64 i32) (result i64)
                    local.get 0
                    block (param i64) (result i64)
                      local.get 1 br_if 0
                      drop i64.const 7
                    end
                    call $identity))
                """))
        let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
        let instance = try module.instantiate(store: store)
        let single = try #require(instance.exports[function: "single"])
        let swap = try #require(instance.exports[function: "swap"])
        let large = try #require(instance.exports[function: "large"])
        let branch = try #require(instance.exports[function: "branch"])
        for x: UInt64 in [0, 1, 17, .max] {
            #expect(try single([.i64(x)]) == [.i64(x)])
            #expect(try swap([.i64(x), .i64(17)]) == [.i64(17 &- x)])
            #expect(try large([.i64(x)]) == [.i64(x)])
            #expect(try branch([.i64(x), .i32(0)]) == [.i64(7)])
            #expect(try branch([.i64(x), .i32(1)]) == [.i64(x)])
        }
        #if Disassembler
            let dumpStore = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
            let dumpInstance = try module.instantiate(store: dumpStore)
            var listing = ""
            try dumpInstance.dumpFunctions(to: &listing, module: module)
            #expect(listing.contains("compilingCopyCall"))
            if threadingModel == .direct { #expect(listing.contains("compilingCopy2Call")) }
        #endif
    }
}
