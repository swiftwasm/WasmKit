final class SourcePrinter {
    private(set) var contents: String = ""
    private var indentLevel: Int = 0

    init(header: String = "") {
        self.contents = header
    }

    func emptyLine() {
        contents += "\n"
    }

    func write<S: StringProtocol>(line: S) {
        contents += "\n" + String(repeating: " ", count: indentLevel * 4)
        contents += line
    }

    func write(multiline: String) {
        for line in multiline.split(separator: "\n") {
            write(line: line)
        }
    }

    func indent() {
        indentLevel += 1
    }

    func unindent() {
        indentLevel -= 1
    }

    func indent(_ body: () throws -> Void) rethrows {
        indentLevel += 1
        try body()
        indentLevel -= 1
    }
}
