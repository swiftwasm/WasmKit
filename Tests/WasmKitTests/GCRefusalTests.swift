import Testing
import WAT
import WasmKit
import WasmParser

@Suite struct GCRefusalTests {
    struct RefusedModule: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let wat: String
        let message: String
        var features: WasmFeatureSet = .all
    }

    @Test(arguments: ["any", "eq", "i31", "struct", "array", "none", "noextern", "nofunc", "noexn"])
    func validatorRefusesHeapTypeInFunctionType(_ heapType: String) throws {
        try Self.expectValidationError(
            RefusedModule(
                testDescription: heapType,
                wat: "(module (type (func (param (ref null \(heapType))))))",
                message: "heap type \(heapType) is not implemented yet"
            ))
    }

    static let gcTypeDefinitions: [RefusedModule] = [
        ("struct", "(module (type (struct)))"),
        ("non-final function", "(module (type (sub (func))))"),
        ("function with a supertype", "(module (type (func)) (type (sub final 0 (func))))"),
        ("two-member rec group", "(module (rec (type (func)) (type (func))))"),
        ("empty rec group", "(module (rec))"),
    ].map { RefusedModule(testDescription: $0, wat: $1, message: "GC type definitions are not implemented yet") }

    @Test(arguments: gcTypeDefinitions)
    func validatorRefusesGCTypeDefinition(_ module: RefusedModule) throws {
        try Self.expectValidationError(module)
    }

    @Test func parseRefusesFunctionOfStructType() {
        // (module (type (struct)) (func (type 0))), which wat2wasm refuses to encode.
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x03, 0x01, 0x5F, 0x00,
            0x03, 0x02, 0x01, 0x00,
            0x0A, 0x04, 0x01, 0x02, 0x00, 0x0B,
        ]
        let error = #expect(throws: WasmKitError.self) {
            try parseWasm(bytes: bytes, features: .all)
        }
        #expect(Self.messageText(error) == "Type index 0 does not define a function type")
    }

    @Test func parseAdmitsSingletonRecGroupOfFinalFunction() throws {
        let wat = #"(module (rec (type (func (param i32)))) (func (export "f") (type 0)))"#
        let module = try parseWasm(bytes: wat2wasm(wat, features: .all), features: .all)
        #expect(module.exportedFunctionType(named: "f") == FunctionType(parameters: [.i32], results: []))
    }

    static let modulesWithGCHeapTypes: [RefusedModule] = [
        RefusedModule(
            testDescription: "imported table", wat: #"(module (import "m" "t" (table 1 eqref)))"#,
            message: "heap type eq is not implemented yet"),
        RefusedModule(
            testDescription: "imported global", wat: #"(module (import "m" "g" (global i31ref)))"#,
            message: "heap type i31 is not implemented yet"),
        RefusedModule(
            testDescription: "table", wat: "(module (table 1 structref))",
            message: "heap type struct is not implemented yet"),
        RefusedModule(
            testDescription: "table initializer", wat: "(module (table 1 funcref (ref.null nofunc)))",
            message: "heap type nofunc is not implemented yet"),
        RefusedModule(
            // A funcref initializer leaves the global's type as the only GC heap type.
            testDescription: "global", wat: "(module (global arrayref (ref.null func)))",
            message: "heap type array is not implemented yet"),
        RefusedModule(
            testDescription: "global initializer", wat: "(module (global funcref (ref.null nofunc)))",
            message: "heap type nofunc is not implemented yet"),
        RefusedModule(
            testDescription: "element segment type", wat: "(module (elem (ref null any)))",
            message: "heap type any is not implemented yet"),
        RefusedModule(
            testDescription: "element segment item", wat: "(module (elem externref (ref.null noextern)))",
            message: "heap type noextern is not implemented yet"),
        RefusedModule(
            testDescription: "element segment offset",
            wat: "(module (table 1 funcref) (elem (table 0) (offset (ref.null none)) func))",
            message: "heap type none is not implemented yet"),
        RefusedModule(
            testDescription: "local", wat: "(module (func (local nullref)))",
            message: "heap type none is not implemented yet"),
        RefusedModule(
            testDescription: "data segment offset",
            wat: #"(module (memory 1) (data (memory 0) (offset (ref.null any)) ""))"#,
            message: "heap type any is not implemented yet"),
        RefusedModule(
            testDescription: "nullexnref local", wat: "(module (func (local nullexnref)))",
            message: "heap type noexn is not implemented yet", features: .default),
    ]

    @Test(arguments: modulesWithGCHeapTypes)
    func validatorRefusesHeapType(_ module: RefusedModule) throws {
        try Self.expectValidationError(module)
    }

    static let functionsWithGCHeapTypes: [RefusedModule] = [
        RefusedModule(
            testDescription: "block", wat: "(module (func (block (result eqref) unreachable) drop))",
            message: "heap type eq is not implemented yet"),
        RefusedModule(
            testDescription: "loop", wat: "(module (func (loop (result eqref) unreachable) drop))",
            message: "heap type eq is not implemented yet"),
        RefusedModule(
            testDescription: "if",
            wat: "(module (func (if (result eqref) (i32.const 0) (then unreachable) (else unreachable)) drop))",
            message: "heap type eq is not implemented yet"),
        RefusedModule(
            testDescription: "try_table", wat: "(module (func (try_table (result anyref) unreachable) drop))",
            message: "heap type any is not implemented yet"),
        RefusedModule(
            testDescription: "select", wat: "(module (func unreachable select (result i31ref) drop))",
            message: "heap type i31 is not implemented yet"),
        RefusedModule(
            testDescription: "ref.null", wat: "(module (func ref.null struct drop))",
            message: "heap type struct is not implemented yet"),
    ]

    @Test(arguments: functionsWithGCHeapTypes)
    func translatorRefusesHeapType(_ module: RefusedModule) throws {
        let parsed = try parseWasm(bytes: wat2wasm(module.wat, features: module.features), features: module.features)
        let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
        let store = Store(engine: engine)
        let error = #expect(throws: WasmKitError.self) {
            try parsed.instantiate(store: store)
        }
        #expect(Self.messageText(error) == module.message)
    }

    @Test func hostTableRefusesHeapType() {
        let store = Store(engine: Engine())
        let type = TableType(elementType: ReferenceType(isNullable: true, heapType: .abstract(.eq)), limits: Limits(min: 1))
        let error = #expect(throws: WasmKitError.self) {
            try Table(store: store, type: type)
        }
        #expect(Self.messageText(error) == "heap type eq is not implemented yet")
    }

    @Test func hostGlobalRefusesHeapType() {
        let store = Store(engine: Engine())
        let type = GlobalType(mutability: .constant, valueType: .ref(ReferenceType(isNullable: true, heapType: .abstract(.any))))
        let error = #expect(throws: WasmKitError.self) {
            try Global(store: store, type: type, value: .ref(.extern(nil)))
        }
        #expect(Self.messageText(error) == "heap type any is not implemented yet")
    }

    private static func expectValidationError(
        _ module: RefusedModule, sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let parsed = try parseWasm(bytes: wat2wasm(module.wat, features: module.features), features: module.features)
        let error = #expect(throws: WasmKitError.self, sourceLocation: sourceLocation) {
            try parsed.instantiate(store: Store(engine: Engine()))
        }
        #expect(Self.messageText(error) == module.message, sourceLocation: sourceLocation)
    }

    private static func messageText(_ error: WasmKitError?) -> String? {
        guard case .message(let message)? = error?.kind else { return error.map(String.init(describing:)) }
        return message.text
    }
}
