import Foundation
import WasmParser
import XCTest

@testable import WAT

class ParserTests: XCTestCase {
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
        guard case let .module(moduleDirective) = directives.first else {
            XCTFail("Expected module directive")
            return nil
        }
        return moduleDirective
    }

    func parseBinaryModule(_ source: String) throws -> (source: [UInt8], id: String?)? {
        guard let module = try parseModule(source) else { return nil }
        guard case let .binary(content) = module.source else { return nil }
        return (content, module.id)
    }

    func testParseWastBinaryModule() throws {
        try XCTAssertEqual(
            parseBinaryModule(#"(module binary "\00asm\01\00\00\00")"#)?.source,
            [0, 97, 115, 109, 1, 0, 0, 0]
        )
        try XCTAssertEqual(
            parseBinaryModule(
                #"""
                (module binary
                "\00asm" "\01\00\00\00"
                ;; comment between strings
                "foo"
                )
                """#)?.source,
            [0, 97, 115, 109, 1, 0, 0, 0, 102, 111, 111]
        )

        do {
            let m1 = try parseBinaryModule(#"(module $M1 binary "\00asm\01\00\00\00")"#)
            XCTAssertEqual(m1?.id, "$M1")
            XCTAssertEqual(m1?.source, [0, 97, 115, 109, 1, 0, 0, 0])
        }
    }

    func testParseWastModule() throws {
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
                    XCTFail("Expected text module field")
                    return
                }
            case _:
                XCTFail("Expected only module directive")
            }
        }
    }

    func testParseWastModuleSkip() throws {
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

        XCTAssertEqual(directives.count, 2)
        guard case let .module(directive) = try XCTUnwrap(directives.last),
            case let .binary(content) = directive.source
        else {
            return
        }
        XCTAssertEqual(content, Array("ok".utf8))
    }

    func testSpecForward() throws {
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
        XCTAssertEqual(wast.count, 5)
        guard case let .module(module) = wast.first, case var .text(wat) = module.source else {
            XCTFail("expect a module directive")
            return
        }
        XCTAssertEqual(wat.functionsMap.count, 2)
        let even = wat.functionsMap[0]
        let (evenType, _) = try wat.types.resolve(use: even.typeUse)
        XCTAssertEqual(evenType.signature.parameters, [.i32])
        XCTAssertEqual(evenType.signature.results.first, .i32)
        XCTAssertEqual(evenType.parameterNames.map(\.?.value), ["$n"])
    }

    func testFuncIdBinding() throws {
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
        XCTAssertEqual(wat.tables.count, 1)
        let table = wat.tables[0]
        XCTAssertEqual(table.type, TableType(elementType: .funcRef, limits: Limits(min: 10, max: nil)))
        XCTAssertEqual(wat.elementsMap.count, 14)
    }

    func testParseSpectest() throws {
        var failureCount = 0
        var totalCount = 0
        for filePath in Spectest.wastFiles(include: []) {
            print("Parsing \(filePath.path)...")
            totalCount += 1
            let source = try String(contentsOf: filePath)
            do {
                _ = try parseWast(source, features: Spectest.deriveFeatureSet(wast: filePath))
            } catch {
                failureCount += 1
                XCTFail("Failed to parse \(filePath.path):\(error)")
            }
        }

        if failureCount > 0 {
            XCTFail("Failed to parse \(failureCount) / \(totalCount) files")
        }
    }
}
