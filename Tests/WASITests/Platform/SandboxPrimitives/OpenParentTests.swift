import SystemPackage
import XCTest

@testable import WASIBase

final class OpenParentTests: XCTestCase {
    func testSplitParent() {
        func XCTCheck(
            _ lhs: (FilePath, FilePath.Component)?,
            _ rhs: (FilePath, FilePath.Component)?,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            switch (lhs, rhs) {
            case (.none, .none): return
            case let (.some(lhs), .some(rhs)):
                XCTAssertEqual(lhs.0, rhs.0, file: file, line: line)
                XCTAssertEqual(lhs.1, rhs.1, file: file, line: line)
            default:
                XCTFail("\(String(describing: lhs)) and \(String(describing: rhs)) are not equal", file: file, line: line)
            }
        }

        XCTCheck(splitParent(path: ""), nil)

        XCTCheck(splitParent(path: "/"), (FilePath("/"), FilePath.Component(".")))
        XCTCheck(splitParent(path: "/."), (FilePath("/."), FilePath.Component(".")))
        XCTCheck(splitParent(path: "/a"), (FilePath("/"), FilePath.Component("a")))
        XCTCheck(splitParent(path: "/a/"), (FilePath("/a"), FilePath.Component(".")))
        XCTCheck(splitParent(path: "/a/."), (FilePath("/a/."), FilePath.Component(".")))
        XCTCheck(splitParent(path: "/a/.."), (FilePath("/a/.."), FilePath.Component(".")))

        XCTCheck(splitParent(path: "b"), (FilePath(""), FilePath.Component("b")))
        XCTCheck(splitParent(path: "b/."), (FilePath("b/."), FilePath.Component(".")))
        XCTCheck(splitParent(path: "b/.."), (FilePath("b/.."), FilePath.Component(".")))

        XCTCheck(splitParent(path: "../c"), (FilePath(".."), FilePath.Component("c")))
    }
}
