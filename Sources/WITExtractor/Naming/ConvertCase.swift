enum ConvertCase {

    static func witIdentifier(identifier: [String]) -> String {
        return witIdentifier(kebabCase(identifier: identifier))
    }

    static func witIdentifier(identifier: String) -> String {
        return witIdentifier(kebabCase(identifier: identifier))
    }

    static func witIdentifier(_ id: String) -> String {
        // https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md#keywords
        let keywords: Set<String> = [
            "use",
            "type",
            "resource",
            "func",
            "record",
            "enum",
            "flags",
            "variant",
            "static",
            "interface",
            "world",
            "import",
            "export",
            "package",
            "include",
        ]

        if keywords.contains(id) {
            return "%\(id)"
        }
        return id
    }

    static func kebabCase(identifier: [String]) -> String {
        identifier.map { kebabCase(identifier: $0) }.joined(separator: "-")
    }

    /// Convert any Swift-like identifier to WIT identifier
    ///
    /// The WIT identifier is defined as follows:
    ///
    /// ```
    /// label          ::= <word>
    ///                  | <label>-<word>
    /// word           ::= [a-z][0-9a-z]*
    ///                  | [A-Z][0-9A-Z]*
    /// ```
    /// > See <https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#instance-definitions>
    ///
    /// Note that different inputs can produce the same output.
    static func kebabCase(identifier: String) -> String {
        struct Word {
            var text: String
            let isUpperCases: Bool
        }
        var words: [Word] = []
        var cursor = identifier.startIndex

        let lowerCases: ClosedRange<Character> = "a"..."z"
        let upperCases: ClosedRange<Character> = "A"..."Z"
        let digits: ClosedRange<Character> = "0"..."9"

        var nextChar: Character? {
            let nextCursor = identifier.index(after: cursor)
            guard identifier.index(after: cursor) < identifier.endIndex else {
                return nil
            }
            return identifier[nextCursor]
        }
        var char: Character { identifier[cursor] }

        // 1. Split into words by following the definition
        while cursor < identifier.endIndex {
            // Start of a "word"

            var isUpperCases: Bool
            var building = ""

            // Consume [A-Z]
            // Note that it doesn't consume [A-Z][0-9A-Z]* here to allow later heuristic word merging.
            if upperCases.contains(char) {
                isUpperCases = true
                building.append(char)
                cursor = identifier.index(after: cursor)
            } else if lowerCases.contains(char) {
                isUpperCases = false
                // Consume [a-z][0-9a-z]*
                while cursor < identifier.endIndex, lowerCases.contains(char) || digits.contains(char) {
                    building.append(char)
                    cursor = identifier.index(after: cursor)
                }
            } else {
                // Otherwise, the char appears invalid position or the char itself is invalid.
                // If the char itself is valid, append it at the tail of the last word
                if digits.contains(char), let lastWord = words.popLast() {
                    building = lastWord.text + String(char)
                    isUpperCases = lastWord.isUpperCases
                } else {
                    // Just ignore the char if it's invalid char
                    cursor = identifier.index(after: cursor)
                    continue
                }
                cursor = identifier.index(after: cursor)
            }
            if !building.isEmpty {
                words.append(Word(text: building, isUpperCases: isUpperCases))
                building = ""
            }
        }

        // 2. Merge words by some heuristics
        var mergedWords: [Word] = []

        // Merge Pascal case words into all lower-cased word
        do {
            var wordIndex = 0
            while wordIndex < words.count - 1 {
                let word = words[wordIndex]
                let nextWord = words[wordIndex + 1]

                // Merge ["P", "ascal", "C", "ase"] -> ["pascal", "case"]
                if word.text.count == 1, word.isUpperCases, !nextWord.isUpperCases {
                    mergedWords.append(Word(text: word.text.lowercased() + nextWord.text, isUpperCases: false))
                    wordIndex += 1
                } else {
                    mergedWords.append(word)
                }
                wordIndex += 1
            }
            // Append the trailing word if it's not merged
            if wordIndex == words.count - 1 {
                mergedWords.append(words[wordIndex])
            }
        }

        // Merge trailing upper cases like ["mac", "O", "S"] -> ["mac", "OS"]
        // but it doesn't merge non-trailing upper words like ["C", "Language"]
        do {
            while mergedWords.count >= 2,
                let lastWord = mergedWords.popLast(),
                let nextLastWord = mergedWords.popLast()
            {
                if lastWord.isUpperCases, nextLastWord.isUpperCases {
                    mergedWords.append(Word(text: nextLastWord.text + lastWord.text, isUpperCases: true))
                } else {
                    mergedWords.append(nextLastWord)
                    mergedWords.append(lastWord)
                    break
                }
            }
        }
        return mergedWords.map(\.text).joined(separator: "-")
    }
}
