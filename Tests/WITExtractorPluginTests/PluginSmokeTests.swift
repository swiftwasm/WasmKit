import XCTest

class PluginSmokeTests: XCTestCase {
    func testExtractPlugin() throws {
        guard ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] == nil else {
            throw XCTSkip(
                "\"swift package resolve\" somehow fails to clone git repository only when invoking from Xcode test runner"
            )
        }
        let stdout = try assertSwiftPackage(
            fixturePackage: "PluginSmokePackage",
            ["extract-wit", "--target", "PluginSmokeModule"]
        )
        XCTAssertEqual(stdout, """
        package swift:plugin-smoke-package

        interface plugin-smoke-module {
            record struct-a {
                member-b: s64,
            }
            record struct-a-nested-struct-c {
                member-d: s64,
            }
        }

        """)
    }
}
