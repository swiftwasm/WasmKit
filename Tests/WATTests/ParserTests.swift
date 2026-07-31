import Foundation
import Testing
import WasmParser

@testable import WAT

@Suite
struct ParserTests {
    func parseWast(_ source: String, features: WasmFeatureSet = .default) throws -> [WastDirective] {
        var parser = WastParser(source, features: features)
        var directives: [WastDirective] = []
        while let directive = try parser.nextDirective() {
            directives.append(directive)
        }
        return directives
    }

    func parseModule(_ source: String) throws -> ModuleDirective? {
        let directives = try parseWast(source)
        guard case .module(let moduleDirective) = directives.first else {
            #expect((false), "Expected module directive")
            return nil
        }
        return moduleDirective
    }

    func parseBinaryModule(_ source: String) throws -> (source: [UInt8], id: String?)? {
        guard let module = try parseModule(source) else { return nil }
        guard case .binary(let content) = module.source else { return nil }
        return (content, module.id)
    }

    @Test
    func parseWastBinaryModule() throws {
        #expect(
            try parseBinaryModule(#"(module binary "\00asm\01\00\00\00")"#)?.source == [0, 97, 115, 109, 1, 0, 0, 0]
        )
        #expect(
            try parseBinaryModule(
                #"""
                (module binary
                "\00asm" "\01\00\00\00"
                ;; comment between strings
                "foo"
                )
                """#)?.source == [0, 97, 115, 109, 1, 0, 0, 0, 102, 111, 111]
        )

        do {
            let m1 = try parseBinaryModule(#"(module $M1 binary "\00asm\01\00\00\00")"#)
            #expect(m1?.id == "$M1")
            #expect(m1?.source == [0, 97, 115, 109, 1, 0, 0, 0])
        }
    }

    @Test
    func parseWastModule() throws {
        var parser = WastParser(
            #"""
            (module
              ;; comment here
              (memory 1)

              (func $dummy)

              (func (export "empty")
                (unknown expr)
              )
            )
            """#, features: .default)

        while let directive = try parser.nextDirective() {
            switch directive {
            case .module(let directive):
                guard case .text(_) = directive.source else {
                    #expect((false), "Expected text module field")
                    return
                }
            case _:
                #expect((false), "Expected only module directive")
            }
        }
    }

    @Test
    func parseModuleDefinitionDoesNotThrow() throws {
        #expect(throws: Never.self) {
            _ = try self.parseWast("(module definition (memory 65536))")
        }
    }

    @Test
    func parseModuleDefinitionBare() throws {
        let m = try #require(try parseModule("(module definition (memory 65536))"))
        #expect(m.isModuleDefinition)
        #expect(m.id == nil)
        #expect({ if case .text = m.source { return true } else { return false } }())
    }

    @Test
    func parseModuleDefinitionNamed() throws {
        // Id appears AFTER `definition` (instance.wast:3/109 shape).
        let m = try #require(try parseModule("(module definition $M (memory 0))"))
        #expect(m.isModuleDefinition)
        #expect(m.id == "$M")
    }

    @Test
    func parseModuleDefinitionBinary() throws {
        // `definition` with a binary source (exact-func-import.wast:219 shape).
        let m = try #require(try parseModule(#"(module definition binary "\00asm\01\00\00\00")"#))
        #expect(m.isModuleDefinition)
        #expect({ if case .binary(let b) = m.source { return b == [0, 97, 115, 109, 1, 0, 0, 0] } else { return false } }())
    }

    @Test
    func parsePlainModuleIsNotDefinition() throws {
        let m = try #require(try parseModule("(module (memory 1))"))
        #expect(!m.isModuleDefinition)
    }

    @Test
    func parseAssertInvalidWrappedDefinitionThreadsFlag() throws {
        // The flag must thread through the wrapped construction site. The harness ignores the flag
        // for assert_invalid, so behavior there is unchanged.
        let directives = try parseWast(#"(assert_invalid (module definition (memory 65537)) "size")"#)
        guard case .assertInvalid(let module, _) = try #require(directives.first) else {
            #expect(Bool(false), "expected assert_invalid directive")
            return
        }
        #expect(module.isModuleDefinition)
    }

    @Test
    func parseEitherAssertReturnDoesNotThrow() throws {
        #expect(throws: Never.self) {
            _ = try self.parseWast(
                #"(module (func (export "f") (result v128) (v128.const i32x4 0 0 0 0)))"#
                    + #"(assert_return (invoke "f") (either (v128.const i32x4 0 0 0 0) (v128.const i32x4 1 0 0 0)))"#)
        }
    }

    @Test
    func parseWastModuleSkip() throws {
        let directives = try parseWast(
            #"""
            (module
              ;; comment here
              (memory 1)

              (func $dummy)

              (func (export "empty")
                (unknown expr)
              )
            )
            (module binary "ok")
            """#)

        #expect(directives.count == 2)
        guard case .module(let directive) = try #require(directives.last),
            case .binary(let content) = directive.source
        else {
            return
        }
        #expect(content == Array("ok".utf8))
    }

    @Test
    func specForward() throws {
        let source = """
            (module
              (func $even (export "even") (param $n i32) (result i32)
                (if (result i32) (i32.eq (local.get $n) (i32.const 0))
                  (then (i32.const 1))
                  (else (call $odd (i32.sub (local.get $n) (i32.const 1))))
                )
              )

              (func $odd (export "odd") (param $n i32) (result i32)
                (if (result i32) (i32.eq (local.get $n) (i32.const 0))
                  (then (i32.const 0))
                  (else (call $even (i32.sub (local.get $n) (i32.const 1))))
                )
              )
            )

            (assert_return (invoke "even" (i32.const 13)) (i32.const 0))
            (assert_return (invoke "even" (i32.const 20)) (i32.const 1))
            (assert_return (invoke "odd" (i32.const 13)) (i32.const 1))
            (assert_return (invoke "odd" (i32.const 20)) (i32.const 0))
            """
        let wast = try parseWast(source)
        #expect(wast.count == 5)
        guard case .module(let module) = wast.first, case .text(var wat) = module.source else {
            #expect((false), "expect a module directive")
            return
        }
        #expect(wat.functionsMap.count == 2)
        let even = wat.functionsMap[0]
        let (evenType, _) = try wat.types.resolve(use: even.typeUse)
        #expect(evenType.signature.parameters == [.i32])
        #expect(evenType.signature.results.first == .i32)
        #expect(evenType.parameterNames.map(\.?.value) == ["$n"])
    }

    @Test
    func funcIdBinding() throws {
        let source = """
            (module
              (table $t 10 funcref)
              (func $f)
              (func $g)

              ;; Passive
              (elem funcref)
              (elem funcref (ref.func $f) (item ref.func $f) (item (ref.null func)) (ref.func $g))
              (elem func)
              (elem func $f $f $g $g)

              (elem $p1 funcref)
              (elem $p2 funcref (ref.func $f) (ref.func $f) (ref.null func) (ref.func $g))
              (elem $p3 func)
              (elem $p4 func $f $f $g $g)

              ;; Active
              (elem (table $t) (i32.const 0) funcref)
              (elem (table $t) (i32.const 0) funcref (ref.func $f) (ref.null func))
              (elem (table $t) (i32.const 0) func)
              (elem (table $t) (i32.const 0) func $f $g)
              (elem (table $t) (offset (i32.const 0)) funcref)
              (elem (table $t) (offset (i32.const 0)) func $f $g)
            )
            """
        let wat = try parseWAT(source)
        #expect(wat.tables.count == 1)
        let table = wat.tables[0]
        #expect(table.type == TableType(elementType: .funcRef, limits: Limits(min: 10, max: nil)))
        #expect(wat.elementsMap.count == 14)
    }

    // NOTE: We do the same check as a part of the EncoderTests, so it's
    // usually redundant and time-wasting to run this test every time.
    // Keeping it here just for local unit testing purposes.
    @Test(
        .enabled(if: ProcessInfo.processInfo.environment["WASMKIT_PARSER_SPECTEST"] == "1"),
        arguments: Spectest.wastFiles(include: [])
    )
    func parseSpectest(wastFile: URL) throws {
        let source = try String(contentsOf: wastFile, encoding: .utf8)
        _ = try parseWast(source, features: Spectest.deriveFeatureSet(wast: wastFile))
    }
}
