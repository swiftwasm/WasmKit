import WIT

enum StaticMetaOperand: CustomStringConvertible {
    /// A case that represents a core value stored in the given variable name
    case variable(String)
    case literal(String)
    case call(_ name: String, arguments: [(String?, StaticMetaOperand)])
    indirect case forceUnwrap(StaticMetaOperand)
    indirect case liftOptional(isSome: StaticMetaOperand, payload: StaticMetaOperand)
    indirect case lowerBool(StaticMetaOperand)
    indirect case accessField(StaticMetaOperand, name: String)

    static func call(_ name: String, arguments: [StaticMetaOperand]) -> StaticMetaOperand {
        return .call(name, arguments: arguments.map { (nil, $0) })
    }

    var description: String {
        switch self {
        case .variable(let label): return label
        case .literal(let content): return content
        case .call(let typeName, let arguments):
            let arguments = arguments.map { label, operand in
                if let label { return "\(label): \(operand)" }
                return operand.description
            }
            return "\(typeName)(\(arguments.joined(separator: ", ")))"
        case .forceUnwrap(let operand):
            return "(\(operand))!"
        case .liftOptional(let isSome, let payload):
            return "\(isSome) == 0 ? nil : \(payload)"
        case .lowerBool(let value):
            return "Int32(\(value) ? 1 : 0)"
        case .accessField(let base, let name):
            return "\(base).\(name)"
        }
    }
}

struct StaticMetaPointer: Strideable, CustomStringConvertible {
    typealias Stride = Int
    let basePointerVar: String
    let offset: Int

    init(basePointerVar: String, offset: Int) {
        self.basePointerVar = basePointerVar
        self.offset = offset
    }

    func advanced(by n: Stride) -> StaticMetaPointer {
        return StaticMetaPointer(basePointerVar: basePointerVar, offset: offset + n)
    }

    func distance(to other: StaticMetaPointer) -> Int {
        assert(basePointerVar == other.basePointerVar)
        return offset - other.offset
    }

    var description: String {
        "\(basePointerVar).advanced(by: \(offset))"
    }
}

/// Meta view of ``WasmKit/CanonicalCallContext``
struct StaticMetaCanonicalCallContext {
    /// The variable name of the ``WasmKit/CanonicalCallContext``
    let contextVar: String
}
