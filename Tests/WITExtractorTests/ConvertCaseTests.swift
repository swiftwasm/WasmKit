import Testing

@testable import WITExtractor

@Suite

struct ConvertCaseTests {
    @Test func pascalToKebab() {
        #expect(ConvertCase.kebabCase(identifier: "PascalCase") == "pascal-case")
        #expect(ConvertCase.kebabCase(identifier: "camelCase") == "camel-case")
        #expect(ConvertCase.kebabCase(identifier: "libXML2") == "lib-XML2")
        // underscore is not allowed in WIT kebab-case
        #expect(ConvertCase.kebabCase(identifier: "iso9899_1990") == "iso98991990")
        #expect(ConvertCase.kebabCase(identifier: "v4_2") == "v42")
        #expect(ConvertCase.kebabCase(identifier: "CXXConfig") == "C-X-X-config")
    }
}
