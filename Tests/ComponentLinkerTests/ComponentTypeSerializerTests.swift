#if ComponentModel
import ComponentLinker
import ComponentModel
import Testing
import WasmParser
import WIT

@Suite
struct ComponentTypeSerializerTests {

    // MARK: - Helpers

    /// Build a SemanticsContext from inline WIT source text.
    private func buildContext(_ witSource: String) throws -> SemanticsContext {
        let sourceFile = try SourceFileSyntax.parse(witSource, fileName: "test.wit")
        let resolver = PackageResolver()
        let pkg = try resolver.register(packageSources: [sourceFile])
        return SemanticsContext(rootPackage: pkg, packageResolver: resolver)
    }

    /// Encode a world and return the raw bytes.
    private func encode(
        _ witSource: String,
        worldName: String,
        encodingVersion: UInt32 = 4
    ) throws -> [UInt8] {
        let ctx = try buildContext(witSource)
        return try ComponentTypeSerializer.encodeComponentType(
            context: ctx, worldName: worldName, encodingVersion: encodingVersion
        )
    }

    /// Parse serializer output through ComponentParser, returning all payloads.
    private func parseOutput(_ bytes: [UInt8]) throws -> [ComponentParsingPayload] {
        var parser = ComponentParser(bytes: bytes)
        var payloads: [ComponentParsingPayload] = []
        while let payload = try parser.parseNext() {
            payloads.append(payload)
        }
        return payloads
    }

    /// Extract the type section's [ComponentTypeDef] from parsed payloads.
    private func typeSection(from payloads: [ComponentParsingPayload]) -> [ComponentTypeDef]? {
        for payload in payloads {
            if case .typeSection(let types) = payload {
                return types
            }
        }
        return nil
    }

    /// Extract the export section's [ComponentExportDef] from parsed payloads.
    private func exportSection(from payloads: [ComponentParsingPayload]) -> [ComponentExportDef]? {
        for payload in payloads {
            if case .exportSection(let exports) = payload {
                return exports
            }
        }
        return nil
    }

    /// Extract custom sections from parsed payloads.
    private func customSections(from payloads: [ComponentParsingPayload]) -> [CustomSection] {
        payloads.compactMap {
            if case .customSection(let cs) = $0 { return cs }
            return nil
        }
    }

    /// Navigate to the inner componenttype declarations (the world's body).
    /// Path: typeSection[0] → outer componenttype → decl[0] (type) → inner componenttype → declarations
    private func innerWorldDecls(from payloads: [ComponentParsingPayload]) throws -> [ComponentOrInstanceDecl] {
        let types = try #require(typeSection(from: payloads))
        #expect(types.count >= 1)
        guard case .component(let outerDecl) = types[0] else {
            Issue.record("Expected outer componenttype, got \(types[0])")
            return []
        }
        #expect(outerDecl.declarations.count >= 1)
        guard case .instanceDecl(.type(.component(let innerDecl))) = outerDecl.declarations[0] else {
            Issue.record("Expected inner componenttype in outer decl[0], got \(outerDecl.declarations[0])")
            return []
        }
        return innerDecl.declarations
    }

    /// Extract instance decls from ComponentOrInstanceDecl array.
    private func instanceDecls(_ decls: [ComponentOrInstanceDecl]) -> [InstanceDecl] {
        decls.compactMap {
            if case .instanceDecl(let d) = $0 { return d }
            return nil
        }
    }

    /// Extract import decls from ComponentOrInstanceDecl array.
    private func importDecls(_ decls: [ComponentOrInstanceDecl]) -> [ComponentImportDecl] {
        decls.compactMap {
            if case .importDecl(let d) = $0 { return d }
            return nil
        }
    }

    /// Read an unsigned LEB128 value from bytes at the given offset.
    private func readLEB128(_ bytes: [UInt8], offset: Int) -> (value: Int, consumed: Int) {
        var result = 0
        var shift = 0
        var pos = offset
        while pos < bytes.count {
            let byte = bytes[pos]
            result |= Int(byte & 0x7F) << shift
            pos += 1
            if byte & 0x80 == 0 { break }
            shift += 7
        }
        return (result, pos - offset)
    }

    /// Read a name (LEB128 length + UTF-8 bytes) from position in bytes.
    private func readName(_ bytes: [UInt8], offset: Int) -> (name: String, consumed: Int) {
        let (len, lenBytes) = readLEB128(bytes, offset: offset)
        let start = offset + lenBytes
        let name = String(bytes: bytes[start..<start + len], encoding: .utf8) ?? ""
        return (name, lenBytes + len)
    }

    /// Find a section by ID in component binary bytes (after the 8-byte header).
    private func findSection(id: UInt8, in bytes: [UInt8]) -> (offset: Int, size: Int, contentStart: Int)? {
        var pos = 8  // skip header
        while pos < bytes.count {
            let sectionId = bytes[pos]
            pos += 1
            let (size, consumed) = readLEB128(bytes, offset: pos)
            pos += consumed
            let contentStart = pos
            if sectionId == id {
                return (offset: contentStart - consumed - 1, size: size, contentStart: contentStart)
            }
            pos += size
        }
        return nil
    }

    // MARK: - Basic structure tests

    @Test func emptyWorldStructure() throws {
        let bytes = try encode("""
            package test:pkg
            world empty {}
            """, worldName: "empty")

        let payloads = try parseOutput(bytes)

        // Should have header, custom section, type section, export section
        #expect(payloads.count == 4)

        let customs = customSections(from: payloads)
        #expect(customs.count == 1)
        #expect(typeSection(from: payloads) != nil)
        #expect(exportSection(from: payloads) != nil)

        // Inner componenttype should have 0 declarations
        let decls = try innerWorldDecls(from: payloads)
        #expect(decls.isEmpty)
    }

    @Test func witComponentEncodingCustomSection() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {}
            """, worldName: "my-world", encodingVersion: 4)

        let payloads = try parseOutput(bytes)
        let customs = customSections(from: payloads)
        #expect(customs.count == 1)
        #expect(customs[0].name == "wit-component-encoding")

        // Verify encoding version by reading the payload bytes
        let payload = Array(customs[0].bytes)
        let (version, _) = readLEB128(payload, offset: 0)
        #expect(version == 4)
    }

    @Test func exportSectionContainsWorldName() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {}
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let exports = try #require(exportSection(from: payloads))
        #expect(exports.count == 1)
        #expect(exports[0].name == "my-world")
        if case .type = exports[0].sort {} else {
            Issue.record("Expected type sort, got \(exports[0].sort)")
        }
        #expect(exports[0].index == 0)
    }

    @Test func worldNotFoundError() throws {
        let ctx = try buildContext("""
            package test:pkg
            world my-world {}
            """)
        #expect(throws: ComponentTypeSerializer.Error.worldNotFound("nonexistent")) {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "nonexistent"
            )
        }
    }

    // MARK: - Type section structure tests

    @Test func typeSectionContainsOuterComponentType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {}
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let types = try #require(typeSection(from: payloads))
        #expect(types.count == 1)

        // Outer should be a componenttype with 2 declarations
        guard case .component(let outerDecl) = types[0] else {
            Issue.record("Expected componenttype"); return
        }
        #expect(outerDecl.declarations.count == 2)
    }

    // MARK: - Function export tests

    @Test func worldWithExportedFunction() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export do-stuff: func(name: string) -> string
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // 2 decls: functype + export
        #expect(decls.count == 2)

        // Decl 0: type → functype
        let iDecls = instanceDecls(decls)
        let typeDecls = iDecls.compactMap { d -> ComponentFuncType? in
            if case .type(.function(let ft)) = d { return ft }
            return nil
        }
        #expect(typeDecls.count == 1)
        let ft = typeDecls[0]
        #expect(ft.params.count == 1)
        #expect(ft.params[0].name == "name")
        #expect(ft.params[0].type == .string)
        #expect(ft.result == .string)

        // Decl 1: export → "do-stuff" → function(0)
        let exportDecls = iDecls.compactMap { d -> ComponentExportDecl? in
            if case .exportDecl(let e) = d { return e }
            return nil
        }
        #expect(exportDecls.count == 1)
        #expect(exportDecls[0].name == "do-stuff")
        if case .function(let typeIdx) = exportDecls[0].externDesc {
            #expect(typeIdx == 0)
        } else {
            Issue.record("Expected function extern desc")
        }
    }

    @Test func worldWithImportedFunction() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                import greet: func(name: string) -> string
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // 2 decls: functype + import
        #expect(decls.count == 2)

        // Should have an import decl
        let imports = importDecls(decls)
        #expect(imports.count == 1)
        #expect(imports[0].name == "greet")
        if case .function(let typeIdx) = imports[0].externDesc {
            #expect(typeIdx == 0)
        } else {
            Issue.record("Expected function extern desc")
        }
    }

    @Test func worldWithVoidFunction() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export noop: func()
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        let iDecls = instanceDecls(decls)
        let funcTypes = iDecls.compactMap { d -> ComponentFuncType? in
            if case .type(.function(let ft)) = d { return ft }
            return nil
        }
        #expect(funcTypes.count == 1)
        #expect(funcTypes[0].params.isEmpty)
        #expect(funcTypes[0].result == nil, "void function should have nil result")
    }

    // MARK: - Interface import/export tests

    @Test func worldWithInlineInterface() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    do-stuff: func(x: u32) -> u32
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // 2 decls: instancetype + export
        #expect(decls.count == 2)

        let iDecls = instanceDecls(decls)

        // Find the instancetype
        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        #expect(instanceTypes.count == 1)
        let it = instanceTypes[0]
        // Instance should have 2 decls: functype + export
        #expect(it.declarations.count == 2)

        // Verify the functype inside the instance
        if case .type(.function(let ft)) = it.declarations[0] {
            #expect(ft.params.count == 1)
            #expect(ft.params[0].name == "x")
            #expect(ft.params[0].type == .u32)
            #expect(ft.result == .u32)
        } else {
            Issue.record("Expected functype in instance decl[0]")
        }

        // Verify the export name
        if case .exportDecl(let e) = it.declarations[1] {
            #expect(e.name == "do-stuff")
        } else {
            Issue.record("Expected export decl in instance decl[1]")
        }

        // Verify outer export name
        let exports = iDecls.compactMap { d -> ComponentExportDecl? in
            if case .exportDecl(let e) = d { return e }
            return nil
        }
        #expect(exports.count == 1)
        #expect(exports[0].name == "my-iface")
    }

    @Test func worldWithNamedInterfaceImport() throws {
        let bytes = try encode("""
            package test:pkg
            interface my-iface {
                do-stuff: func(x: u32) -> string
            }
            world my-world {
                import my-iface
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // Should have import with FQ name
        let imports = importDecls(decls)
        #expect(imports.count == 1)
        #expect(imports[0].name == "test:pkg/my-iface")
        if case .instance(let typeIdx) = imports[0].externDesc {
            #expect(typeIdx == 0)
        } else {
            Issue.record("Expected instance extern desc, got \(imports[0].externDesc)")
        }
    }

    @Test func worldWithNamedInterfaceExport() throws {
        let bytes = try encode("""
            package test:pkg
            interface my-iface {
                do-stuff: func(x: u32) -> string
            }
            world my-world {
                export my-iface
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        let iDecls = instanceDecls(decls)
        let exports = iDecls.compactMap { d -> ComponentExportDecl? in
            if case .exportDecl(let e) = d { return e }
            return nil
        }
        #expect(exports.count == 1)
        #expect(exports[0].name == "test:pkg/my-iface")
        if case .instance(let typeIdx) = exports[0].externDesc {
            #expect(typeIdx == 0)
        } else {
            Issue.record("Expected instance extern desc, got \(exports[0].externDesc)")
        }
    }

    // MARK: - Composite type tests

    @Test func interfaceWithRecordType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    record point {
                        x: s32,
                        y: s32,
                    }
                    get-origin: func() -> point
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        // Find instancetype
        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        // Find record type def
        var records: [ComponentValueType] = []
        for d in it.declarations {
            if case .type(.definedValue(let vt)) = d {
                if case .record = vt { records.append(vt) }
            }
        }
        #expect(records.count == 1)
        guard case .record(let fields) = records[0] else {
            Issue.record("Expected record"); return
        }
        #expect(fields.count == 2)
        #expect(fields[0].name == "x")
        #expect(fields[1].name == "y")
        // Field types are read as type indices by the parser since they're
        // encoded as primitive opcodes (s32 = 0x7A = 122 as unsigned LEB128)
        #expect(fields[0].type.rawValue == Int(0x7A))
        #expect(fields[1].type.rawValue == Int(0x7A))
    }

    @Test func interfaceWithEnumType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    enum color {
                        red,
                        green,
                        blue,
                    }
                    get-color: func() -> color
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        // Find enum type def
        for d in it.declarations {
            if case .type(.definedValue(let vt)) = d {
                if case .enum(let labels) = vt {
                    #expect(labels == ["red", "green", "blue"])
                    return
                }
            }
        }
        Issue.record("No enum type def found in instance declarations")
    }

    @Test func interfaceWithFlagsType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    flags permissions {
                        read,
                        write,
                        execute,
                    }
                    check-perms: func() -> permissions
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        for d in it.declarations {
            if case .type(.definedValue(let vt)) = d {
                if case .flags(let labels) = vt {
                    #expect(labels == ["read", "write", "execute"])
                    return
                }
            }
        }
        Issue.record("No flags type def found in instance declarations")
    }

    @Test func interfaceWithVariantType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    variant filter {
                        all,
                        none,
                        some(string),
                    }
                    apply-filter: func(f: filter) -> string
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        for d in it.declarations {
            if case .type(.definedValue(let vt)) = d {
                if case .variant(let cases) = vt {
                    #expect(cases.count == 3)
                    #expect(cases[0].name == "all")
                    #expect(cases[0].type == nil)
                    #expect(cases[1].name == "none")
                    #expect(cases[1].type == nil)
                    #expect(cases[2].name == "some")
                    #expect(cases[2].type != nil, "some should have a payload type")
                    return
                }
            }
        }
        Issue.record("No variant type def found in instance declarations")
    }

    // MARK: - Inline composite valtype tests (byte-level)
    //
    // The parser's parseValType in functype params only handles primitives and
    // type indices, not inline composite types. These tests verify the serializer
    // produces the correct bytes for inline composites using targeted byte checks.

    @Test func functionWithListParam() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export sum: func(values: list<u32>) -> u32
            }
            """, worldName: "my-world")

        // Verify structure via section presence
        #expect(findSection(id: 0x07, in: bytes) != nil)

        // Verify the functype contains: list opcode (0x70) followed by u32 opcode (0x79)
        let listU32Sequence: [UInt8] = [0x70, 0x79]
        #expect(containsSubsequence(bytes, listU32Sequence),
            "Should contain list<u32> encoding (0x70, 0x79)")
    }

    @Test func functionWithOptionParam() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export maybe-greet: func(name: option<string>) -> string
            }
            """, worldName: "my-world")

        #expect(findSection(id: 0x07, in: bytes) != nil)

        // option opcode (0x6B) followed by string opcode (0x73)
        let optionStringSequence: [UInt8] = [0x6B, 0x73]
        #expect(containsSubsequence(bytes, optionStringSequence),
            "Should contain option<string> encoding (0x6B, 0x73)")
    }

    @Test func functionWithResultParam() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export try-parse: func(input: string) -> result<u32, string>
            }
            """, worldName: "my-world")

        #expect(findSection(id: 0x07, in: bytes) != nil)

        // result opcode (0x6A) + ok present (0x01) + u32 (0x79) + err present (0x01) + string (0x73)
        let resultSequence: [UInt8] = [0x6A, 0x01, 0x79, 0x01, 0x73]
        #expect(containsSubsequence(bytes, resultSequence),
            "Should contain result<u32, string> encoding")
    }

    @Test func functionWithTupleParam() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export swap: func(pair: tuple<u32, u64>) -> tuple<u64, u32>
            }
            """, worldName: "my-world")

        #expect(findSection(id: 0x07, in: bytes) != nil)

        // tuple opcode (0x6F) + count(2) + u32(0x79) + u64(0x77)
        let tupleSequence: [UInt8] = [0x6F, 0x02, 0x79, 0x77]
        #expect(containsSubsequence(bytes, tupleSequence),
            "Should contain tuple<u32, u64> encoding")
    }

    /// Check if `bytes` contains the given subsequence.
    private func containsSubsequence(_ bytes: [UInt8], _ sub: [UInt8]) -> Bool {
        guard sub.count <= bytes.count else { return false }
        for i in 0...(bytes.count - sub.count) {
            if bytes[i..<(i + sub.count)].elementsEqual(sub) {
                return true
            }
        }
        return false
    }

    // MARK: - Multiple imports and exports

    @Test func worldWithMultipleExterns() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                import log: func(msg: string)
                export greet: func(name: string) -> string
                export add: func(a: u32, b: u32) -> u32
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // 6 decls: 3 functions × 2 (type + import/export)
        #expect(decls.count == 6)

        let imports = importDecls(decls)
        #expect(imports.count == 1)
        #expect(imports[0].name == "log")

        let iDecls = instanceDecls(decls)
        let exports = iDecls.compactMap { d -> ComponentExportDecl? in
            if case .exportDecl(let e) = d { return e }
            return nil
        }
        #expect(exports.count == 2)
        #expect(exports[0].name == "greet")
        #expect(exports[1].name == "add")
    }

    // MARK: - Fully-qualified name tests

    @Test func outerComponentTypeExportsFullyQualifiedName() throws {
        let bytes = try encode("""
            package myns:mypkg
            world my-world {
                export greet: func(name: string) -> string
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let types = try #require(typeSection(from: payloads))
        guard case .component(let outerDecl) = types[0] else {
            Issue.record("Expected outer componenttype"); return
        }

        // Decl 1 should be export with FQ name
        #expect(outerDecl.declarations.count == 2)
        guard case .instanceDecl(.exportDecl(let exportDecl)) = outerDecl.declarations[1] else {
            Issue.record("Expected export decl in outer[1], got \(outerDecl.declarations[1])")
            return
        }
        #expect(exportDecl.name == "myns:mypkg/my-world")
        if case .component(let typeIdx) = exportDecl.externDesc {
            #expect(typeIdx == 0)
        } else {
            Issue.record("Expected component extern desc, got \(exportDecl.externDesc)")
        }
    }

    // MARK: - All primitive types

    @Test func allPrimitiveTypes() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export test-bool: func(v: bool) -> bool
                export test-u8: func(v: u8) -> u8
                export test-u16: func(v: u16) -> u16
                export test-u32: func(v: u32) -> u32
                export test-u64: func(v: u64) -> u64
                export test-s8: func(v: s8) -> s8
                export test-s16: func(v: s16) -> s16
                export test-s32: func(v: s32) -> s32
                export test-s64: func(v: s64) -> s64
                export test-f32: func(v: float32) -> float32
                export test-f64: func(v: float64) -> float64
                export test-char: func(v: char) -> char
                export test-string: func(v: string) -> string
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)

        // Extract all functypes
        let iDecls = instanceDecls(decls)
        let funcTypes = iDecls.compactMap { d -> ComponentFuncType? in
            if case .type(.function(let ft)) = d { return ft }
            return nil
        }
        #expect(funcTypes.count == 13)

        // Each function has 1 param and 1 result, both the same primitive type
        let expectedTypes: [ComponentValueType] = [
            .bool, .u8, .u16, .u32, .u64, .s8, .s16, .s32, .s64,
            .float32, .float64, .char, .string,
        ]
        for (i, expected) in expectedTypes.enumerated() {
            #expect(funcTypes[i].params.count == 1)
            #expect(funcTypes[i].params[0].name == "v")
            #expect(funcTypes[i].params[0].type == expected,
                "Function \(i) param type should be \(expected), got \(funcTypes[i].params[0].type)")
            #expect(funcTypes[i].result == expected,
                "Function \(i) result should be \(expected), got \(String(describing: funcTypes[i].result))")
        }
    }

    // MARK: - Named type reference within interface

    @Test func interfaceTypeReferenceInFunction() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    record point {
                        x: s32,
                        y: s32,
                    }
                    record line {
                        start: point,
                        end: point,
                    }
                    get-line: func() -> line
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        // Collect type defs in order
        var typeDefs: [ComponentValueType] = []
        for d in it.declarations {
            if case .type(.definedValue(let vt)) = d { typeDefs.append(vt) }
        }
        #expect(typeDefs.count == 2, "Should have point and line records")

        // Type 0 = point (exported as type index 0 after the export decl)
        guard case .record(let pointFields) = typeDefs[0] else {
            Issue.record("Expected point record"); return
        }
        #expect(pointFields.count == 2)

        // Type 1 = line, fields reference point by index 0
        guard case .record(let lineFields) = typeDefs[1] else {
            Issue.record("Expected line record"); return
        }
        #expect(lineFields.count == 2)
        #expect(lineFields[0].name == "start")
        #expect(lineFields[1].name == "end")
        // point is type index 0 in this instancetype
        #expect(lineFields[0].type.rawValue == 0)
        #expect(lineFields[1].type.rawValue == 0)
    }

    // MARK: - Encoding version

    @Test func customEncodingVersion() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {}
            """, worldName: "my-world", encodingVersion: 5)

        let payloads = try parseOutput(bytes)
        let customs = customSections(from: payloads)
        #expect(customs[0].name == "wit-component-encoding")

        let payload = Array(customs[0].bytes)
        let (version, _) = readLEB128(payload, offset: 0)
        #expect(version == 5)
    }

    // MARK: - Error path tests

    @Test func useInInterfaceThrows() throws {
        // This would require an actual `use` in an interface. We construct WIT
        // with a use item to verify the serializer rejects it.
        let ctx = try buildContext("""
            package test:pkg
            interface types {
                type my-id = u32
            }
            interface consumer {
                use types.{my-id}
                get-id: func() -> my-id
            }
            world my-world {
                export consumer
            }
            """)
        #expect(throws: ComponentTypeSerializer.Error.unsupportedFeature("use in interface")) {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "my-world"
            )
        }
    }

    @Test func useInWorldThrows() throws {
        let ctx = try buildContext("""
            package test:pkg
            interface types {
                type my-id = u32
            }
            world my-world {
                use types.{my-id}
            }
            """)
        #expect(throws: ComponentTypeSerializer.Error.unsupportedFeature("use in world")) {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "my-world"
            )
        }
    }

    @Test func includeInWorldThrows() throws {
        let ctx = try buildContext("""
            package test:pkg
            world base {
                export log: func(msg: string)
            }
            world my-world {
                include base
            }
            """)
        #expect(throws: ComponentTypeSerializer.Error.unsupportedFeature("include in world")) {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "my-world"
            )
        }
    }

    @Test func resourceTypeThrows() throws {
        let ctx = try buildContext("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    resource blob {
                        constructor(data: list<u8>)
                    }
                }
            }
            """)
        #expect {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "my-world"
            )
        } throws: { error in
            guard let e = error as? ComponentTypeSerializer.Error else { return false }
            if case .unsupportedFeature(let msg) = e {
                return msg.contains("resource")
            }
            return false
        }
    }

    @Test func crossPackageReferenceThrows() throws {
        // This tests that a reference to another package's interface fails.
        // We can't actually register a second package, but we can create WIT
        // that references a different package namespace.
        let ctx = try buildContext("""
            package test:pkg
            world my-world {
                import other:stuff/something
            }
            """)
        #expect {
            try ComponentTypeSerializer.encodeComponentType(
                context: ctx, worldName: "my-world"
            )
        } throws: { error in
            guard let e = error as? ComponentTypeSerializer.Error else { return false }
            if case .unsupportedFeature(let msg) = e {
                return msg.contains("cross-package")
            }
            return false
        }
    }

    // MARK: - Type index correctness

    @Test func typeIndexOrderingInInterface() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export my-iface: interface {
                    record point {
                        x: s32,
                        y: s32,
                    }
                    enum color {
                        red,
                        green,
                        blue,
                    }
                    flags perms {
                        read,
                        write,
                    }
                    get-point: func() -> point
                    get-color: func() -> color
                }
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        let it = try #require(instanceTypes.first)

        // Collect declarations in order
        var typeDefIndices: [Int] = []  // track type index assignment
        var exportDecls: [ComponentExportDecl] = []
        var funcTypesByIndex: [Int: ComponentFuncType] = [:]
        var typeIndex = 0

        for d in it.declarations {
            switch d {
            case .type(let td):
                typeDefIndices.append(typeIndex)
                if case .function(let ft) = td {
                    funcTypesByIndex[typeIndex] = ft
                }
                typeIndex += 1
            case .exportDecl(let e):
                exportDecls.append(e)
            default: break
            }
        }

        // Should have 5 type defs (point, color, perms, get-point functype, get-color functype)
        // and 5 exports (point, color, perms, get-point, get-color)
        #expect(typeDefIndices.count == 5)
        #expect(exportDecls.count == 5)

        // Export type indices should match: type defs at 0,1,2 + funcs at 3,4
        // Export "point" → type(eq 0), "color" → type(eq 1), "perms" → type(eq 2)
        // Export "get-point" → function(3), "get-color" → function(4)
        #expect(exportDecls[0].name == "point")
        #expect(exportDecls[1].name == "color")
        #expect(exportDecls[2].name == "perms")
        #expect(exportDecls[3].name == "get-point")
        #expect(exportDecls[4].name == "get-color")

        // Verify get-point returns type index 0 (point)
        if let ft = funcTypesByIndex[3] {
            // The result references point which is type 0; but since point is a
            // named type, the serializer writes its index (0) as a type reference
            if case .indexed(let idx) = ft.result {
                #expect(idx.rawValue == 0, "get-point should return type 0 (point)")
            } else {
                Issue.record("Expected indexed result for get-point, got \(String(describing: ft.result))")
            }
        }

        // Verify get-color returns type index 1 (color)
        if let ft = funcTypesByIndex[4] {
            if case .indexed(let idx) = ft.result {
                #expect(idx.rawValue == 1, "get-color should return type 1 (color)")
            } else {
                Issue.record("Expected indexed result for get-color, got \(String(describing: ft.result))")
            }
        }
    }

    @Test func worldLevelTypeDefinition() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                type my-id = u32
                export get-id: func() -> my-id
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        // Should have: type def + type export(eq) + functype + func export = 4 decls
        #expect(decls.count == 4)

        // First should be a type def (the alias u32 → just writes u32 primitive)
        if case .type(.definedValue(let vt)) = iDecls[0] {
            #expect(vt == .u32, "type my-id = u32 should produce u32 defined value")
        } else {
            Issue.record("Expected defined value type for my-id, got \(iDecls[0])")
        }

        // Second should be export "my-id" with type(eq 0)
        if case .exportDecl(let e) = iDecls[1] {
            #expect(e.name == "my-id")
            if case .type(let bound) = e.externDesc {
                if case .eq(let idx) = bound {
                    #expect(idx == 0, "my-id export should reference type index 0")
                } else {
                    Issue.record("Expected eq bound")
                }
            } else {
                Issue.record("Expected type extern desc")
            }
        } else {
            Issue.record("Expected export decl for my-id")
        }
    }

    // MARK: - Structural edge cases

    @Test func emptyInterface() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export empty: interface {}
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        // Find instancetype
        var instanceTypes: [InstanceTypeDecl] = []
        for d in iDecls {
            if case .type(.instance(let it)) = d { instanceTypes.append(it) }
        }
        #expect(instanceTypes.count == 1)
        #expect(instanceTypes[0].declarations.isEmpty, "Empty interface should have 0 declarations")
    }

    @Test func multipleWorldsSelectsCorrect() throws {
        let wit = """
            package test:pkg
            world alpha {
                export greet: func() -> string
            }
            world beta {
                export count: func() -> u32
            }
            """

        // Encode alpha
        let alphaBytes = try encode(wit, worldName: "alpha")
        let alphaPayloads = try parseOutput(alphaBytes)
        let alphaExports = try #require(exportSection(from: alphaPayloads))
        #expect(alphaExports[0].name == "alpha")

        let alphaTypes = try #require(typeSection(from: alphaPayloads))
        guard case .component(let alphaOuter) = alphaTypes[0] else {
            Issue.record("Expected componenttype"); return
        }
        guard case .instanceDecl(.exportDecl(let alphaExportDecl)) = alphaOuter.declarations[1] else {
            Issue.record("Expected export decl"); return
        }
        #expect(alphaExportDecl.name == "test:pkg/alpha")

        // Encode beta
        let betaBytes = try encode(wit, worldName: "beta")
        let betaPayloads = try parseOutput(betaBytes)
        let betaExports = try #require(exportSection(from: betaPayloads))
        #expect(betaExports[0].name == "beta")

        let betaTypes = try #require(typeSection(from: betaPayloads))
        guard case .component(let betaOuter) = betaTypes[0] else {
            Issue.record("Expected componenttype"); return
        }
        guard case .instanceDecl(.exportDecl(let betaExportDecl)) = betaOuter.declarations[1] else {
            Issue.record("Expected export decl"); return
        }
        #expect(betaExportDecl.name == "test:pkg/beta")
    }

    @Test func deeplyNestedCompositeType() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export deep: func(v: list<option<result<u32, string>>>)
            }
            """, worldName: "my-world")

        // Verify the nested type encoding at byte level:
        // list(0x70) option(0x6B) result(0x6A) ok-present(0x01) u32(0x79) err-present(0x01) string(0x73)
        let nestedSequence: [UInt8] = [0x70, 0x6B, 0x6A, 0x01, 0x79, 0x01, 0x73]
        #expect(containsSubsequence(bytes, nestedSequence),
            "Should contain list<option<result<u32, string>>> encoding")
    }

    @Test func namedFunctionResults() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export get-pair: func() -> (x: u32, y: u32)
            }
            """, worldName: "my-world")

        // Named results encode as: 0x01 (named marker) count name valtype ...
        // The parser doesn't fully handle named results with count > 0,
        // so verify at byte level.
        // 0x01 (named) 0x02 (2 results) then "x" + u32 + "y" + u32
        let namedResultPrefix: [UInt8] = [0x01, 0x02]
        #expect(containsSubsequence(bytes, namedResultPrefix),
            "Should contain named result marker with count 2")

        // Also check the result names appear
        let xNameBytes = Array("x".utf8)
        let yNameBytes = Array("y".utf8)
        #expect(containsSubsequence(bytes, [0x01] + xNameBytes), "Should contain result name 'x'")
        #expect(containsSubsequence(bytes, [0x01] + yNameBytes), "Should contain result name 'y'")
    }

    @Test func functionMultipleParams() throws {
        let bytes = try encode("""
            package test:pkg
            world my-world {
                export multi: func(a: u32, b: string, c: bool) -> u64
            }
            """, worldName: "my-world")

        let payloads = try parseOutput(bytes)
        let decls = try innerWorldDecls(from: payloads)
        let iDecls = instanceDecls(decls)

        let funcTypes = iDecls.compactMap { d -> ComponentFuncType? in
            if case .type(.function(let ft)) = d { return ft }
            return nil
        }
        #expect(funcTypes.count == 1)
        let ft = funcTypes[0]
        #expect(ft.params.count == 3)
        #expect(ft.params[0].name == "a")
        #expect(ft.params[0].type == .u32)
        #expect(ft.params[1].name == "b")
        #expect(ft.params[1].type == .string)
        #expect(ft.params[2].name == "c")
        #expect(ft.params[2].type == .bool)
        #expect(ft.result == .u64)
    }
}

#endif
