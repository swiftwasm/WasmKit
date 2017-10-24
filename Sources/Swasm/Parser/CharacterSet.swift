internal struct CharacterSet {
    static func ~= (lhs: CharacterSet, rhs: UnicodeScalar) -> Bool {
        return lhs.contains(rhs)
    }

    let ranges: [ClosedRange<String>]
    let characters: Set<Character>

    init(ranges: [ClosedRange<String>] = [], characters: Set<Character> = Set()) {
        self.ranges = ranges
        self.characters = Set(characters)
    }

    func with(_ ranges: ClosedRange<String>...) -> CharacterSet {
        return CharacterSet(
            ranges: self.ranges + ranges,
            characters: self.characters
        )
    }

    func with(_ characters: Character...) -> CharacterSet {
        return CharacterSet(
            ranges: self.ranges,
            characters: self.characters.union(characters)
        )
    }

    func contains(_ character: UnicodeScalar) -> Bool {
        for range in ranges where range.contains(String(character)) {
            return true
        }

        return characters.contains(Character(character))
    }
}
