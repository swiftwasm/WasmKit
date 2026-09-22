import Testing
import WasmParser

@Suite struct InstructionDecodingTests {
    struct InstructionCollector: AnyInstructionVisitor {
        typealias VisitorError = Never
        var binaryOffset: Int = 0
        var instructions: [Instruction] = []

        mutating func visit(_ instruction: Instruction) {
            instructions.append(instruction)
        }
    }

    /// Decodes `body` as the expression of the only function in a module.
    func decodeFunctionBody(_ body: [UInt8]) throws -> [Instruction] {
        let code: [UInt8] = [0x00] + body  // no locals
        var module: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]
        module += [0x01, 0x04, 0x01, 0x60, 0x00, 0x00]  // type section: (func)
        module += [0x03, 0x02, 0x01, 0x00]  // function section: type 0
        module += [0x0A, UInt8(code.count + 2), 0x01, UInt8(code.count)] + code  // code section

        var parser = Parser(bytes: module)
        while let payload = try parser.parseNext() {
            guard case .codeSection(let codes) = payload else { continue }
            var expressionParser = ExpressionParser(code: try #require(codes.first))
            var collector = InstructionCollector()
            while let visit = try expressionParser.parse() {
                visit(visitor: &collector)
            }
            return collector.instructions
        }
        Issue.record("no code section")
        return []
    }

    @Test func functionReferencesImmediates() throws {
        // A skipped immediate would be decoded as the next instruction, and the
        // multi-byte LEB128 immediates check that the whole immediate is consumed.
        let instructions = try decodeFunctionBody([
            0x14, 0x00,  // call_ref 0
            0x15, 0x81, 0x01,  // return_call_ref 129
            0xD4,  // ref.as_non_null
            0xD5, 0xC8, 0x01,  // br_on_null 200
            0xD6, 0x02,  // br_on_non_null 2
            0x0B,  // end
        ])
        #expect(
            instructions == [
                .callRef(typeIndex: 0),
                .returnCallRef(typeIndex: 129),
                .refAsNonNull,
                .brOnNull(relativeDepth: 200),
                .brOnNonNull(relativeDepth: 2),
                .end,
            ])
    }
}
