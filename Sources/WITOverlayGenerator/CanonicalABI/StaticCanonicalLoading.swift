import WIT

struct StaticCanonicalLoading: CanonicalLoading {
    typealias Operand = StaticMetaOperand
    typealias Pointer = StaticMetaPointer

    let printer: SourcePrinter
    let builder: SwiftFunctionBuilder

    private func loadByteSwappable(at pointer: Pointer, type: String) -> Operand {
        let boundPointer = "\(pointer).assumingMemoryBound(to: \(type).self)"
        let loadedVar = builder.variable("loaded")
        printer.write(line: "let \(loadedVar) = \(boundPointer).pointee")
        return .variable(loadedVar)
    }

    private func loadUInt(at pointer: Pointer, bitWidth: Int) -> Operand {
        return loadByteSwappable(at: pointer, type: "UInt\(bitWidth)")
    }
    private func loadInt(at pointer: Pointer, bitWidth: Int) -> Operand {
        let bitPattern = loadUInt(at: pointer, bitWidth: bitWidth)
        return .call("Int\(bitWidth)", arguments: [("bitPattern", bitPattern)])
    }
    private func loadFloat(at pointer: Pointer, bitWidth: Int) -> Operand {
        let bitPattern = loadUInt(at: pointer, bitWidth: bitWidth)
        return .call("Float\(bitWidth)", arguments: [("bitPattern", bitPattern)])
    }

    func loadUInt8(at pointer: Pointer) -> Operand {
        loadUInt(at: pointer, bitWidth: 8)
    }
    func loadUInt16(at pointer: Pointer) -> Operand {
        loadUInt(at: pointer, bitWidth: 16)
    }
    func loadUInt32(at pointer: Pointer) -> Operand {
        loadUInt(at: pointer, bitWidth: 32)
    }
    func loadUInt64(at pointer: Pointer) -> Operand {
        loadUInt(at: pointer, bitWidth: 64)
    }
    func loadInt8(at pointer: Pointer) -> Operand {
        loadInt(at: pointer, bitWidth: 8)
    }
    func loadInt16(at pointer: Pointer) -> Operand {
        loadInt(at: pointer, bitWidth: 16)
    }
    func loadInt32(at pointer: Pointer) -> Operand {
        loadInt(at: pointer, bitWidth: 32)
    }
    func loadInt64(at pointer: Pointer) -> Operand {
        loadInt(at: pointer, bitWidth: 64)
    }
    func loadFloat32(at pointer: Pointer) -> Operand {
        loadFloat(at: pointer, bitWidth: 32)
    }
    func loadFloat64(at pointer: Pointer) -> Operand {
        loadFloat(at: pointer, bitWidth: 64)
    }
}
