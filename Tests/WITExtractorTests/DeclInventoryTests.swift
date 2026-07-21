import Testing

@testable import WITExtractor

struct DeclInventoryTests {
    @Test func selectsTypeByMarkerCollectsBarePublicFields() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                @WIT public struct A { public var f1: String }
                @WIT public struct B { public var f2: String }
                """)
        #expect(inv.types.map(\.name) == ["A", "B"])
        #expect(inv.types.first { $0.name == "A" }?.fields.map(\.name) == ["f1"])
        #expect(inv.types.first { $0.name == "A" }?.fields.first?.type.trimmedDescription == "String")
    }

    @Test func dropsUnmarkedType() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                public struct NonExposed { public var field: Int }
                """)
        #expect(inv.types.isEmpty)
    }

    @Test func filtersFieldsByAccessAndExcludesStaticWithDiagnostic() {
        let (inv, diags) = WITDeclCollector.collect(
            source: """
                @WIT public struct StructFields {
                    @WIT public var varField: Int
                    @WIT public let letField: Int
                    @WIT public static var staticVarField: Int = 0
                    @WIT public static let staticLetField: Int = 0
                    @WIT public let `static`: Int
                    @WIT public let resource: Int
                    internal var internalField: Int
                }
                """)
        let fields = inv.types.first { $0.name == "StructFields" }?.fields ?? []
        // Absence of internalField from this list is the only internal-excluded check.
        #expect(fields.map(\.name) == ["varField", "letField", "static", "resource"])
        #expect(
            diags.diagnostics.map(\.message) == [
                "Skipping static field StructFields/staticVarField: static members are not WIT record fields",
                "Skipping static field StructFields/staticLetField: static members are not WIT record fields",
            ])
    }

    @Test func sharesTypeAcrossMultiBinding() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                @WIT public struct S {
                    public var a, b: Int
                    public var c: Int, d: String
                }
                """)
        let fields = inv.types.first { $0.name == "S" }?.fields ?? []
        #expect(fields.map(\.name) == ["a", "b", "c", "d"])
        #expect(fields.map { $0.type.trimmedDescription } == ["Int", "Int", "Int", "String"])
    }

    @Test func collectsEnumCasesWholesaleWithPayloadTypes() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                @WIT public enum EnumType { case c1, c2(Int), c3(String) }
                """)
        let entry = inv.types.first { $0.name == "EnumType" }
        #expect(entry?.cases.map(\.name) == ["c1", "c2", "c3"])
        #expect(entry?.cases.first { $0.name == "c1" }?.payload.isEmpty == true)
        #expect(entry?.cases.first { $0.name == "c2" }?.payload.map { $0.trimmedDescription } == ["Int"])
        #expect(entry?.cases.first { $0.name == "c3" }?.payload.map { $0.trimmedDescription } == ["String"])
    }

    @Test func dropsEmptyEnumButKeepsNestedTypeScope() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                @WIT public struct EmptyStruct {}
                @WIT public enum NamespaceEnum {
                    @WIT public struct NestedEmptyStruct {}
                }
                """)
        #expect(inv.types.map(\.qualifiedName) == ["EmptyStruct", "NamespaceEnum.NestedEmptyStruct"])
    }

    @Test func collectsTopLevelFunctionAndDiagnosesMethod() {
        let (inv, diags) = WITDeclCollector.collect(
            source: """
                @WIT public func noParameter() {}
                @WIT public func withMultipleResult() -> (x: Int, y: Int) { (0, 1) }
                public func unmarked() {}
                @WIT public struct S { @WIT public func method() {} }
                """)
        #expect(inv.functions.map(\.name) == ["noParameter", "withMultipleResult"])
        #expect(inv.functions.first { $0.name == "withMultipleResult" }?.returnClause != nil)
        #expect(
            diags.diagnostics.map(\.message) == [
                "Skipping method 'method': only struct, enum, and top-level function declarations export to WIT"
            ])
    }

    @Test func capturesParameterLabelsAndInternalNames() throws {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                @WIT public func area(of shape: Double) {}
                @WIT public func scale(_ factor: Double, by amount: Double) {}
                @WIT public func plain(a: Double, b: Double) {}
                """)
        func params(_ name: String) throws -> [FunctionEntry.Parameter] {
            try #require(inv.functions.first { $0.name == name }).parameters
        }
        #expect(try params("area").map(\.externalLabel) == ["of"])
        #expect(try params("area").map(\.internalName) == ["shape"])
        #expect(try params("scale").map(\.externalLabel) == [nil, "by"])
        #expect(try params("scale").map(\.internalName) == ["factor", "amount"])
        #expect(try params("plain").map(\.externalLabel) == ["a", "b"])
        #expect(try params("plain").map(\.internalName) == ["a", "b"])
    }

    @Test func diagnosesMarkedUnsupportedDeclKinds() {
        let (inv, diags) = WITDeclCollector.collect(
            source: """
                @WIT public class C {}
                @WIT public typealias T = Int
                """)
        #expect(inv.types.isEmpty)
        #expect(
            diags.diagnostics.map(\.message) == [
                "Skipping class 'C': only struct, enum, and top-level function declarations export to WIT",
                "Skipping typealias 'T': only struct, enum, and top-level function declarations export to WIT",
            ])
    }

    @Test func exportsWITTypesDeclaredInExtensions() {
        let (inv, _) = WITDeclCollector.collect(
            source: """
                public struct Outer {}
                extension Outer {
                    @WIT public struct InExtension { public var v: Int }
                }
                """)
        let entry = inv.types.first { $0.name == "InExtension" }
        #expect(entry?.qualifiedName == "Outer.InExtension")
        #expect(entry?.fields.map(\.name) == ["v"])
    }

    @Test func collectsAcrossSources() {
        let inventory = WITDeclCollector.collect(
            sources: ["@WIT public struct A { public var f: Int }", "@WIT public struct B { public var g: Int }"],
            into: DiagnosticCollection())
        #expect(inventory.types.map(\.name) == ["A", "B"])
    }
}
