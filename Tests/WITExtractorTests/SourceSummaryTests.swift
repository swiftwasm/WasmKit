import Testing

@testable import WITExtractor

struct SourceSummaryTests {
    private func summary(_ source: String) -> SwiftSourceSummary {
        SwiftSourceSummary(inventory: WITDeclCollector.collect(source: source).inventory)
    }

    @Test func mapsNestedWITNameToQualifiedSwiftName() {
        // An empty enum has no WIT name but still qualifies its nested types.
        let summary = summary(
            """
            @WIT public struct EmptyStruct {}
            @WIT public enum NamespaceEnum {
                @WIT public struct NestedEmptyStruct {}
            }
            """)
        #expect(summary.qualifiedSwiftName(byWITName: "empty-struct") == "EmptyStruct")
        #expect(
            summary.qualifiedSwiftName(byWITName: "namespace-enum-nested-empty-struct")
                == "NamespaceEnum.NestedEmptyStruct")
        #expect(summary.qualifiedSwiftName(byWITName: "namespace-enum") == nil)
    }

    @Test func preservesSingleLetterTypeNames() {
        let summary = summary(
            """
            @WIT public struct A { public var f1: String }
            @WIT public struct B { public var f2: String }
            @WIT public struct TwoWords { public var f3: String }
            """)
        #expect(summary.qualifiedSwiftName(byWITName: "A") == "A")
        #expect(summary.qualifiedSwiftName(byWITName: "B") == "B")
        #expect(summary.qualifiedSwiftName(byWITName: "two-words") == "TwoWords")
    }

    @Test func enumCaseNamesByWITName() {
        let summary = summary(
            """
            @WIT public enum EnumType { case c1, c2(Int), c3(String) }
            @WIT public struct Widget { public var f: Int }
            """)
        #expect(summary.enumCaseNames(byWITName: "enum-type") == ["c1", "c2", "c3"])
        #expect(summary.enumCaseNames(byWITName: "widget") == nil)
        #expect(summary.enumCaseNames(byWITName: "missing") == nil)
    }

    @Test func carriesExternalLabelsByWITName() {
        let summary = summary("@WIT public func scaleShape(_ factor: Double, by amount: Double) {}")
        #expect(summary.argumentLabels(byWITFunctionName: "scale-shape") == [nil, "by"])
        #expect(summary.argumentLabels(byWITFunctionName: "absent") == nil)
    }
}
