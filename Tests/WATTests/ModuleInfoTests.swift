import Testing
import WasmParser

@testable import WAT

@Suite
struct ModuleInfoTests {
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
        #expect(info.elementSection == nil)
        #expect(info.codeSection == nil)
        #expect(info.dataSection == nil)
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
        let code = try #require(info.codeSection).parse(features: info.features) { parser throws(WasmParserError) in
            let count: UInt32 = try parser.parseUnsigned()
            #expect(count == 1)
            return try parser.parseCodeEntry()
        }
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
        guard case .function = info.imports[0].descriptor else {
            Issue.record("Expected function import, got \(info.imports[0].descriptor)")
            return
        }
        #expect(info.imports[1].name == "mem")
        guard case .memory = info.imports[1].descriptor else {
            Issue.record("Expected memory import, got \(info.imports[1].descriptor)")
            return
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
        let segment = try #require(info.dataSection).parse(features: info.features) { parser throws(WasmParserError) in
            let count: UInt32 = try parser.parseUnsigned()
            #expect(count == 1)
            return try parser.parseDataSegmentEntry()
        }
        guard case .active(let active) = segment else {
            Issue.record("Expected active data segment")
            return
        }
        #expect(active.index == 0)
        #expect(Array(active.initializer) == Array("hello".utf8))
    }

    @Test func collectKeepsTheCodeSectionBytes() throws {
        let binary = try binaryStream(forWat: "(module (func) (func) (func))")
        let info = try collectModule(stream: binary, features: .default)
        let section = try #require(info.codeSection)
        #expect(section.body.count > 0)
        let count = try section.parse(features: info.features) { parser throws(WasmParserError) in
            let count: UInt32 = try parser.parseUnsigned()
            for _ in 0..<count { _ = try parser.parseCodeEntry() }
            return count
        }
        #expect(count == 3)
    }

    @Test func collectModuleRecordsTheFeatureSet() throws {
        let info = try collectModule(stream: binaryStream(forWat: "(module)"), features: .all)
        #expect(info.features == .all)
    }

    /// A type section declaring 4 bytes whose body parses after 1 (an empty vector).
    @Test func collectModuleRejectsOversizedSection() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x04, 0x00, 0x00, 0xFF, 0xFF,
        ]
        let stream = StaticByteStreamSource(bytes: bytes)
        let error = try #require(throws: WasmParserError.self) {
            _ = try collectModule(stream: stream)
        }
        guard case .message(let message) = error.kind else {
            Issue.record("Expected a .message error, got \(error.kind)")
            return
        }
        #expect(message.text == "Section size mismatch for section 1: expected 14 but got 11")
        #expect(error.location == 11)
    }
}
