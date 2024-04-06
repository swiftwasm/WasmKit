public enum Trap: Error {
    // FIXME: for debugging purposes, to be eventually deleted
    case _raw(String)

    case unreachable

    // Stack
    case stackOverflow
    case stackValueTypesMismatch(expected: ValueType, actual: ValueType)
    case stackElementNotFound(Any.Type, index: Int)
    case localIndexOutOfRange(index: UInt32)
    case callStackExhausted

    // Store
    case globalAddressOutOfRange(index: GlobalAddress)
    case globalImmutable(index: GlobalAddress)
    case outOfBoundsTableAccess(index: ElementIndex)
    case readingDroppedReference(index: ElementIndex)

    // Invocation
    case exportedFunctionNotFound(ModuleInstance, name: String)
    case tableUninitialized(ElementIndex)
    case undefinedElement
    case tableSizeOverflow
    case callIndirectFunctionTypeMismatch(actual: FunctionType, expected: FunctionType)
    case outOfBoundsMemoryAccess
    case invalidFunctionIndex(FunctionIndex)
    case poppedLabelMismatch
    case labelMismatch
    case integerDividedByZero
    case integerOverflowed
    case invalidConversionToInteger
    case tooManyBlockParameters([ValueType])

    /// Human-readable text representation of the trap that `.wast` text format expects in assertions
    public var assertionText: String {
        switch self {
        case .outOfBoundsMemoryAccess:
            return "out of bounds memory access"
        case .integerDividedByZero:
            return "integer divide by zero"
        case .integerOverflowed:
            return "integer overflow"
        case .invalidConversionToInteger:
            return "invalid conversion to integer"
        case .undefinedElement:
            return "undefined element"
        case let .tableUninitialized(elementIndex):
            return "uninitialized element \(elementIndex)"
        case .callIndirectFunctionTypeMismatch:
            return "indirect call type mismatch"
        case .outOfBoundsTableAccess, .tableSizeOverflow:
            return "out of bounds table access"
        case .callStackExhausted:
            return "call stack exhausted"
        default:
            return String(describing: self)
        }
    }
}

public enum InstantiationError: Error {
    case importsAndExternalValuesMismatch
    case invalidTableExpression
    case outOfBoundsTableAccess
    case outOfBoundsMemoryAccess

    /// Human-readable text representation of the trap that `.wast` text format expects in assertions
    public var assertionText: String {
        switch self {
        case .outOfBoundsTableAccess:
            return "out of bounds table access"
        case .outOfBoundsMemoryAccess:
            return "out of bounds memory access"
        default:
            return String(describing: self)
        }
    }
}

public enum ImportError: Error {
    case unknownImport(moduleName: String, externalName: String)
    case incompatibleImportType
    case moduleInstanceAlreadyRegistered(String)

    /// Human-readable text representation of the trap that `.wast` text format expects in assertions
    public var assertionText: String {
        switch self {
        case .unknownImport:
            return "unknown import"
        case .incompatibleImportType:
            return "incompatible import type"
        case let .moduleInstanceAlreadyRegistered(name):
            return "a module instance is already registered under a name `\(name)"
        }
    }
}
