import WasmKit

package struct LLStore: ~Copyable {
    package init() {}
}

extension Module {
    package func instantiate(llStore: borrowing LLStore, imports: Imports = Imports()) throws -> LLInstance {
        LLInstance()
    }
}
