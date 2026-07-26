import SwiftSyntax
import Testing

@testable import WITExtractor

struct TypeResolverTests {
    // The symbol table indexes all nominals, so extra sources need no `@WIT`.
    private func resolverAndFieldType(_ swiftType: String, extraSources: [String] = []) throws
        -> (resolver: TypeResolver, type: TypeSyntax)
    {
        let probe = "@WIT public struct Probe { public var f: \(swiftType) }"
        let inventory = WITDeclCollector.collect(source: probe).inventory
        let type = try #require(inventory.types.first?.fields.first?.type, "no field type for \(swiftType)")
        let table = WITSymbolTableBuilder.build(sources: [probe] + extraSources)
        return (TypeResolver(symbolTable: table), type)
    }

    @Test func resolvesPrimitives() throws {
        let cases: [(String, String)] = [
            ("Bool", "bool"), ("UInt8", "u8"), ("UInt16", "u16"), ("UInt32", "u32"), ("UInt64", "u64"),
            ("UInt", "u64"), ("Int8", "s8"), ("Int16", "s16"), ("Int32", "s32"), ("Int64", "s64"),
            ("Int", "s64"), ("Float", "f32"), ("Double", "f64"), ("String", "string"),
        ]
        for (swift, wit) in cases {
            let (resolver, type) = try resolverAndFieldType(swift)
            #expect(resolver.resolve(type, inScope: []) == wit, "\(swift) should resolve to \(wit)")
        }
    }

    @Test func resolvesSwiftQualifiedSpellings() throws {
        for (swift, wit) in [("Swift.Int", "s64"), ("Swift.String", "string")] {
            let (resolver, type) = try resolverAndFieldType(swift)
            #expect(resolver.resolve(type, inScope: []) == wit)
        }
    }

    @Test func resolvesSugarAndGenericSpellings() throws {
        let cases: [(String, String)] = [
            ("Optional<Int>", "option<s64>"),
            ("Optional<Optional<Int>>", "option<option<s64>>"),
            ("Int?", "option<s64>"),
            ("Array<Int>", "list<s64>"),
            ("Array<Array<Int>>", "list<list<s64>>"),
            ("[Int]", "list<s64>"),
            ("Dictionary<String, Int>", "list<tuple<string, s64>>"),
            ("Dictionary<String, Dictionary<String, Int>>", "list<tuple<string, list<tuple<string, s64>>>>"),
            ("[String: Int]", "list<tuple<string, s64>>"),
            ("Swift.Array<Int>", "list<s64>"),
        ]
        for (swift, wit) in cases {
            let (resolver, type) = try resolverAndFieldType(swift)
            #expect(resolver.resolve(type, inScope: []) == wit, "\(swift) should resolve to \(wit)")
        }
    }

    @Test func resolvesSameModuleNominal() throws {
        let (resolver, type) = try resolverAndFieldType("Widget", extraSources: ["public struct Widget {}"])
        #expect(resolver.resolve(type, inScope: []) == "widget")
    }

    @Test func referencedNominalsAcrossContainers() throws {
        let (resolver, type) = try resolverAndFieldType("[Widget]", extraSources: ["public struct Widget {}"])
        #expect(resolver.referencedNominals(in: type, inScope: []).map(\.qualifiedName) == [["Widget"]])
    }

    @Test func emitGateDropsUnemittedNominal() throws {
        let (base, type) = try resolverAndFieldType("Widget", extraSources: ["public struct Widget {}"])
        var gated = base
        gated.emittedNominals = []
        #expect(gated.resolve(type, inScope: []) == nil)
        #expect(base.resolve(type, inScope: []) == "widget")
    }

    @Test func resolvesNestedNominalInnermostFirst() throws {
        let (resolver, type) = try resolverAndFieldType(
            "Inner",
            extraSources: [
                "public struct Outer { public struct Inner {} }",
                "public struct Inner {}",
            ])
        #expect(resolver.resolve(type, inScope: ["Outer"]) == "outer-inner")
        #expect(resolver.resolve(type, inScope: []) == "inner")
    }

    @Test func resolvesGenericUserNominalIgnoringArguments() throws {
        let (resolver, type) = try resolverAndFieldType("Box<Int>", extraSources: ["public struct Box<T> {}"])
        #expect(resolver.resolve(type, inScope: []) == "box")
    }

    @Test func resolvesGenericUserNominalWithUnresolvableArgument() throws {
        // Arguments are never consulted: `[Unknown]` drops, `Box<Unknown>` resolves to `box`.
        let (resolver, type) = try resolverAndFieldType(
            "Box<SomeUnknown>", extraSources: ["public struct Box<T> {}"])
        #expect(resolver.resolve(type, inScope: []) == "box")
    }

    @Test func userTypeShadowsGenericSugarName() throws {
        // The symbol table is consulted before the generic-sugar arm, so user `Array` shadows the sugar.
        let (resolver, type) = try resolverAndFieldType("Array<Int>", extraSources: ["public struct Array<T> {}"])
        #expect(resolver.resolve(type, inScope: []) == "array")
    }

    @Test func dropsUnresolvedInsideContainers() throws {
        for swift in [
            "[SomeUnknown]", "Optional<SomeUnknown>", "SomeUnknown?", "Dictionary<String, SomeUnknown>",
            "[String: SomeUnknown]", "(Int, SomeUnknown)",
        ] {
            let (resolver, type) = try resolverAndFieldType(swift)
            #expect(resolver.resolve(type, inScope: []) == nil, "\(swift) should drop")
        }
    }

    @Test func dropsValueGenericArgument() throws {
        // A value-generic argument (`.expr`, here `3`) makes the type unresolvable. `Foo` is declared so
        // that is the only cause of the drop, not an unknown base name.
        let (resolver, type) = try resolverAndFieldType("Foo<3>", extraSources: ["public struct Foo<T> {}"])
        #expect(resolver.resolve(type, inScope: []) == nil)
    }

    @Test func resolvesFieldTypedAsEscapedNominalName() throws {
        // A backtick-escaped name is read via `.text`, symmetrically with the builder.
        let (resolver, type) = try resolverAndFieldType("`enum`", extraSources: ["public struct `enum` {}"])
        #expect(resolver.resolve(type, inScope: []) == "%enum")
    }

    @Test func expandsTypealiasToPrimitive() throws {
        let (resolver, type) = try resolverAndFieldType("Meters", extraSources: ["public typealias Meters = Int"])
        #expect(resolver.resolve(type, inScope: []) == "s64")
    }

    @Test func expandsTypealiasChain() throws {
        let (resolver, type) = try resolverAndFieldType(
            "Distance",
            extraSources: ["public typealias Distance = Length", "public typealias Length = Int"])
        #expect(resolver.resolve(type, inScope: []) == "s64")
    }

    @Test func expandsTypealiasInItsEnclosingScope() throws {
        // The alias RHS must resolve in the alias's own enclosing scope, not the reference's scope;
        // `aliasScope = scope` would drop it to nil.
        let (resolver, type) = try resolverAndFieldType(
            "Space.T",
            extraSources: ["public enum Space { public struct Sibling {}; public typealias T = Sibling }"])
        #expect(resolver.resolve(type, inScope: []) == "space-sibling")
    }

    @Test func dropsCyclicTypealias() throws {
        let (resolver, type) = try resolverAndFieldType(
            "A", extraSources: ["public typealias A = B", "public typealias B = A"])
        #expect(resolver.resolve(type, inScope: []) == nil)
    }

    @Test func dropsCyclicTypealiasThroughSugar() throws {
        // The in-flight-alias set threads through the sugar arms, so a self-reference nested in sugar
        // terminates instead of recursing forever.
        let (resolver, type) = try resolverAndFieldType("A", extraSources: ["public typealias A = [A]"])
        #expect(resolver.resolve(type, inScope: []) == nil)
    }

    @Test func typealiasShadowingPrimitiveExpandsToRHS() throws {
        // The `.typeAlias` branch is consulted before the primitive map, so it expands to its RHS
        // rather than mapping by name.
        let (resolver, type) = try resolverAndFieldType("String", extraSources: ["public typealias String = Int"])
        #expect(resolver.resolve(type, inScope: []) == "s64")
    }

    @Test func sameModuleTypeShadowsPrimitive() throws {
        // The symbol table is consulted before the primitive map: a user `Int` wins.
        let (resolver, type) = try resolverAndFieldType("Int", extraSources: ["public struct Int {}"])
        #expect(resolver.resolve(type, inScope: []) == "int")
    }

    @Test func dropsUnresolvedType() throws {
        let (resolver, type) = try resolverAndFieldType("SomeExternalThing")
        #expect(resolver.resolve(type, inScope: []) == nil)  // no bare-name fallback
    }

    @Test func resolvesEnumPayloads() throws {
        let source = "@WIT public enum E { case c1, c2(Int), c3(String), c4([String]) }"
        let type = try #require(WITDeclCollector.collect(source: source).inventory.types.first)
        let resolver = TypeResolver(symbolTable: WITSymbolTableBuilder.build(sources: [source]))
        #expect(type.cases[0].payload.isEmpty)
        #expect(resolver.resolvePayload(type.cases[1].payload, inScope: []) == "s64")
        #expect(resolver.resolvePayload(type.cases[2].payload, inScope: []) == "string")
        #expect(resolver.resolvePayload(type.cases[3].payload, inScope: []) == "list<string>")
    }

    @Test func resolvesMultiParameterPayloadAsTuple() throws {
        let source = "@WIT public enum E { case pair(Int, String) }"
        let type = try #require(WITDeclCollector.collect(source: source).inventory.types.first)
        let resolver = TypeResolver(symbolTable: WITSymbolTableBuilder.build(sources: [source]))
        #expect(resolver.resolvePayload(type.cases[0].payload, inScope: []) == "tuple<s64, string>")
    }

    @Test func resolvesFunctionParametersAndResults() throws {
        func function(_ source: String) throws -> (TypeResolver, FunctionEntry) {
            let entry = try #require(WITDeclCollector.collect(source: source).inventory.functions.first)
            return (TypeResolver(symbolTable: WITSymbolTableBuilder.build(sources: [source])), entry)
        }
        let (r1, f1) = try function("@WIT public func noParameter() {}")
        #expect(r1.resolveParameters(f1.parameters.map(\.type), inScope: []) == [])
        #expect(r1.resolveResults(f1.returnClause, inScope: []) == [])

        let (r2, f2) = try function("@WIT public func withParameters(x: String, y: Int) {}")
        #expect(r2.resolveParameters(f2.parameters.map(\.type), inScope: []) == ["string", "s64"])
        #expect(r2.resolveResults(f2.returnClause, inScope: []) == [])

        let (r3, f3) = try function("@WIT public func withResult() -> Int { return 0 }")
        #expect(r3.resolveResults(f3.returnClause, inScope: []) == ["s64"])

        // WIT permits at most one result; a multi-element tuple return lowers to a single `tuple<...>`.
        let (r4, f4) = try function("@WIT public func withMultipleResult() -> (x: Int, y: Int) { return (0, 1) }")
        #expect(r4.resolveResults(f4.returnClause, inScope: []) == ["tuple<s64, s64>"])

        let (r5, f5) = try function("@WIT public func voidResult() -> Void {}")
        #expect(r5.resolveResults(f5.returnClause, inScope: []) == [])
        let (r6, f6) = try function("@WIT public func qualifiedVoidResult() -> Swift.Void {}")
        #expect(r6.resolveResults(f6.returnClause, inScope: []) == [])

        // A parenthesized single-element return `-> (T)` is a one-element tuple that collapses to its
        // element, not a `tuple<...>`.
        let (r7, f7) = try function("@WIT public func parenthesizedResult() -> (Int) { return 0 }")
        #expect(r7.resolveResults(f7.returnClause, inScope: []) == ["s64"])
    }
}
