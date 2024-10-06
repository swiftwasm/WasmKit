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

struct InstructionValidator<Context: TranslatorContext> {
    let context: Context

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

    func validateTableInit(elemIndex: UInt32, table: UInt32) throws {
        let tableType = try context.tableType(table)
        let elementType = try context.elementType(elemIndex)
        guard tableType.elementType == elementType else {
            throw ValidationError("Table element type mismatch in table.init: \(tableType.elementType) != \(elementType)")
        }
    }

    func validateRefFunc(functionIndex: UInt32) throws {
        try context.validateFunctionIndex(functionIndex)
    }
}

struct ModuleValidator {
    let module: Module
    init(module: Module) {
        self.module = module
    }

    func validate() throws {
        if module.memoryTypes.count > 1 {
            throw ValidationError("Multiple memories are not permitted")
        }
        for memoryType in module.memoryTypes {
            try Self.checkMemoryType(memoryType, features: module.features)
        }
    }

    static func checkMemoryType(_ type: MemoryType, features: WasmFeatureSet) throws {
        try checkLimit(type)

        if type.isMemory64 {
            guard features.contains(.memory64) else {
                throw ValidationError("memory64 feature is required for 64-bit memories")
            }
        }

        let hardMax = MemoryEntity.maxPageCount(isMemory64: type.isMemory64)

        if type.min > hardMax {
            throw ValidationError("size minimum must not be greater than \(hardMax)")
        }

        if let max = type.max, max > hardMax {
            throw ValidationError("size maximum must not be greater than \(hardMax)")
        }

        if type.shared {
            guard features.contains(.threads) else {
                throw ValidationError("reference-types feature is required for shared memories")
            }
        }
    }

    private static func checkLimit(_ limit: Limits) throws {
        guard let max = limit.max else { return }
        if limit.min > max {
            throw ValidationError("size minimum must not be greater than maximum")
        }
    }
}
