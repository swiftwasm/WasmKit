import XCTest

@testable import WasmKit
import WAT

final class TranslatorTests: XCTestCase {
    func assertTranslate(_ wat: String, _ expected: [[Instruction]], line: UInt = #line) throws {
        let module = try parseWasm(bytes: wat2wasm(wat))
        let runtime = Runtime()
        let instance = try runtime.instantiate(module: module)
        let definedFunctions = instance.handle.functions[
            module.translatorContext.imports.numberOfFunctions..<instance.handle.functions.count
        ]
        for (function, expected) in zip(definedFunctions, expected) {
            try function.ensureCompiled(runtime: RuntimeRef(runtime))
            let (iseq, _, _) = function.assumeCompiled()
            if Array(iseq.instructions) == expected { continue }

            var out = "Actual:\n"
            let function = Function(handle: function, allocator: runtime.store.allocator)
            var context = InstructionPrintingContext(shouldColor: false, function: function, nameRegistry: NameRegistry())
            iseq.instructions.write(to: &out, context: &context)
            out += "\n\n"
            out += "Expected:\n"
            expected.write(to: &out, context: &context)
            XCTFail(out, line: line)
        }
    }

    func testParamReturn() throws {
        try assertTranslate("""
        (func (param i32) (result i32)
            local.get 0
        )
        """, [[
            .copyStack(Instruction.CopyStackOperand(source: -1, dest: 0)),
            .copyStack(Instruction.CopyStackOperand(source: 0, dest: -1)),
            .return,
            .return,
        ]])
    }
}
