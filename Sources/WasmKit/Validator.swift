import WasmParser

struct ValidationError: Error, CustomStringConvertible {
    let message: String
    var offset: Int?

    var description: String {
        if let offset = offset {
            return "\(message) at offset 0x\(String(offset, radix: 16))"
        } else {
            return message
        }
    }

    init(_ message: String) {
        self.message = message
    }
}

struct InstructionValidator {
    func validateMemArg(_ memarg: MemArg, naturalAlignment: Int) throws {
        if memarg.align > naturalAlignment {
            throw ValidationError("Alignment 2**\(memarg.align) is out of limit \(naturalAlignment)")
        }
    }

    func validateGlobalSet(_ type: GlobalType) throws {
        switch type.mutability {
        case .constant:
            throw ValidationError("Cannot set a constant global")
        case .variable:
            break
        }
    }
}

struct ModuleValidator {
    func validate(_ module: Module) throws {
        if module.memoryTypes.count > 1 {
            throw ValidationError("Multiple memories are not permitted")
        }
    }
}
