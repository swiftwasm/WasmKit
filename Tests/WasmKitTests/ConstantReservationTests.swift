import Testing
import WAT

@_spi(OnlyForCLI) @testable import WasmKit

@Suite struct ConstantReservationTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func preservesLiveAndAllocatedConstants(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let additions = (1...40).map { "local.get 0 i64.const \($0) i64.add local.set 0" }.joined(separator: "\n")
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func $identity (param i64) (result i64) local.get 0)
                  (func (export "add") (param i64) (result i64)
                    \(additions) local.get 0)
                  (func (export "live") (param i64) (result i64 i64 i64)
                    i64.const 1234567890123
                    i64.const 9876543210123 call $identity
                    \(additions)
                    local.get 0)
                  (func (export "deep") (param i64) (result i64)
                    \(String(repeating: "i64.const 0 ", count: 130))
                    \(additions)
                    \(String(repeating: "drop ", count: 130))
                    local.get 0)
                  (func (export "branch") (param i64 i32) (result i64 i64)
                    i64.const 1234567890123
                    local.get 1 if
                      \(additions)
                    else
                      i64.const 3 local.set 0
                    end
                    local.get 0))
                """))
        for mode in [EngineConfiguration.CompilationMode.lazy, .eager] {
            let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: mode)))
            let instance = try module.instantiate(store: store)
            let add = try #require(instance.exports[function: "add"])
            let live = try #require(instance.exports[function: "live"])
            let deep = try #require(instance.exports[function: "deep"])
            let branch = try #require(instance.exports[function: "branch"])
            for x: UInt64 in [0, 17, .max] {
                #expect(try add([.i64(x)]) == [.i64(x &+ 820)])
                #expect(try deep([.i64(x)]) == [.i64(x &+ 820)])
                #expect(try live([.i64(x)]) == [.i64(1_234_567_890_123), .i64(9_876_543_210_123), .i64(x &+ 820)])
                #expect(try branch([.i64(x), .i32(1)]) == [.i64(1_234_567_890_123), .i64(x &+ 820)])
                #expect(try branch([.i64(x), .i32(0)]) == [.i64(1_234_567_890_123), .i64(3)])
            }
        }
        #if Disassembler
            if threadingModel == .direct {
                let immediateModule = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module (func (export "add") (param i64) (result i64)
                          \(additions) local.get 0))
                        """))
                let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel)))
                let instance = try immediateModule.instantiate(store: store)
                var listing = ""
                try instance.dumpFunctions(to: &listing, module: immediateModule)
                #expect(!listing.contains("const64"))
                #expect(listing.contains("i64.add"))
            }
        #endif
    }
}
