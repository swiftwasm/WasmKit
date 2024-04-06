/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-code>
struct Code {
    let locals: [ValueType]
    let expression: ArraySlice<UInt8>
}

extension Code: Equatable {
    static func == (lhs: Code, rhs: Code) -> Bool {
        return lhs.locals == rhs.locals && lhs.expression == rhs.expression
    }
}
