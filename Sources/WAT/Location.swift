/// A location in a WAT source file.
public struct Location: Equatable, CustomDebugStringConvertible {
    let index: Lexer.Index
    let source: String.UnicodeScalarView

    init(at index: Lexer.Index, in source: String.UnicodeScalarView) {
        self.index = index
        self.source = source
    }

    public static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.index == rhs.index
    }

    public var debugDescription: String {
        return "Location\(sourceLocation(at: index, in: source))"
    }

    /// Computes the line and column of the location in the source file.
    /// - Returns: The line and column of the location. Line is 1-indexed and column is 0-indexed.
    public func computeLineAndColumn() -> (line: Int, column: Int) {
        return sourceLocation(at: index, in: source)
    }
}


/// Returns the location of the given index in the source
/// - Parameters:
///   - index: The index in the source
///   - source: The source string
/// - Returns: The location of the index in line-column style. Line is 1-indexed and column is 0-indexed.
func sourceLocation(at index: Lexer.Index, in source: String.UnicodeScalarView) -> (line: Int, column: Int) {
    let slice = source[..<index]
    let lineNo = slice.split(separator: "\n", omittingEmptySubsequences: false).count
    let columnNo: Int
    if let lastNewlineIndex = slice.lastIndex(of: "\n") {
        columnNo = slice.distance(from: lastNewlineIndex, to: index)
    } else {
        // The current position is the first line of the input
        columnNo = slice.distance(from: slice.startIndex, to: index)
    }
    return (line: lineNo, column: columnNo)
}
