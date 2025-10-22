import SystemPackage
import Testing

@testable import WASI

@Suite
struct OpenParentTests {
    @Test
    func testSplitParent() {
        func check(
            _ lhs: (FilePath, FilePath.Component)?,
            _ rhs: (FilePath, FilePath.Component)?,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            switch (lhs, rhs) {
            case (.none, .none): return
            case (.some(let lhs), .some(let rhs)):
                #expect(lhs.0 == rhs.0, sourceLocation: sourceLocation)
                #expect(lhs.1 == rhs.1, sourceLocation: sourceLocation)
            default:
                #expect((false), "\(String(describing: lhs)) and \(String(describing: rhs)) are not equal", sourceLocation: sourceLocation)
            }
        }

        check(splitParent(path: ""), nil)

        check(splitParent(path: "/"), (FilePath("/"), FilePath.Component(".")))
        check(splitParent(path: "/."), (FilePath("/."), FilePath.Component(".")))
        check(splitParent(path: "/a"), (FilePath("/"), FilePath.Component("a")))
        check(splitParent(path: "/a/"), (FilePath("/a"), FilePath.Component(".")))
        check(splitParent(path: "/a/."), (FilePath("/a/."), FilePath.Component(".")))
        check(splitParent(path: "/a/.."), (FilePath("/a/.."), FilePath.Component(".")))

        check(splitParent(path: "b"), (FilePath(""), FilePath.Component("b")))
        check(splitParent(path: "b/."), (FilePath("b/."), FilePath.Component(".")))
        check(splitParent(path: "b/.."), (FilePath("b/.."), FilePath.Component(".")))

        check(splitParent(path: "../c"), (FilePath(".."), FilePath.Component("c")))
    }
}
