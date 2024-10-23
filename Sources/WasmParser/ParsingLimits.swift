/// Limits for parsing WebAssembly modules.
@usableFromInline
struct ParsingLimits {
    /// Maximum number of locals in a function.
    @usableFromInline
    var maxFunctionLocals: UInt64

    /// The default limits for parsing.
    static var `default`: ParsingLimits {
        return ParsingLimits(maxFunctionLocals: 50000)
    }
}
