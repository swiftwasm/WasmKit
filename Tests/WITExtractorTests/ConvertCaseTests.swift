import XCTest

@testable import WITExtractor

class ConvertCaseTests: XCTestCase {
    func testPascalToKebab() {
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "PascalCase"), "pascal-case")
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "camelCase"), "camel-case")
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "libXML2"), "lib-XML2")
        // underscore is not allowed in WIT kebab-case
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "iso9899_1990"), "iso98991990")
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "v4_2"), "v42")
        XCTAssertEqual(ConvertCase.kebabCase(identifier: "CXXConfig"), "C-X-X-config")
    }
}
