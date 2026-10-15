/// The ids the printer writes for one index space, made from the name section's names.
///
/// Duplicate names are found with `String`'s `==`, which is how the WAT parser compares ids.
struct IdentifierTable {
    private var ids: [UInt32: String] = [:]
    private var namesWithoutIds: [UInt32: String] = [:]

    init(names: [UInt32: String]) {
        var used: Set<String> = []
        for (index, name) in names.sorted(by: { $0.key < $1.key }) {
            if let id = Self.id(for: name), used.insert(name).inserted {
                ids[index] = id
            } else {
                namesWithoutIds[index] = name
            }
        }
    }

    /// The id for `name`, quoted unless it is all idchars, or `nil` for the empty name.
    static func id(for name: String) -> String? {
        guard !name.isEmpty else { return nil }
        if name.unicodeScalars.allSatisfy(Lexer.isIdChar) {
            return "$" + name
        }
        return "$" + watStringLiteral(name.utf8, keepingUTF8: true)
    }

    subscript(index: UInt32) -> String? {
        ids[index]
    }

    /// ` $id` for the definition of entity `index`, or nothing.
    func definition(_ index: UInt32) -> String {
        ids[index].map { " " + $0 } ?? ""
    }

    /// The operand that refers to entity `index`: its id, or else its index.
    func reference(_ index: UInt32) -> String {
        ids[index] ?? String(index)
    }

    /// ` (@name "...")` for entity `index` when it has a name but no id, or nothing.
    func nameAnnotation(_ index: UInt32) -> String {
        namesWithoutIds[index].map { " (@name \(watStringLiteral($0.utf8, keepingUTF8: true)))" } ?? ""
    }
}
