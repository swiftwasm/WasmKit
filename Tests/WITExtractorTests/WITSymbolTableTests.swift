import Testing

@testable import WITExtractor

struct WITSymbolTableTests {
    private func isNominal(_ entry: WITSymbolTable.Entry?) -> Bool {
        if case .nominal = entry { return true }
        return false
    }

    @Test func nominalCarriesModuleAndNode() {
        let table = WITSymbolTableBuilder.build(tagged: [
            ModuleSource(module: "Main", source: "public struct Top { public struct Inner {} }")
        ])
        guard case .nominal(let module, let node)? = table.entry(["Top"]) else {
            Issue.record("expected a nominal entry at [Top]")
            return
        }
        #expect(module == "Main")
        if case .structDecl = node {} else { Issue.record("expected a structDecl node") }
    }

    @Test func indexesTopLevelAndNestedNominals() {
        let table = WITSymbolTableBuilder.build(sources: [
            """
            public struct Outer {
                public struct Inner {}
                public enum E { case a }
            }
            public struct Top {}
            public class C { public struct Nested {} }
            public actor A { public struct InActor {} }
            """
        ])
        #expect(table.contains(["Outer"]))
        #expect(table.contains(["Outer", "Inner"]))
        #expect(table.contains(["Outer", "E"]))
        #expect(table.contains(["Top"]))
        #expect(table.contains(["C", "Nested"]))
        #expect(table.contains(["A", "InActor"]))
        #expect(!table.contains(["C"]))  // a class is not a WIT nominal
        #expect(!table.contains(["A"]))  // nor an actor
        #expect(!table.contains(["Inner"]))
        #expect(isNominal(table.entry(["Outer", "Inner"])))
    }

    @Test func resolvesInnermostScopeFirst() {
        let table = WITSymbolTableBuilder.build(sources: [
            """
            public struct Inner {}
            public struct Outer { public struct Inner { public struct Deep {} } }
            """
        ])
        #expect(table.resolve(["Inner"], inScope: ["Outer"])?.qualifiedName == ["Outer", "Inner"])
        #expect(table.resolve(["Inner"], inScope: [])?.qualifiedName == ["Inner"])
        #expect(table.resolve(["Missing"], inScope: ["Outer"]) == nil)
        #expect(
            table.resolve(["Inner", "Deep"], inScope: ["Outer"])?.qualifiedName == ["Outer", "Inner", "Deep"])
        #expect(table.resolve(["Inner", "Deep"], inScope: []) == nil)
    }

    @Test func indexesNominalsDeclaredInExtensions() {
        let table = WITSymbolTableBuilder.build(sources: [
            """
            public struct Outer {}
            extension Outer { public struct Inner {} }
            extension Outer.Inner { public struct Deep {} }
            public struct Box<T> {}
            extension Box { public struct Item {} }
            """
        ])
        #expect(table.contains(["Outer", "Inner"]))
        #expect(table.contains(["Outer", "Inner", "Deep"]))  // extension applies regardless of source order
        #expect(table.contains(["Box", "Item"]))  // extended type's generic params don't appear in the path
        #expect(isNominal(table.entry(["Outer", "Inner"])))
    }

    @Test func mergesNominalsAcrossSources() {
        let table = WITSymbolTableBuilder.build(sources: [
            "public struct FromFileA { public struct Inner {} }",
            "public enum FromFileB {}",
        ])
        #expect(table.contains(["FromFileA"]))
        #expect(table.contains(["FromFileA", "Inner"]))
        #expect(table.contains(["FromFileB"]))
    }

    @Test func lastDeclarationWinsOnDuplicateQualifiedName() {
        // Last decl at a qualified name wins; the typealias parses after the struct.
        let table = WITSymbolTableBuilder.build(sources: [
            """
            public struct Dup {}
            public typealias Dup = Int
            """
        ])
        guard case .typeAlias = table.entry(["Dup"]) else {
            Issue.record("expected the later typealias to win at key [Dup]")
            return
        }
    }

    @Test func recordsTypealiasWithRHS() {
        let table = WITSymbolTableBuilder.build(sources: [
            """
            public typealias Meters = Int
            public struct S { public typealias Inner = String }
            public enum Namespace { public struct Leaf {} }
            public typealias Alias = Namespace.Leaf
            """
        ])
        guard case .typeAlias(let metersRHS)? = table.entry(["Meters"]) else {
            Issue.record("Meters is not a typealias entry")
            return
        }
        #expect(metersRHS.trimmedDescription == "Int")
        guard case .typeAlias(let innerRHS)? = table.entry(["S", "Inner"]) else {
            Issue.record("S.Inner is not a typealias entry")
            return
        }
        #expect(innerRHS.trimmedDescription == "String")
        // A qualified RHS is stored unresolved, keeping its full member-type spelling.
        guard case .typeAlias(let aliasRHS)? = table.entry(["Alias"]) else {
            Issue.record("Alias is not a typealias entry")
            return
        }
        #expect(aliasRHS.trimmedDescription == "Namespace.Leaf")
    }
}
