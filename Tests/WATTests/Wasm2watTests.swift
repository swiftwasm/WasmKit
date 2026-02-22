import Foundation
import Testing
import WasmParser

@testable import WAT

@Suite
struct Wasm2watTests {

    // MARK: - Helper

    /// Assemble WAT text → binary.
    private func assemble(_ wat: String) throws -> StaticByteStream {
        try StaticByteStream(bytes: wat2wasm(wat))
    }

    // MARK: - ModuleCollector unit tests

    @Test func collectEmptyModule() throws {
        let binary = try assemble("(module)")
        let info = try collectModule(stream: binary)
        #expect(info.types.isEmpty)
        #expect(info.imports.isEmpty)
        #expect(info.functionTypeIndices.isEmpty)
        #expect(info.tables.isEmpty)
        #expect(info.memories.isEmpty)
        #expect(info.globals.isEmpty)
        #expect(info.exports.isEmpty)
        #expect(info.start == nil)
        #expect(info.elements.isEmpty)
        #expect(info.codes.isEmpty)
        #expect(info.data.isEmpty)
    }

    @Test func collectTypeSection() throws {
        let binary = try assemble(
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
        let binary = try assemble(
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
        #expect(info.codes.count == 1)
        #expect(info.codes[0].locals == [])
    }

    @Test func collectImports() throws {
        let binary = try assemble(
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
        let binary = try assemble(
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
        let binary = try assemble("(module (memory 1 4))")
        let info = try collectModule(stream: binary)
        #expect(info.memories.count == 1)
        #expect(info.memories[0].type.min == 1)
        #expect(info.memories[0].type.max == 4)
    }

    @Test func collectGlobal() throws {
        let binary = try assemble(
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
        let binary = try assemble(
            """
            (module
              (memory 1)
              (data (i32.const 0) "hello")
            )
            """)
        let info = try collectModule(stream: binary)
        #expect(info.data.count == 1)
        if case .active(let seg) = info.data[0] {
            #expect(seg.index == 0)
            #expect(Array(seg.initializer) == Array("hello".utf8))
        } else {
            Issue.record("Expected active data segment")
        }
    }

    // MARK: - WatPrinter unit tests

    @Test func printEmptyModule() throws {
        let binary = try assemble("(module)")
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat == "(module\n)\n")
    }

    @Test func printFunctionType() throws {
        let binary = try assemble(
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
        let binary = try assemble("(module (memory 1 4))")
        let info = try collectModule(stream: binary)
        var printer = WatPrinter(info: info)
        let wat = try printer.print()
        #expect(wat.contains("(memory (;0;) 1 4)"))
    }

    @Test func printExport() throws {
        let binary = try assemble(
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
        let binary = try assemble(
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
        let binary = try assemble(
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

    // MARK: - Round-trip tests

    /// Assembles WAT → binary → disassembles → re-assembles → checks binaries match.
    private func roundTrip(_ source: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let binary1 = try assemble(source)
        let text = try wasm2wat(binary1)
        let binary2 = try assemble(text)
        #expect(
            binary1.bytes == binary2.bytes,
            "Round-trip mismatch for:\n\(source)\nDisassembled:\n\(text)",
            sourceLocation: sourceLocation
        )
    }

    @Test func roundTripEmptyModule() throws {
        try roundTrip("(module)")
    }

    @Test func roundTripSimpleAdd() throws {
        try roundTrip(
            """
            (module
              (func $add (param i32 i32) (result i32)
                local.get 0
                local.get 1
                i32.add)
              (export "add" (func $add))
            )
            """)
    }

    @Test func roundTripMemoryAndData() throws {
        try roundTrip(
            """
            (module
              (memory 1)
              (data (i32.const 0) "hello world")
            )
            """)
    }

    @Test func roundTripGlobals() throws {
        try roundTrip(
            """
            (module
              (global $g (mut i32) (i32.const 42))
              (func (export "get") (result i32) global.get $g)
              (func (export "set") (param i32) global.set $g)
            )
            """)
    }

    @Test func roundTripImports() throws {
        try roundTrip(
            """
            (module
              (import "env" "log" (func (param i32)))
              (import "env" "mem" (memory 1))
              (func (export "run") (param i32)
                local.get 0
                call 0)
            )
            """)
    }

    @Test func roundTripTable() throws {
        try roundTrip(
            """
            (module
              (table 2 funcref)
              (func $f1 (result i32) i32.const 1)
              (func $f2 (result i32) i32.const 2)
              (elem (i32.const 0) func $f1 $f2)
            )
            """)
    }

    @Test func roundTripIfElse() throws {
        try roundTrip(
            """
            (module
              (func (param i32) (result i32)
                local.get 0
                if (result i32)
                  i32.const 1
                else
                  i32.const 0
                end)
            )
            """)
    }

    @Test func roundTripLoop() throws {
        try roundTrip(
            """
            (module
              (func (param i32) (result i32)
                (local i32)
                block $exit
                  loop $top
                    local.get 0
                    i32.eqz
                    br_if $exit
                    local.get 1
                    i32.const 1
                    i32.add
                    local.set 1
                    local.get 0
                    i32.const 1
                    i32.sub
                    local.set 0
                    br $top
                  end
                end
                local.get 1)
            )
            """)
    }

    @Test func roundTripStart() throws {
        try roundTrip(
            """
            (module
              (func $init)
              (start $init)
            )
            """)
    }

    @Test func roundTripPassiveData() throws {
        try roundTrip(
            """
            (module
              (memory 1)
              (data "passive segment")
            )
            """)
    }

    @Test func roundTripBrTable() throws {
        try roundTrip(
            """
            (module
              (func (param i32) (result i32)
                block
                  block
                    local.get 0
                    br_table 0 1
                  end
                  i32.const 100
                  return
                end
                i32.const 200)
            )
            """)
    }

    @Test func roundTripCallIndirect() throws {
        try roundTrip(
            """
            (module
              (type (func (param i32) (result i32)))
              (table 1 funcref)
              (func (param i32 i32) (result i32)
                local.get 0
                local.get 1
                call_indirect (type 0))
            )
            """)
    }
}
