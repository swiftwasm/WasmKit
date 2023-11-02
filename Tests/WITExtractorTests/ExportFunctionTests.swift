import XCTest

class ExportFunctionTests: XCTestCase {
    func testNoParameter() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public func noParameter() {}
            """,
            """
            package swift:wasmkit

            interface test {
                no-parameter: func()
            }
            """)
    }

    func testParameters() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public func withParameters(x: String, y: Int) {}
            """,
            """
            package swift:wasmkit

            interface test {
                with-parameters: func(a: string, b: s64)
            }
            """)
    }

    func testResult() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public func withResult() -> Int { return 0 }
            """,
            """
            package swift:wasmkit

            interface test {
                with-result: func() -> s64
            }
            """)
    }

    func testMultipleResult() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public func withMultipleResult() -> (x: Int, y: Int) {
                return (0, 1)
            }
            """,
            """
            package swift:wasmkit

            interface test {
                with-multiple-result: func() -> (a: s64, b: s64)
            }
            """)
    }
}
