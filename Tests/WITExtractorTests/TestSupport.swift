#if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
    import Testing

    @testable import WIT
    @testable import WITExtractor

    struct TestSupport {
        static func assertTranslation(
            _ swiftSource: String,
            _ expectedWIT: String,
            _ namespace: String = "swift",
            _ packageName: String = "wasmkit",
            _ moduleName: String = "test",
            sourceLocation: SourceLocation = #_sourceLocation
        ) throws {
            let extractor = WITExtractor(namespace: namespace, packageName: packageName, sources: [swiftSource])
            let output = extractor.runWithoutHeader(moduleName: moduleName)
            #expect(output.witContents == expectedWIT, sourceLocation: sourceLocation)
            var lexer = Lexer(cursor: Lexer.Cursor(input: output.witContents))
            _ = try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
        }
    }
#endif
