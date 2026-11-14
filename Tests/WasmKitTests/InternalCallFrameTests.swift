import Testing
import WAT

@testable import WasmKit

@Suite struct InternalCallFrameTests {
    @Test(arguments: [EngineConfiguration.ThreadingModel.direct, .token])
    func frameSizesAndRepeatedCalls(threadingModel: EngineConfiguration.ThreadingModel) throws {
        for count in [0, 1, 2, 4, 8, 15, 16, 17, 32, 100] {
            let locals = count == 0 ? "" : "(local " + Array(repeating: "i64", count: count).joined(separator: " ") + ")"
            let check = count == 0 ? "i64.const 0" : "local.get \(count)"
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (func $callee (param i64) (result i64) \(locals)
                        local.get 0 \(check) i64.add)
                      (func (export "run") (param i64) (result i64)
                        local.get 0 call $callee call $callee))
                    """))
            for mode in [EngineConfiguration.CompilationMode.lazy, .eager] {
                let store = Store(engine: Engine(configuration: .init(threadingModel: threadingModel, compilationMode: mode)))
                let instance = try module.instantiate(store: store)
                let run = try #require(instance.exports[function: "run"])
                for value in UInt64(1)...10 { #expect(try run([.i64(value)]) == [.i64(value)]) }
            }
        }
    }
}
