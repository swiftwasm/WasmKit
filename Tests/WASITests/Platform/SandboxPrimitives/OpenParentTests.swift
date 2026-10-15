import Testing

@testable import WASI

@Suite
struct OpenParentTests {
    @Test
    func testSplitParent() {
        func check(
            _ lhs: (GuestPath, GuestPath.Component)?,
            _ rhs: (GuestPath, GuestPath.Component)?,
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

        check(splitParent(path: "/"), (GuestPath("/"), .currentDirectory))
        check(splitParent(path: "/."), (GuestPath("/."), .currentDirectory))
        check(splitParent(path: "/a"), (GuestPath("/"), .regular("a")))
        check(splitParent(path: "/a/"), (GuestPath("/a"), .currentDirectory))
        check(splitParent(path: "/a/."), (GuestPath("/a/."), .currentDirectory))
        check(splitParent(path: "/a/.."), (GuestPath("/a/.."), .currentDirectory))

        check(splitParent(path: "b"), (GuestPath(""), .regular("b")))
        check(splitParent(path: "b/."), (GuestPath("b/."), .currentDirectory))
        check(splitParent(path: "b/.."), (GuestPath("b/.."), .currentDirectory))

        check(splitParent(path: "../c"), (GuestPath(".."), .regular("c")))
    }
}
