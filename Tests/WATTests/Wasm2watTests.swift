import Foundation
import Testing
import WasmParser

@testable import WAT

@Suite
struct Wasm2watTests {

    // MARK: - ModuleCollector unit tests

    @Test func collectEmptyModule() throws {
        let binary = try binaryStream(forWat: "(module)")
        let info = try collectModule(stream: binary)
        #expect(info.types.isEmpty)
        #expect(info.imports.isEmpty)
        #expect(info.functionTypeIndices.isEmpty)
        #expect(info.tables.isEmpty)
        #expect(info.memories.isEmpty)
        #expect(info.globals.isEmpty)
        #expect(info.exports.isEmpty)
        #expect(info.start == nil)
        #expect(info.elementSectionBytes == nil)
        #expect(info.codeSectionBytes == nil)
        #expect(info.dataSectionBytes == nil)
    }

    @Test func collectTypeSection() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (type (func (param i32 i32) (result i32)))
                  (type (func))
                )
                """)
        let info = try collectModule(stream: binary)
        #expect(info.types.count == 2)
        #expect(info.types[0].parameters == [.i32, .i32])
        #expect(info.types[0].results == [.i32])
        #expect(info.types[1].parameters == [])
        #expect(info.types[1].results == [])
    }

    @Test func collectFunctionAndCode() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (func (param i32 i32) (result i32)
                    local.get 0
                    local.get 1
                    i32.add)
                )
                """)
        let info = try collectModule(stream: binary)
        #expect(info.functionTypeIndices.count == 1)
        // Code is now stored as a raw slice; parse one entry to verify it.
        let codeBytes = try #require(info.codeSectionBytes)
        var parser = WasmParser.Parser(sectionBodyBytes: codeBytes)
        let count: UInt32 = try parser.parseUnsigned()
        #expect(count == 1)
        let code = try parser.parseCodeEntry()
        #expect(code.locals == [])
    }

    @Test func collectImports() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (import "env" "log" (func (param i32)))
                  (import "env" "mem" (memory 1))
                )
                """)
        let info = try collectModule(stream: binary)
        #expect(info.imports.count == 2)
        #expect(info.imports[0].module == "env")
        #expect(info.imports[0].name == "log")
        if case .function = info.imports[0].descriptor {
            // ok
        } else {
            Issue.record("Expected function import")
        }
        #expect(info.imports[1].name == "mem")
        if case .memory = info.imports[1].descriptor {
            // ok
        } else {
            Issue.record("Expected memory import")
        }
    }

    @Test func collectExports() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (func (export "add") (param i32 i32) (result i32)
                    local.get 0
                    local.get 1
                    i32.add)
                )
                """)
        let info = try collectModule(stream: binary)
        #expect(info.exports.count == 1)
        #expect(info.exports[0].name == "add")
        if case .function(let idx) = info.exports[0].descriptor {
            #expect(idx == 0)
        } else {
            Issue.record("Expected function export")
        }
    }

    @Test func collectMemory() throws {
        let binary = try binaryStream(forWat: "(module (memory 1 4))")
        let info = try collectModule(stream: binary)
        #expect(info.memories.count == 1)
        #expect(info.memories[0].type.min == 1)
        #expect(info.memories[0].type.max == 4)
    }

    @Test func collectGlobal() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (global i32 (i32.const 42))
                  (global (mut i64) (i64.const -1))
                )
                """)
        let info = try collectModule(stream: binary)
        #expect(info.globals.count == 2)
        #expect(info.globals[0].type.mutability == .constant)
        #expect(info.globals[0].type.valueType == .i32)
        #expect(info.globals[1].type.mutability == .variable)
        #expect(info.globals[1].type.valueType == .i64)
    }

    @Test func collectDataSegment() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (memory 1)
                  (data (i32.const 0) "hello")
                )
                """)
        let info = try collectModule(stream: binary)
        let dataBytes = try #require(info.dataSectionBytes)
        var parser = WasmParser.Parser(sectionBodyBytes: dataBytes)
        let count: UInt32 = try parser.parseUnsigned()
        #expect(count == 1)
        let seg = try parser.parseDataSegmentEntry()
        if case .active(let active) = seg {
            #expect(active.index == 0)
            #expect(Array(active.initializer) == Array("hello".utf8))
        } else {
            Issue.record("Expected active data segment")
        }
    }

    // MARK: - WatPrinter unit tests

    @Test func printEmptyModule() throws {
        let binary = try binaryStream(forWat: "(module)")
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat == "(module\n)\n")
    }

    @Test func printFunctionType() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (type (func (param i32 i32) (result i32)))
                )
                """)
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains("(type (;0;) (func (param i32 i32) (result i32)))"))
    }

    @Test func printMemoryWithMax() throws {
        let binary = try binaryStream(forWat: "(module (memory 1 4))")
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains("(memory (;0;) 1 4)"))
    }

    @Test func printExport() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (func (export "add") (param i32 i32) (result i32)
                    local.get 0
                    local.get 1
                    i32.add)
                )
                """)
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains(#"(export "add" (func 0))"#))
    }

    @Test func printGlobalMutable() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (global (mut i32) (i32.const 0))
                )
                """)
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains("(global (;0;) (mut i32) (i32.const 0))"))
    }

    @Test func printDataSegment() throws {
        let binary = try binaryStream(
            forWat:
                """
                (module
                  (memory 1)
                  (data (i32.const 0) "hello")
                )
                """)
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains("(data (;0;)"))
        #expect(wat.contains("hello"))
    }
}
