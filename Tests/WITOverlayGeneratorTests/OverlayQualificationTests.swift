import Testing
import WIT

@testable import WITOverlayGenerator

/// The overlay emits Swift declarations whose names can shadow the intended `WasmKit.`/`Swift.` symbols, so
/// unqualified references would bind to the shadow. These assert the qualified spellings.
@Suite(TestEnvironmentTraits.hostGeneratorAvailability)
struct OverlayQualificationTests {
    private func guestCode(_ wit: String) throws -> String {
        let source = try SourceFileSyntax.parse(wit, fileName: "kw.wit")
        let packageResolver = PackageResolver()
        let mainPackage = try packageResolver.register(packageSources: [source])
        let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
        return try generateGuest(context: context)
    }

    private func hostCode(_ wit: String) throws -> String {
        let source = try SourceFileSyntax.parse(wit, fileName: "kw.wit")
        let packageResolver = PackageResolver()
        let mainPackage = try packageResolver.register(packageSources: [source])
        let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
        return try generateHost(context: context)
    }

    // MARK: - Host-runtime (WasmKit) qualification

    @Test func hostLinkQualifiesStoreAndImports() throws {
        let code = try hostCode("package test:q1;\nworld w { export run: func(); }")
        #expect(code.contains("store: WasmKit.Store"))
        #expect(code.contains("inout WasmKit.Imports"))
    }

    @Test func hostExportBodyQualifiesWasmKitRuntimeTypes() throws {
        let code = try hostCode("package test:q2;\nworld w { export run: func(); }")
        #expect(code.contains("throw WasmKit.CanonicalABIError("))
        #expect(code.contains("WasmKit.CanonicalOptions._derive"))
        #expect(code.contains("WasmKit.CanonicalCallContext("))
    }

    /// string and list params/result force the lifting/lowering emissions.
    @Test func hostExportQualifiesLiftingLowering() throws {
        let code = try hostCode(
            "package test:q3;\nworld w { export run: func(s: string, xs: list<u32>) -> list<u32>; }")
        #expect(code.contains("WasmKit.CanonicalLowering.lowerString"))
        #expect(code.contains("WasmKit.CanonicalLowering.lowerList"))
        #expect(code.contains("WasmKit.CanonicalLifting.liftList"))
    }

    // MARK: - Flags conformance qualification

    @Test func flagsQualifiesOptionSetConformance() throws {
        let code = try guestCode("package test:q4;\nworld w { flags f { a, b } export run: func(); }")
        #expect(code.contains(": Swift.OptionSet {"))
    }

    @Test func wideFlagsQualifiesRawValueConformances() throws {
        let code = try guestCode(
            """
            package test:q5;
            world w {
              flags wide {
                b00,b01,b02,b03,b04,b05,b06,b07,b08,b09,b10,b11,b12,b13,b14,b15,
                b16,b17,b18,b19,b20,b21,b22,b23,b24,b25,b26,b27,b28,b29,b30,b31,
                b32,
              }
              export run: func();
            }
            """)
        #expect(code.contains("struct RawValue: Swift.Equatable, Swift.Hashable {"))
    }
}
