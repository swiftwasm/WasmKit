import Testing
import WAT
import WasmParser
import WasmTypes

@Suite struct GCTypeEncodingTests {
    private func typeSection(_ wat: String) throws -> [UInt8]? {
        try TestSupport.section(1, in: wat2wasm(wat))
    }

    private func nameSubsection(_ id: UInt8, in wasm: [UInt8]) throws -> [UInt8]? {
        let nameHeader: [UInt8] = [0x04] + Array("name".utf8)
        guard let custom = try TestSupport.section(0, in: wasm), custom.starts(with: nameHeader) else { return nil }
        return try TestSupport.section(id, in: custom, from: nameHeader.count)
    }

    @Test func singletonRecKeepsWrapper() throws {
        #expect(try typeSection("(module (rec (type $t (func))))") == [0x01, 0x4E, 0x01, 0x60, 0x00, 0x00])
    }

    @Test func plainTypeStaysBare() throws {
        #expect(try typeSection("(module (type $t (func)))") == [0x01, 0x60, 0x00, 0x00])
    }

    @Test func encodesEmptyRecGroup() throws {
        #expect(try typeSection("(module (rec))") == [0x01, 0x4E, 0x00])
    }

    @Test func recMembersAreBare() throws {
        #expect(
            try typeSection("(module (rec (type $a (struct (field i32))) (type $b (array (mut i64)))))")
                == [0x01, 0x4E, 0x02, 0x5F, 0x01, 0x7F, 0x00, 0x5E, 0x7E, 0x01])
    }

    @Test func singletonRecDoesNotSeedDedup() throws {
        let types = try typeSection("(module (rec (type $ft (func))) (func $f) (global (ref $ft) (ref.func $f)))")
        #expect(types == [0x02, 0x4E, 0x01, 0x60, 0x00, 0x00, 0x60, 0x00, 0x00])
    }

    @Test func encodesNoExnAs0x74() throws {
        let wasm = try wat2wasm("(module (global $b nullexnref (ref.null noexn)))")
        #expect(try TestSupport.section(6, in: wasm) == [0x01, 0x74, 0x00, 0xD0, 0x74, 0x0B])
    }

    @Test func implicitTypeUseReusesNonFinalSubOutsideRec() throws {
        let sub = try wat2wasm("(module (type (sub (func))) (func))")
        #expect(try TestSupport.section(1, in: sub) == [0x01, 0x50, 0x00, 0x60, 0x00, 0x00])
        #expect(try TestSupport.section(3, in: sub) == [0x01, 0x00])

        let rec = try wat2wasm("(module (rec (type (func))) (func))")
        #expect(try TestSupport.section(1, in: rec) == [0x02, 0x4E, 0x01, 0x60, 0x00, 0x00, 0x60, 0x00, 0x00])
        #expect(try TestSupport.section(3, in: rec) == [0x01, 0x01])
    }

    @Test func subFinalWithoutSupertypesIsBare() throws {
        #expect(try typeSection("(module (type (sub final (func))))") == [0x01, 0x60, 0x00, 0x00])
    }

    @Test func encodesStructArrayAndSupertypes() throws {
        #expect(
            try typeSection("(module (type (struct (field i32 i64) (field (mut i8)) (field))))")
                == [0x01, 0x5F, 0x03, 0x7F, 0x00, 0x7E, 0x00, 0x78, 0x01])
        #expect(try typeSection("(module (type (array (mut i16))))") == [0x01, 0x5E, 0x77, 0x01])
        #expect(
            try typeSection("(module (type $a (sub (struct))) (type $b (sub final $a (struct))))")
                == [0x02, 0x50, 0x00, 0x5F, 0x00, 0x4F, 0x01, 0x00, 0x5F, 0x00])
        #expect(
            try typeSection("(module (type $a (sub (struct))) (type $b (sub (struct))) (type (sub $a $b (struct))))")
                == [0x03, 0x50, 0x00, 0x5F, 0x00, 0x50, 0x00, 0x5F, 0x00, 0x50, 0x02, 0x00, 0x01, 0x5F, 0x00])
    }

    @Test func encodesGCReferenceTypes() throws {
        #expect(
            try typeSection(
                """
                (module (type (func (param anyref eqref i31ref structref arrayref
                                           nullref nullfuncref nullexternref nullexnref))))
                """)
                == [0x01, 0x60, 0x09, 0x6E, 0x6D, 0x6C, 0x6B, 0x6A, 0x71, 0x73, 0x72, 0x74, 0x00])
        #expect(
            try typeSection("(module (type $t (func)) (type (func (param (ref any) (ref null any) (ref $t) (ref null $t)))))")
                == [
                    0x02,
                    0x60, 0x00, 0x00,
                    0x60, 0x04, 0x64, 0x6E, 0x6E, 0x64, 0x00, 0x63, 0x00, 0x00,
                ])
    }

    @Test(
        arguments: [
            ("any", 0x6E), ("eq", 0x6D), ("i31", 0x6C), ("struct", 0x6B), ("array", 0x6A),
            ("none", 0x71), ("noextern", 0x72), ("nofunc", 0x73), ("noexn", 0x74),
        ] as [(String, UInt8)])
    func encodesRefNullWithGCHeapType(keyword: String, byte: UInt8) throws {
        let wasm = try wat2wasm("(module (func (drop (ref.null \(keyword)))))")
        #expect(try TestSupport.section(10, in: wasm) == [0x01, 0x05, 0x00, 0xD0, byte, 0x1A, 0x0B])
    }

    @Test func encodesFieldNamesSubsection() throws {
        let wasm = try wat2wasm(
            """
            (module
              (type $p (struct (field $x i32) (field i64) (field $y (mut f32)) (field $z i8)))
              (type (struct))
              (type $q (struct (field $a anyref))))
            """, options: EncodeOptions(nameSection: true))
        #expect(
            try TestSupport.section(1, in: wasm) == [
                0x03,
                0x5F, 0x04, 0x7F, 0x00, 0x7E, 0x00, 0x7D, 0x01, 0x78, 0x00,
                0x5F, 0x00,
                0x5F, 0x01, 0x6E, 0x00,
            ])
        #expect(
            try nameSubsection(10, in: wasm) == [
                0x02,
                0x00, 0x03, 0x00, 0x01, 0x78, 0x02, 0x01, 0x79, 0x03, 0x01, 0x7A,  // type 0: x, y, z
                0x02, 0x01, 0x00, 0x01, 0x61,  // type 2: a
            ])
    }

    @Test func resolvesForwardReferencesInsideAndAcrossRecGroups() throws {
        #expect(
            try typeSection("(module (rec (type $a (struct (field (ref null $b)))) (type $b (struct (field (ref null $a))))))")
                == [0x01, 0x4E, 0x02, 0x5F, 0x01, 0x63, 0x01, 0x00, 0x5F, 0x01, 0x63, 0x00, 0x00])
        #expect(
            try typeSection("(module (type $a (struct (field (ref null $b)))) (type $b (struct (field (ref null $a)))))")
                == [0x02, 0x5F, 0x01, 0x63, 0x01, 0x00, 0x5F, 0x01, 0x63, 0x00, 0x00])
    }

    @Test(arguments: [
        "(module (type $s (struct)) (func (type $s)))",
        "(module (type $s (struct)) (func (type $s) (param i32)))",
        "(module (type $s (array i8)) (import \"m\" \"f\" (func (type $s))))",
        "(module (type $s (struct)) (tag (type $s)))",
        "(module (type $s (struct)) (table 1 funcref) (func (call_indirect (type $s) (i32.const 0))))",
        "(module (type $s (struct)) (func (block (type $s))))",
    ])
    func rejectsFunctionTypeUseOfAggregate(wat: String) {
        #expect(TestSupport.errorMessage { _ = try wat2wasm(wat) } == "type index 0 is not a function type")
    }

    @Test func reportsMalformedTypeText() {
        #expect(TestSupport.errorMessage { _ = try wat2wasm("(module (type (sub (foo))))") } == "expected func, struct or array")
        #expect(TestSupport.errorMessage { _ = try wat2wasm("(module (func (param (ref foo))))") } == "expected heap type")
        #expect(TestSupport.errorMessage { _ = try wat2wasm("(module (func (drop (ref.null foo))))") } == "expected heap type")
    }

    @Test func rejectsDuplicateFieldName() {
        let message = TestSupport.errorMessage { _ = try wat2wasm("(module (type (struct (field $x i32) (field $x i64))))") }
        #expect(message == "duplicate field $x")
    }

    @Test func roundTripsThroughDecoder() throws {
        let wasm = try wat2wasm(
            """
            (module
              (rec
                (type $a (sub (struct (field $x i32) (field (mut i8)))))
                (type $b (array (mut i16))))
              (type $c (sub final $a (struct (field i32) (field (mut i8)) (field (ref null $b))))))
            """)
        #expect(
            try TestSupport.section(1, in: wasm) == [
                0x02,
                0x4E, 0x02,
                0x50, 0x00, 0x5F, 0x02, 0x7F, 0x00, 0x78, 0x01,
                0x5E, 0x77, 0x01,
                0x4F, 0x01, 0x00, 0x5F, 0x03, 0x7F, 0x00, 0x78, 0x01, 0x63, 0x01, 0x00,
            ])

        var parser = WasmParser.Parser(bytes: wasm, features: [.default, .gc])
        var groups: [RecursiveGroup]?
        while let payload = try parser.parseNext() {
            if case .typeSection(let decoded) = payload {
                groups = decoded
                break
            }
        }
        let i32 = FieldType(storage: .value(.i32), isMutable: false)
        let mutableI8 = FieldType(storage: .packed(.i8), isMutable: true)
        let nullableB = FieldType(
            storage: .value(.ref(ReferenceType(isNullable: true, heapType: .concrete(typeIndex: 1)))), isMutable: false)
        #expect(
            groups == [
                RecursiveGroup(types: [
                    SubType(isFinal: false, supertypes: [], body: .structType(StructType(fields: [i32, mutableI8]))),
                    SubType(
                        isFinal: true, supertypes: [],
                        body: .arrayType(ArrayType(element: FieldType(storage: .packed(.i16), isMutable: true)))),
                ]),
                RecursiveGroup(types: [
                    SubType(isFinal: true, supertypes: [0], body: .structType(StructType(fields: [i32, mutableI8, nullableB])))
                ]),
            ])
    }

    @Test(arguments: ["(module (rec (type (func))))", "(rec (type (func)))"])
    func parsesRecInWAST(script: String) throws {
        var wast = try parseWAST(script)
        let (directive, _) = try #require(try wast.nextDirective())
        guard case .module(let module) = directive, case .text(let wat) = module.source else {
            Issue.record("expected a text module directive, got \(directive)")
            return
        }
        #expect(try TestSupport.section(1, in: wat.encode()) == [0x01, 0x4E, 0x01, 0x60, 0x00, 0x00])
        #expect(try wast.nextDirective() == nil)
    }
}
