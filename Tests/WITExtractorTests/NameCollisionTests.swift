#if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
    import Testing

    @testable import WITExtractor

    // WIT shares one namespace between types and functions. At each WIT name the first declaration wins
    // (types before functions, source order within each); later ones are dropped with a diagnostic.
    struct NameCollisionTests {
        private func extract(_ source: String) -> (wit: String, extractor: WITExtractor) {
            let extractor = WITExtractor(namespace: "swift", packageName: "wasmkit", sources: [source])
            return (extractor.runWithoutHeader(moduleName: "test").witContents, extractor)
        }

        @Test func typeTypeCollisionDropsLaterWithDiagnostic() {
            // `FooBar` and `foo_bar` both kebab to `foo-bar`.
            let (wit, extractor) = extract(
                """
                @WIT public struct FooBar { public var x: Int }
                @WIT public enum foo_bar { case a, b }
                """)
            #expect(wit.ranges(of: "foo-bar").count == 1)
            #expect(wit.contains("record foo-bar"))
            #expect(!wit.contains("enum foo-bar"))
            #expect(extractor.diagnostics.contains { $0.message.contains("already used by") })
        }

        @Test func funcFuncCollisionDropsLaterWithDiagnostic() {
            let (wit, extractor) = extract(
                """
                @WIT public func setup(with x: Int) {}
                @WIT public func setup(x: Int, y: Int) {}
                """)
            #expect(wit.ranges(of: "setup").count == 1)
            #expect(wit.contains("setup: func(x: s64);"))
            #expect(extractor.diagnostics.contains { $0.message.contains("already used by") })
        }

        @Test func typeBeatsFunctionAtSameWITName() {
            let (wit, extractor) = extract(
                """
                @WIT public struct Foo { public var x: Int }
                @WIT public func foo() {}
                """)
            #expect(wit.contains("record foo"))
            #expect(!wit.contains("foo: func"))
            #expect(extractor.diagnostics.contains { $0.message.contains("already used by") })
        }
    }
#endif
