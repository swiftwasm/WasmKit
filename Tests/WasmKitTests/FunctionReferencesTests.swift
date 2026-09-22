import Testing
import WAT
import WasmKit

/// The typed function references proposal is not implemented yet, so its
/// instructions must be rejected instead of being skipped by the translator.
@Suite
struct FunctionReferencesTests {
    @Test(arguments: [
        ("call_ref", "(call_ref $t (local.get 0))"),
        ("return_call_ref", "(return_call_ref $t (local.get 0))"),
        ("ref.as_non_null", "(drop (ref.as_non_null (local.get 0)))"),
        ("br_on_null", "(block (drop (br_on_null 0 (local.get 0))))"),
        ("br_on_non_null", "(drop (block (result (ref null $t)) (br_on_non_null 0 (local.get 0)) (local.get 0)))"),
    ])
    func rejectsUnsupportedInstruction(name: String, body: String) throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (type $t (func))
                    (func (param (ref null $t)) \(body))
                )
                """
            )
        )
        let store = Store(engine: Engine(configuration: EngineConfiguration(compilationMode: .eager)))
        let error = #expect(throws: (any Error).self) {
            try module.instantiate(store: store)
        }
        #expect(error.map { "\($0)" }?.contains("\(name) is not implemented yet") == true)
    }
}
