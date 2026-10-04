import Testing
import WasmTypes

@testable import WasmParser

@Suite struct GCTypeDecodingTests {
    private static let header: [UInt8] = [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]

    private func module(_ sections: [(id: UInt8, content: [UInt8])]) -> [UInt8] {
        var bytes = Self.header
        for section in sections {
            precondition(section.content.count < 0x80, "section sizes are emitted as a single LEB byte")
            bytes += [section.id, UInt8(section.content.count)] + section.content
        }
        return bytes
    }

    private func typeGroups(_ typeSection: [UInt8], features: WasmFeatureSet) throws -> [RecursiveGroup]? {
        var parser = Parser(bytes: module([(id: 1, content: typeSection)]), features: features)
        while let payload = try parser.parseNext() {
            if case .typeSection(let groups) = payload {
                return groups
            }
        }
        return nil
    }

    private func instructions(_ code: [UInt8], features: WasmFeatureSet) throws -> [Instruction]? {
        let body: [UInt8] = [0x00] + code + [0x0B]
        let bytes = module([
            (id: 1, content: [0x01, 0x60, 0x00, 0x00]),
            (id: 3, content: [0x01, 0x00]),
            (id: 10, content: [0x01, UInt8(body.count)] + body),
        ])
        var parser = Parser(bytes: bytes, features: features)
        while let payload = try parser.parseNext() {
            guard case .codeSection(let codes) = payload else { continue }
            var expression = ExpressionParser(code: codes[0])
            var result: [Instruction] = []
            while let visit = try expression.parse() {
                result.append(visit.instruction)
            }
            return result
        }
        return nil
    }

    private static func nullable(_ heapType: AbstractHeapType) -> ValueType {
        .ref(ReferenceType(isNullable: true, heapType: .abstract(heapType)))
    }

    private static func finalGroup(_ body: CompositeType) -> RecursiveGroup {
        RecursiveGroup(types: [SubType(isFinal: true, supertypes: [], body: body)])
    }

    private static func errorMessage(_ body: () throws -> Void) -> String? {
        do {
            try body()
            return nil
        } catch let error as WasmParserError {
            guard case .message(let message) = error.kind else { return error.description }
            return message.text
        } catch {
            return "\(error)"
        }
    }

    @Test func decodesRecGroupStructAndArray() throws {
        let groups = try typeGroups(
            [
                0x03,
                0x4E, 0x02,  // rec, 2 subtypes
                0x60, 0x01, 0x7F, 0x01, 0x7E,  // (func (param i32) (result i64))
                0x60, 0x00, 0x00,  // (func)
                0x5F, 0x03, 0x7F, 0x00, 0x7E, 0x00, 0x78, 0x01,  // (struct (field i32 i64) (field (mut i8)) (field))
                0x5E, 0x77, 0x01,  // (array (mut i16))
            ], features: .gc)
        #expect(
            groups == [
                RecursiveGroup(types: [
                    SubType(isFinal: true, supertypes: [], body: .function(FunctionType(parameters: [.i32], results: [.i64]))),
                    SubType(isFinal: true, supertypes: [], body: .function(FunctionType(parameters: [], results: []))),
                ]),
                Self.finalGroup(
                    .structType(
                        StructType(fields: [
                            FieldType(storage: .value(.i32), isMutable: false),
                            FieldType(storage: .value(.i64), isMutable: false),
                            FieldType(storage: .packed(.i8), isMutable: true),
                        ]))),
                Self.finalGroup(.arrayType(ArrayType(element: FieldType(storage: .packed(.i16), isMutable: true)))),
            ])
    }

    @Test func decodesSubAndSubFinalWithSupertypes() throws {
        let groups = try typeGroups(
            [
                0x04,
                0x50, 0x00, 0x5F, 0x00,  // (type $a (sub (struct)))
                0x4F, 0x01, 0x00, 0x5F, 0x00,  // (type $b (sub final $a (struct)))
                0x50, 0x00, 0x60, 0x00, 0x00,  // (type (sub (func)))
                0x4E, 0x01, 0x60, 0x00, 0x00,  // (rec (type (func)))
            ], features: .gc)
        #expect(
            groups == [
                RecursiveGroup(types: [SubType(isFinal: false, supertypes: [], body: .structType(StructType(fields: [])))]),
                RecursiveGroup(types: [SubType(isFinal: true, supertypes: [0], body: .structType(StructType(fields: [])))]),
                RecursiveGroup(types: [
                    SubType(isFinal: false, supertypes: [], body: .function(FunctionType(parameters: [], results: [])))
                ]),
                Self.finalGroup(.function(FunctionType(parameters: [], results: []))),
            ])
    }

    @Test func decodesEmptyRecGroup() throws {
        #expect(try typeGroups([0x01, 0x4E, 0x00], features: .gc) == [RecursiveGroup(types: [])])
    }

    @Test func decodesGCShorthandFieldTypes() throws {
        let groups = try typeGroups(
            [
                0x01,
                0x5F, 0x08,
                0x6E, 0x00, 0x6D, 0x00, 0x6C, 0x00, 0x6B, 0x00,  // anyref eqref i31ref structref
                0x6A, 0x00, 0x71, 0x00, 0x73, 0x00, 0x72, 0x01,  // arrayref nullref nullfuncref (mut nullexternref)
            ], features: .gc)
        #expect(
            groups == [
                Self.finalGroup(
                    .structType(
                        StructType(fields: [
                            FieldType(storage: .value(Self.nullable(.any)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.eq)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.i31)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.structRef)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.arrayRef)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.noneRef)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.noFunc)), isMutable: false),
                            FieldType(storage: .value(Self.nullable(.noExtern)), isMutable: true),
                        ])))
            ])
    }

    @Test func decodesTypedReferencesWithGCAlone() throws {
        let groups = try typeGroups(
            [
                0x01,
                0x5F, 0x03,
                0x64, 0x6E, 0x00,  // (ref any)
                0x63, 0x6D, 0x01,  // (mut (ref null eq))
                0x63, 0x00, 0x00,  // (ref null 0)
            ], features: [.gc])
        #expect(
            groups == [
                Self.finalGroup(
                    .structType(
                        StructType(fields: [
                            FieldType(storage: .value(.ref(ReferenceType(isNullable: false, heapType: .abstract(.any)))), isMutable: false),
                            FieldType(storage: .value(.ref(ReferenceType(isNullable: true, heapType: .abstract(.eq)))), isMutable: true),
                            FieldType(storage: .value(.ref(ReferenceType(isNullable: true, heapType: .concrete(typeIndex: 0)))), isMutable: false),
                        ])))
            ])
    }

    private func tablesAndElements(
        _ sections: [(id: UInt8, content: [UInt8])], features: WasmFeatureSet
    ) throws -> (tables: [Table], elements: [ElementSegment]) {
        var tables: [Table] = []
        var elements: [ElementSegment] = []
        var parser = Parser(bytes: module(sections), features: features)
        while let payload = try parser.parseNext() {
            switch payload {
            case .tableSection(let section): tables = section
            case .elementSection(let section): elements = section
            default: break
            }
        }
        return (tables, elements)
    }

    private static func function(parameter: ReferenceType) -> RecursiveGroup {
        finalGroup(.function(FunctionType(parameters: [.ref(parameter)], results: [])))
    }

    @Test(arguments: [AbstractHeapType.funcRef, .externRef])
    func nonNullableFuncAndExternNeedFunctionReferences(heapType: AbstractHeapType) throws {
        let typeSection: [UInt8] = [0x01, 0x60, 0x01, 0x64, heapType.binaryEncoding, 0x00]
        let gcAlone = Self.errorMessage { _ = try typeGroups(typeSection, features: .gc) }
        #expect(gcAlone == "malformed value type: 100")
        #expect(
            try typeGroups(typeSection, features: [.gc, .functionReferences]) == [
                Self.function(parameter: ReferenceType(isNullable: false, heapType: .abstract(heapType)))
            ])
    }

    @Test func decodesNonNullableConcreteParameterWithGCAlone() throws {
        #expect(
            try typeGroups([0x01, 0x60, 0x01, 0x64, 0x00, 0x00], features: .gc) == [
                Self.function(parameter: ReferenceType(isNullable: false, heapType: .concrete(typeIndex: 0)))
            ])
    }

    @Test func nonNullableExnNeedsExceptionHandlingWithGCAlone() throws {
        let typeSection: [UInt8] = [0x01, 0x60, 0x01, 0x64, 0x69, 0x00]
        let gcAlone = Self.errorMessage { _ = try typeGroups(typeSection, features: .gc) }
        #expect(gcAlone == "malformed value type: 100")
        #expect(
            try typeGroups(typeSection, features: [.gc, .exceptionHandling]) == [
                Self.function(parameter: ReferenceType(isNullable: false, heapType: .exnRef))
            ])
    }

    @Test func tableInitializerNeedsFunctionReferences() throws {
        let table: (id: UInt8, content: [UInt8]) = (id: 4, content: [0x01, 0x40, 0x00, 0x70, 0x00, 0x01, 0xD0, 0x70, 0x0B])  // (table 1 funcref (ref.null func))
        let error = #expect(throws: WasmParserError.self) { _ = try tablesAndElements([table], features: .gc) }
        guard case .parserUnexpectedByte(0x40, let expected)? = error?.kind else {
            Issue.record("got \(error.map(String.init(describing:)) ?? "no error")")
            return
        }
        #expect(expected == [0x6F, 0x70])
        #expect(
            try tablesAndElements([table], features: [.gc, .functionReferences]).tables == [
                Table(type: TableType(elementType: .funcRef, limits: Limits(min: 1)), initializer: [.refNull(type: .funcRef), .end])
            ])
    }

    @Test func functionIndexSegmentIsNonNullableOnlyWithFunctionReferences() throws {
        let sections: [(id: UInt8, content: [UInt8])] = [
            (id: 1, content: [0x01, 0x60, 0x00, 0x00]),
            (id: 3, content: [0x01, 0x00]),
            (id: 4, content: [0x01, 0x70, 0x00, 0x01]),
            (id: 9, content: [0x01, 0x00, 0x41, 0x00, 0x0B, 0x01, 0x00]),  // (elem (i32.const 0) func 0)
            (id: 10, content: [0x01, 0x02, 0x00, 0x0B]),
        ]
        func segment(_ type: ReferenceType) -> ElementSegment {
            ElementSegment(
                type: type, initializer: [[.refFunc(functionIndex: 0)]], mode: .active(table: 0, offset: [.i32Const(value: 0), .end]))
        }
        #expect(try tablesAndElements(sections, features: .gc).elements == [segment(.funcRef)])
        #expect(
            try tablesAndElements(sections, features: [.gc, .functionReferences]).elements == [
                segment(ReferenceType(isNullable: false, heapType: .funcRef))
            ])
    }

    @Test func decodesGCHeapTypesInFunctionBodies() throws {
        #expect(
            try instructions([0xD0, 0x6E, 0x1A, 0xD0, 0x71, 0x1A], features: .gc) == [
                .refNull(type: .abstract(.any)), .drop,
                .refNull(type: .abstract(.noneRef)), .drop,
                .end,
            ])
        #expect(
            try instructions([0x02, 0x6E, 0xD0, 0x6E, 0x0B, 0x1A], features: .gc) == [
                .block(blockType: .type(Self.nullable(.any))), .refNull(type: .abstract(.any)), .end, .drop, .end,
            ])
    }

    @Test func reportsMalformedGCTypes() {
        let mutability = Self.errorMessage { _ = try typeGroups([0x01, 0x5E, 0x78, 0x02], features: .gc) }
        #expect(mutability == "Malformed mutability: 2")
        let composite = Self.errorMessage { _ = try typeGroups([0x01, 0x5D], features: .gc) }
        #expect(composite == "Malformed composite type: 93")
        let overlong = Self.errorMessage { _ = try typeGroups([0x01, 0xE0, 0x00], features: .gc) }
        #expect(overlong == "Integer representation is too long")
    }

    @Test(arguments: [WasmFeatureSet.default, [.functionReferences]])
    func rejectsGCEncodingsWithoutGC(features: WasmFeatureSet) {
        let structEntry = Self.errorMessage { _ = try typeGroups([0x01, 0x5F, 0x00], features: features) }
        #expect(structEntry == "Malformed function type: 95")
        let recEntry = Self.errorMessage { _ = try typeGroups([0x01, 0x4E, 0x01, 0x60, 0x00, 0x00], features: features) }
        #expect(recEntry == "Malformed function type: 78")
        let subEntry = Self.errorMessage { _ = try typeGroups([0x01, 0x50, 0x00, 0x60, 0x00, 0x00], features: features) }
        #expect(subEntry == "Malformed function type: 80")
        let anyrefParameter = Self.errorMessage { _ = try typeGroups([0x01, 0x60, 0x01, 0x6E, 0x00], features: features) }
        #expect(anyrefParameter == "malformed value type: 110")
        let refNullAny = Self.errorMessage { _ = try instructions([0xD0, 0x6E, 0x1A], features: features) }
        #expect(refNullAny == "invalid function type index: -18, expected a unsigned 32-bit integer")
        let refNullNone = Self.errorMessage { _ = try instructions([0xD0, 0x71, 0x1A], features: features) }
        #expect(refNullNone == "invalid function type index: -15, expected a unsigned 32-bit integer")
        let anyrefBlock = Self.errorMessage { _ = try instructions([0x02, 0x6E, 0xD0, 0x6E, 0x0B, 0x1A], features: features) }
        #expect(anyrefBlock == "invalid function type index: -18, expected a unsigned 32-bit integer")
    }

    @Test func decodesNullExnRefWithExceptionHandling() throws {
        #expect(
            try typeGroups([0x01, 0x60, 0x01, 0x74, 0x00], features: .default) == [
                Self.finalGroup(.function(FunctionType(parameters: [Self.nullable(.noExn)], results: [])))
            ])
        #expect(
            try instructions([0xD0, 0x74, 0x1A], features: .default) == [
                .refNull(type: .abstract(.noExn)), .drop, .end,
            ])
        #expect(
            try instructions([0x02, 0x74, 0xD0, 0x74, 0x0B, 0x1A], features: .default) == [
                .block(blockType: .type(Self.nullable(.noExn))), .refNull(type: .abstract(.noExn)), .end, .drop, .end,
            ])
    }

    @Test(arguments: [WasmFeatureSet.referenceTypes, .gc])
    func rejectsNullExnRefWithoutExceptionHandling(features: WasmFeatureSet) {
        let parameter = Self.errorMessage { _ = try typeGroups([0x01, 0x60, 0x01, 0x74, 0x00], features: features) }
        #expect(parameter == "malformed value type: 116")
        let refNull = Self.errorMessage { _ = try instructions([0xD0, 0x74, 0x1A], features: features) }
        #expect(refNull == "invalid function type index: -12, expected a unsigned 32-bit integer")
    }
}
