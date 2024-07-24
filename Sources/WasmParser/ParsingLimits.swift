/// Limits for parsing WebAssembly modules.
struct ParsingLimits {
    /// Maximum number of locals in a function.
    var maxFunctionLocals: UInt64

    /// The default limits for parsing.
    static var `default`: ParsingLimits {
        return ParsingLimits(maxFunctionLocals: 50000)
    }
}
