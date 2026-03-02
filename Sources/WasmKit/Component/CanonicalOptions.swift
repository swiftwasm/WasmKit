/// A type representing a `canonopt` values supplied to currently-executing
/// `canon lift` or `canon lower`.
/// > Note:
/// <https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md#runtime-state>
public struct CanonicalOptions {
    /// A type of string encoding used in the Component Model.
    public enum StringEncoding {
        /// UTF-8
        case utf8
        /// UTF-16
        case utf16
        /// Dynamic encoding of Latin-1 or UTF-16
        case latin1OrUTF16
    }

    /// The memory address used for lifting or lowering operations.
    public let memory: Memory
    /// The string encoding used for lifting or lowering string values.
    public let stringEncoding: StringEncoding
    /// The realloc function address used for lifting or lowering values.
    public let realloc: Function?
    /// The function address called when a lifted/lowered function returns.
    public let postReturn: Function?

    public init(
        memory: Memory, stringEncoding: StringEncoding,
        realloc: Function?, postReturn: Function?
    ) {
        self.memory = memory
        self.stringEncoding = stringEncoding
        self.realloc = realloc
        self.postReturn = postReturn
    }

    /// FIXME: This deriviation is wrong because the options should be determined by `(canon lift)` or `(canon lower)`
    /// in an encoded component at componetizing-time. (e.g. wit-component tool is one of the componetizers)
    /// Remove this temporary method after we will accept binary form of component file.
    public static func _derive(from instance: Instance, exportName: String) -> CanonicalOptions {
        guard case .memory(let memory) = instance.exports["memory"] else {
            fatalError("Missing required \"memory\" export")
        }
        return CanonicalOptions(
            memory: memory, stringEncoding: .utf8,
            realloc: instance.exportedFunction(name: "cabi_realloc"),
            postReturn: instance.exportedFunction(name: "cabi_post_\(exportName)"))
    }
}
