import Testing

@testable import WITExtractor

struct InlineClosureTests {
    // Dependencies precede main in the symbol table so a main-module nominal wins a bare-name collision.
    private func widen(
        main: ModuleSource, dependencies: [ModuleSource],
        diagnostics: DiagnosticCollection = DiagnosticCollection()
    ) -> DeclInventory {
        let table = WITSymbolTableBuilder.build(tagged: dependencies + [main])
        let inventory = WITDeclCollector.collect(parsed: [main.tree], into: diagnostics)
        return InlineClosure(
            resolver: TypeResolver(symbolTable: table), mainModule: main.module, diagnostics: diagnostics
        ).widen(inventory)
    }

    @Test func inlinesDependencyFieldType() {
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct UsesExternal { public var ext: External }"),
            dependencies: [ModuleSource(module: "ExternalLib", source: "public struct External { public var label: String; public init(label: String) { self.label = label } }")])
        #expect(widened.types.map(\.witName) == ["uses-external", "external"])
        let external = widened.types.first { $0.witName == "external" }
        #expect(external?.swiftQualifiedName == "ExternalLib.External")
        #expect(external?.fields.map(\.name) == ["label"])
    }

    @Test func doesNotInlineSameModuleUnmarkedType() {
        // `@WIT` is the export gate for same-module code, so an unmarked same-module type is not inlined.
        let widened = widen(
            main: ModuleSource(
                module: "Main",
                source: "@WIT public struct Holder { public var inner: Hidden }\npublic struct Hidden { public var x: Int }"),
            dependencies: [])
        #expect(widened.types.map(\.witName) == ["holder"])
    }

    @Test func recursesIntoInlinedDependencyMembers() {
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct Root { public var mid: Mid }"),
            dependencies: [ModuleSource(
                module: "Dep",
                source: "public struct Mid { public var leaf: Leaf; public init(leaf: Leaf) { self.leaf = leaf } }\npublic struct Leaf { public var n: Int; public init(n: Int) { self.n = n } }")])
        #expect(widened.types.map(\.witName) == ["root", "mid", "leaf"])
        #expect(widened.types.first { $0.witName == "leaf" }?.swiftQualifiedName == "Dep.Leaf")
    }

    @Test func dropsInconstructibleDependencyStruct() {
        // An implicit memberwise init is internal, so the overlay cannot construct it cross-module.
        let diagnostics = DiagnosticCollection()
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct UsesExternal { public var ext: External }"),
            dependencies: [ModuleSource(module: "ExternalLib", source: "public struct External { public var label: String }")],
            diagnostics: diagnostics)
        #expect(widened.types.map(\.witName) == ["uses-external"])
        #expect(
            diagnostics.diagnostics.contains {
                $0.message.contains("External") && $0.message.contains("initializer")
            })
    }

    @Test func dropsNonPublicTransitiveDependencyType() {
        // Field type `Hidden` is internal to the dependency, so it is not nameable from the overlay.
        let diagnostics = DiagnosticCollection()
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct Root { public var p: Public }"),
            dependencies: [ModuleSource(
                module: "Dep",
                source: "public struct Public { public var inner: Hidden; public init(inner: Hidden) { self.inner = inner } }\nstruct Hidden { public var n: Int }")],
            diagnostics: diagnostics)
        #expect(widened.types.map(\.witName) == ["root", "public"])
        #expect(
            diagnostics.diagnostics.contains {
                $0.message.contains("Hidden") && $0.message.contains("public")
            })
    }

    @Test func dropsDependencyStructWithOnlyFailableInit() {
        // `init?` returns `Type?`, which the overlay's unconditional `Type(...)` call cannot use.
        let diagnostics = DiagnosticCollection()
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct UsesExternal { public var ext: External }"),
            dependencies: [ModuleSource(
                module: "ExternalLib",
                source: "public struct External { public var label: String; public init?(label: String) { self.label = label } }")],
            diagnostics: diagnostics)
        #expect(widened.types.map(\.witName) == ["uses-external"])
        #expect(diagnostics.diagnostics.contains { $0.message.contains("External") })
    }

    @Test func dropsEmptyDependencyStructWithoutPublicInit() {
        // An empty struct's implicit `init()` is internal, so the overlay's `Type()` call is inaccessible.
        let widened = widen(
            main: ModuleSource(module: "Main", source: "@WIT public struct Holder { public var marker: Marker }"),
            dependencies: [ModuleSource(module: "Dep", source: "public struct Marker {}")])
        #expect(widened.types.map(\.witName) == ["holder"])
    }
}
