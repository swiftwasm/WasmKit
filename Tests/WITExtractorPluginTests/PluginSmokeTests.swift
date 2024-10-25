import XCTest

class PluginSmokeTests: XCTestCase {
    func testExtractPlugin() throws {
        #if compiler(>=6.0)
            throw XCTSkip("XFAIL: Swift compiler path inference is broken in Swift 6.0")
        #endif
        guard ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] == nil else {
            throw XCTSkip(
                "\"swift package resolve\" somehow fails to clone git repository only when invoking from Xcode test runner"
            )
        }
        let stdout = try assertSwiftPackage(
            fixturePackage: "PluginSmokePackage",
            ["extract-wit", "--target", "PluginSmokeModule"]
        )
        XCTAssertEqual(
            stdout,
            """
            // DO NOT EDIT.
            //
            // Generated by the WITExtractor
            package swift:plugin-smoke-package

            interface plugin-smoke-module {
                record struct-A {
                    member-B: s64,
                }

                record struct-A-nested-struct-C {
                    member-D: s64,
                }
            }
            """)
    }
}
