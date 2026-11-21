import Testing
import WasmParser

@_spi(Fuzzing) @testable import WasmKit

@Suite
struct ModuleTests {
    private static func nullableReference(toFirstTypeOf module: Module) -> ReferenceType {
        ReferenceType(isNullable: true, heapType: .concrete(typeIndex: module.typeCanonicalizer.typeIDs[0].id))
    }

    @Test
    func instantiationInStoreOfOtherEngineThrows() throws {
        let engine = Engine()
        // (module)
        let module = try parseWasm(bytes: [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00], engine: engine)
        _ = try module.instantiate(store: Store(engine: engine))
        let error = try #require(throws: WasmKitError.self) {
            try module.instantiate(store: Store(engine: Engine()))
        }
        #expect(error.description == "module was parsed with a different engine than the store's")
    }

    @Test
    func functionTypeAtIndexHasCanonicalTypes() throws {
        let engine = Engine()
        let store = Store(engine: engine)
        _ = try Function(store: store, parameters: [.i32]) { _, _ in [] }
        // (module (type $t (func)) (type (func (param (ref null $t)))) (import "m" "f" (func (type 1))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x02, 0x07, 0x01, 0x01, 0x6D, 0x01, 0x66, 0x00, 0x01,
            ],
            engine: engine,
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        let type = try #require(module.functionType(at: 1))
        #expect(type == FunctionType(parameters: [.ref(Self.nullableReference(toFirstTypeOf: module))]))
        let function = try Function(store: store, type: type) { _, _ in [] }
        _ = try module.instantiate(store: store, imports: ["m": ["f": function]])
    }

    @Test
    func functionTypeAtIndexOfStructTypeIsNil() throws {
        // (module (type (struct)))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x03, 0x01, 0x5F, 0x00,
            ],
            engine: Engine(),
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        #expect(module.functionType(at: 0) == nil)
        #expect(module.functionType(at: 1) == nil)
    }

    @Test
    func exportedFunctionTypeHasCanonicalTypes() throws {
        let engine = Engine()
        _ = try Function(store: Store(engine: engine), parameters: [.i32]) { _, _ in [] }
        let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .gc]

        // (module (type $t (func)) (type (func (param (ref null $t)))) (func (export "f") (type 1)))
        let defined = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x03, 0x02, 0x01, 0x01,
                0x07, 0x05, 0x01, 0x01, 0x66, 0x00, 0x00,
                0x0A, 0x04, 0x01, 0x02, 0x00, 0x0B,
            ],
            engine: engine,
            features: features
        )
        let expected = FunctionType(parameters: [.ref(Self.nullableReference(toFirstTypeOf: defined))])
        #expect(defined.exportedFunctionType(named: "f") == expected)
        #expect(defined.exportedFunctionType(named: "missing") == nil)

        // (module (type $t (func)) (type (func (param (ref null $t)))) (import "m" "f" (func (type 1))) (export "g" (func 0)))
        let imported = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x02, 0x07, 0x01, 0x01, 0x6D, 0x01, 0x66, 0x00, 0x01,
                0x07, 0x05, 0x01, 0x01, 0x67, 0x00, 0x00,
            ],
            engine: engine,
            features: features
        )
        #expect(imported.exportedFunctionType(named: "g") == expected)
    }

    @Test
    func importedGlobalAndTableTypesAreCanonical() throws {
        let engine = Engine()
        let store = Store(engine: engine)
        _ = try Function(store: store, parameters: [.i32]) { _, _ in [] }
        // (module (type $t (func)) (import "m" "g" (global (ref null $t))) (import "m" "t" (table 1 (ref null $t))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
                0x02, 0x12, 0x02, 0x01, 0x6D, 0x01, 0x67, 0x03, 0x63, 0x00, 0x00,
                0x01, 0x6D, 0x01, 0x74, 0x01, 0x63, 0x00, 0x00, 0x01,
            ],
            engine: engine,
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        let reference = Self.nullableReference(toFirstTypeOf: module)
        let globalType = GlobalType(mutability: .constant, valueType: .ref(reference))
        let tableType = TableType(elementType: reference, limits: Limits(min: 1))
        #expect(module.imports.map(\.descriptor) == [.global(globalType), .table(tableType)])
        let global = try Global(store: store, type: globalType, value: .ref(.function(nil)))
        let table = try Table(store: store, type: tableType)
        _ = try module.instantiate(store: store, imports: ["m": ["g": global, "t": table]])
    }
}
