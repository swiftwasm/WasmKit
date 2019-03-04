public enum Trap: Error {
    // FIXME: for debugging purposes, to be eventually deleted
    case _raw(String)
    case _unimplemented(_ file: StaticString, _ line: UInt)

    case unreachable

    // Stack
    case stackTypeMismatch(expected: Any.Type, actual: Any.Type)
    case stackValueTypesMismatch(expected: ValueType, actual: [Any.Type])
    case stackNoCurrent(Any.Type)
    case localIndexOutOfRange(index: UInt32)

    // Store
    case globalIndexOutOfRange(index: UInt32)
    case globalImmutable(index: UInt32)

    static func unimplemented(file: StaticString = #file, line: UInt = #line) -> Trap {
        return ._unimplemented(file, line)
    }
}
