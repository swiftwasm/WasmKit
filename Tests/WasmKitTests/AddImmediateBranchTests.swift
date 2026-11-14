import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct AddImmediateBranchTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func wrappingBranchAndRetainedLocal(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func (export "forward") (param i32) (result i32) (local i32)
                    block
                      local.get 0 i32.const -1 i32.add local.tee 1 br_if 0
                      i32.const 7 local.set 1
                    end local.get 1)
                  (func (export "loop") (param i32) (result i32)
                    loop
                      local.get 0 i32.const -1 i32.add local.tee 0 br_if 0
                    end local.get 0)
                  (func (export "skipped") (param i32 i32) (result i32) (local i32)
                    block
                      local.get 1 br_if 0
                      local.get 0 i32.const -1 i32.add local.tee 2 br_if 0
                      i32.const 7 local.set 2
                    end local.get 2)
                  (func (export "copy") (param i32) (result i32)
                    block (result i32)
                      i32.const 42 local.get 0 i32.const -1 i32.add br_if 0
                      drop i32.const 7
                    end))
                """))
        for mode in [EngineConfiguration.CompilationMode.lazy, .eager] {
            let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: mode)))
            let instance = try module.instantiate(store: store)
            for input: UInt32 in [0, 1, 2, 0x8000_0000, .max] {
                let value = input &- 1
                let expected: UInt32 = value != 0 ? value : 7
                #expect(try instance.exports[function: "forward"]!([.i32(input)]) == [.i32(expected)])
                #expect(try instance.exports[function: "skipped"]!([.i32(input), .i32(0)]) == [.i32(expected)])
                #expect(try instance.exports[function: "skipped"]!([.i32(input), .i32(1)]) == [.i32(0)])
                #expect(try instance.exports[function: "copy"]!([.i32(input)]) == [.i32(value != 0 ? 42 : 7)])
            }
            for input: UInt32 in [1, 2, 8, 100] {
                #expect(try instance.exports[function: "loop"]!([.i32(input)]) == [.i32(0)])
            }
        }
        #if Disassembler
            if threadingModel == .direct {
                let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
                let instance = try module.instantiate(store: store)
                var listing = ""
                try instance.dumpFunctions(to: &listing, module: module)
                #expect(listing.contains("i32AddImmBrIf"))
            }
        #endif
    }
}
