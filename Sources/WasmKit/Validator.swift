import WasmParser

struct ValidationError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

struct InstructionValidator {
    func validateMemArg(_ memarg: MemArg, naturalAlignment: Int) throws {
        if memarg.align > naturalAlignment {
            throw ValidationError("Alignment 2**\(memarg.align) is out of limit \(naturalAlignment)")
        }
    }
}
