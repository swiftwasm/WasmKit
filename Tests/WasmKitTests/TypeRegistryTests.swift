import Testing

@testable import WasmKit

#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Foundation
    import Glibc
#endif

@Suite
struct TypeRegistryTests {
    @Test
    func instantiationPastMaxTypeCountThrows() throws {
        // (module (type (func)))
        let module = try parseWasm(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
        ])
        // (module (type (func (param i32))))
        let moduleWithNewType = try parseWasm(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x05, 0x01, 0x60, 0x01, 0x7F, 0x00,
        ])
        let store = Store(engine: Engine(configuration: EngineConfiguration(maxTypeCount: 1)))
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        // The module's only type is the host function's, so it takes no more room.
        _ = try module.instantiate(store: store)
        let error = try #require(throws: WasmKitError.self) {
            try moduleWithNewType.instantiate(store: store)
        }
        #expect(error.description == "too many types: an engine holds at most 1, set by EngineConfiguration.maxTypeCount")
    }

    @Test
    func recursionGroupPastMaxTypeCountThrows() throws {
        // (module (rec (type (func)) (type (func (param i32)))))
        let moduleWithGroup = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x0A, 0x01, 0x4E, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x7F, 0x00,
            ],
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        // (module (type (func (param i32))))
        let moduleWithNewType = try parseWasm(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x05, 0x01, 0x60, 0x01, 0x7F, 0x00,
        ])
        let store = Store(engine: Engine(configuration: EngineConfiguration(maxTypeCount: 2)))
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        // One type is left, and the group needs two.
        let error = try #require(throws: WasmKitError.self) {
            try moduleWithGroup.instantiate(store: store)
        }
        #expect(error.description == "too many types: an engine holds at most 2, set by EngineConfiguration.maxTypeCount")
        // The group took no room, so one new type still fits.
        _ = try moduleWithNewType.instantiate(store: store)
    }

    @Test
    func supertypeDefinedLaterInGroupIsUnknown() throws {
        // (module (type (struct)) (rec (type (sub 2 (struct))) (type (sub (struct)))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x0E, 0x02, 0x5F, 0x00, 0x4E, 0x02, 0x50, 0x01, 0x02, 0x5F, 0x00, 0x50, 0x00, 0x5F, 0x00,
            ],
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        let error = try #require(throws: WasmKitError.self) {
            try module.instantiate(store: Store(engine: Engine()))
        }
        #expect(error.description == "unknown type 2")
    }

    @Test(arguments: [
        // (module (type $a (sub final (func))) (type (sub $a (func))))
        (
            [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x0A, 0x02, 0x60, 0x00, 0x00, 0x50, 0x01, 0x00, 0x60, 0x00, 0x00,
            ] as [UInt8],
            "type mismatch: cannot declare a subtype of final type 0"
        ),
        // Two equal function types first, so that type 2 is the engine's second type.
        // (module (type (func)) (type (func)) (type $a (sub final (struct))) (type (sub $a (struct))))
        (
            [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x0E, 0x04, 0x60, 0x00, 0x00, 0x60, 0x00, 0x00, 0x5F, 0x00, 0x50, 0x01, 0x02, 0x5F, 0x00,
            ],
            "type mismatch: cannot declare a subtype of final type 2"
        ),
        // (module (type (func)) (type (func))
        //   (type $a (sub (struct (field i32)))) (type (sub $a (struct (field i64)))))
        (
            [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x14, 0x04, 0x60, 0x00, 0x00, 0x60, 0x00, 0x00,
                0x50, 0x00, 0x5F, 0x01, 0x7F, 0x00, 0x50, 0x01, 0x02, 0x5F, 0x01, 0x7E, 0x00,
            ],
            "type mismatch: invalid declared supertype 2"
        ),
    ])
    func declaredSupertypeErrorNamesModuleTypeIndex(bytes: [UInt8], message: String) throws {
        let module = try parseWasm(bytes: bytes, features: [.referenceTypes, .exceptionHandling, .gc])
        let error = try #require(throws: WasmKitError.self) {
            try module.instantiate(store: Store(engine: Engine()))
        }
        #expect(error.description == message)
    }

    static func functionReference(store: Store) throws -> Value {
        // (module (func $f) (elem declare func $f) (func (export "get") (result funcref) (ref.func $f)))
        let module = try parseWasm(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x08, 0x02, 0x60, 0x00, 0x00, 0x60, 0x00, 0x01, 0x70,
            0x03, 0x03, 0x02, 0x00, 0x01,
            0x07, 0x07, 0x01, 0x03, 0x67, 0x65, 0x74, 0x00, 0x01,
            0x09, 0x05, 0x01, 0x03, 0x00, 0x01, 0x00,
            0x0A, 0x09, 0x02, 0x02, 0x00, 0x0B, 0x04, 0x00, 0xD2, 0x00, 0x0B,
        ])
        let get = try #require(try module.instantiate(store: store).exportedFunction(name: "get"))
        let results = try get()
        return results[0]
    }

    static func storeWithFunctionReferenceOfOtherEngine() throws -> (store: Store, reference: Value) {
        let store = Store(engine: Engine())
        // 4,096 types first, so that the reference's type ID is in a page that
        // no other new engine's registry has allocated.
        let numberTypes: [ValueType] = [.i32, .i64, .f32, .f64]
        for signature in 0..<4096 {
            let parameters = (0..<6).map { numberTypes[(signature >> (2 * $0)) & 3] }
            _ = try Function(store: store, parameters: parameters) { _, _ in [] }
        }
        return (store, try functionReference(store: store))
    }

    static func referenceType(_ id: UInt32) -> ValueType {
        .ref(ReferenceType(isNullable: true, heapType: .concrete(typeIndex: id)))
    }

    @Test(arguments: [UInt32(5000), 0x2000_0000, 0x8000_0000, 0x8000_0001])
    func hostFunctionOfUnregisteredTypeThrows(id: UInt32) throws {
        let store = Store(engine: Engine())
        // Type 0, so that 0x2000_0000 and 0x8000_0000 differ from a registered ID only above its index.
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        let parameterError = try #require(throws: WasmKitError.self) {
            try Function(store: store, parameters: [Self.referenceType(id)]) { _, _ in [] }
        }
        #expect(parameterError.description == "unknown type \(id)")
        let resultError = try #require(throws: WasmKitError.self) {
            try Function(store: store, parameters: [], results: [Self.referenceType(id)]) { _, _ in [] }
        }
        #expect(resultError.description == "unknown type \(id)")
    }

    @Test
    func tagOfUnregisteredTypeThrows() throws {
        let error = try #require(throws: WasmKitError.self) {
            try Tag(store: Store(engine: Engine()), type: FunctionType(parameters: [Self.referenceType(0x8000_0003)]))
        }
        #expect(error.description == "unknown type 2147483651")
    }

    @Test(arguments: [UInt32(5000), 0x2000_0000])
    func globalOfUnregisteredTypeThrows(id: UInt32) throws {
        let store = Store(engine: Engine())
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        let type = GlobalType(mutability: .constant, valueType: Self.referenceType(id))
        let error = try #require(throws: WasmKitError.self) {
            try Global(store: store, type: type, value: .ref(.function(nil)))
        }
        #expect(error.description == "unknown type \(id)")
    }

    @available(*, deprecated)
    @Test
    func deprecatedGlobalOfUnregisteredTypeThrows() throws {
        let type = GlobalType(mutability: .constant, valueType: Self.referenceType(5000))
        let error = try #require(throws: WasmKitError.self) {
            try Global(globalType: type, initialValue: .ref(.function(nil)), store: Store(engine: Engine()))
        }
        #expect(error.description == "unknown type 5000")
    }

    @Test
    func tableOfUnregisteredTypeThrows() throws {
        let type = TableType(
            elementType: ReferenceType(isNullable: true, heapType: .concrete(typeIndex: 5000)), limits: Limits(min: 1))
        let error = try #require(throws: WasmKitError.self) {
            try Table(store: Store(engine: Engine()), type: type)
        }
        #expect(error.description == "unknown type 5000")
    }

    @Test
    func hostTypePastMaxTypeCountThrows() throws {
        let store = Store(engine: Engine(configuration: EngineConfiguration(maxTypeCount: 1)))
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        let functionError = try #require(throws: WasmKitError.self) {
            try Function(store: store, parameters: [.i32]) { _, _ in [] }
        }
        #expect(functionError.description == "too many types: an engine holds at most 1, set by EngineConfiguration.maxTypeCount")
        let tagError = try #require(throws: WasmKitError.self) {
            try Tag(store: store, type: FunctionType(parameters: [.i64]))
        }
        #expect(tagError.description == "too many types: an engine holds at most 1, set by EngineConfiguration.maxTypeCount")
    }

    @available(*, deprecated)
    @Test
    func runtimeHostModulesPastMaxTypeCountThrow() throws {
        let hostModule = HostModule(functions: [
            "f": HostFunction(type: FunctionType(parameters: []), implementation: { _, _ in [] }),
            "g": HostFunction(type: FunctionType(parameters: [.i32]), implementation: { _, _ in [] }),
        ])
        let error = try #require(throws: WasmKitError.self) {
            try Runtime(hostModules: ["env": hostModule], configuration: EngineConfiguration(maxTypeCount: 1))
        }
        #expect(error.description == "too many types: an engine holds at most 1, set by EngineConfiguration.maxTypeCount")
    }

    @available(*, deprecated)
    @Test
    func runtimeHostModuleOfUnregisteredTypeThrows() throws {
        let hostModule = HostModule(functions: [
            "f": HostFunction(type: FunctionType(parameters: [Self.referenceType(5000)]), implementation: { _, _ in [] })
        ])
        let error = try #require(throws: WasmKitError.self) {
            try Runtime(hostModules: ["env": hostModule])
        }
        #expect(error.description == "unknown type 5000")
    }

    @Test
    func hostObjectsOfRegisteredTypeSatisfyImports() throws {
        let store = Store(engine: Engine())
        // Type 0x0800_0000, the engine's first type and the module's type 0.
        _ = try Function(store: store, parameters: []) { _, _ in [] }
        let type = Self.referenceType(0x0800_0000)
        let function = try Function(store: store, parameters: [type]) { _, _ in [] }
        let global = try Global(store: store, type: GlobalType(mutability: .constant, valueType: type), value: .ref(.function(nil)))
        let tableType = TableType(
            elementType: ReferenceType(isNullable: true, heapType: .concrete(typeIndex: 0x0800_0000)), limits: Limits(min: 1))
        let table = try Table(store: store, type: tableType)
        let tag = try Tag(store: store, type: FunctionType(parameters: [type]))
        // (module (type $t (func)) (import "m" "f" (func (param (ref null $t))))
        //   (import "m" "g" (global (ref null $t))) (import "m" "t" (table 1 (ref null $t)))
        //   (import "m" "e" (tag (param (ref null $t)))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x02, 0x1F, 0x04, 0x01, 0x6D, 0x01, 0x66, 0x00, 0x01, 0x01, 0x6D, 0x01, 0x67, 0x03, 0x63, 0x00, 0x00,
                0x01, 0x6D, 0x01, 0x74, 0x01, 0x63, 0x00, 0x00, 0x01, 0x01, 0x6D, 0x01, 0x65, 0x04, 0x00, 0x01,
            ],
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        _ = try module.instantiate(store: store, imports: ["m": ["f": function, "g": global, "t": table, "e": tag]])
    }

    @Test
    func functionReferenceFromOtherEngineFailsParameterCheck() throws {
        let (otherStore, reference) = try Self.storeWithFunctionReferenceOfOtherEngine()
        // (module (type $t (func)) (func (export "take") (param (ref null $t))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x03, 0x02, 0x01, 0x01,
                0x07, 0x08, 0x01, 0x04, 0x74, 0x61, 0x6B, 0x65, 0x00, 0x00,
                0x0A, 0x04, 0x01, 0x02, 0x00, 0x0B,
            ],
            features: [.referenceTypes, .exceptionHandling, .functionReferences]
        )
        let take = try #require(try module.instantiate(store: Store(engine: Engine())).exportedFunction(name: "take"))
        let error = try #require(throws: Trap.self) {
            try withExtendedLifetime(otherStore) { try take([reference]) }
        }
        #expect(error.description == "Trap: parameter types don't match, expected [(ref null $134217728)], got [\(reference)]")
    }

    @Test
    func functionReferenceFromOtherEngineFailsArrayParameterCheck() throws {
        let otherStore = Store(engine: Engine())
        let reference = try Self.functionReference(store: otherStore)
        // (module (type $arr (array i32)) (func (export "take") (param (ref null $arr))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x09, 0x02, 0x5E, 0x7F, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
                0x03, 0x02, 0x01, 0x01,
                0x07, 0x08, 0x01, 0x04, 0x74, 0x61, 0x6B, 0x65, 0x00, 0x00,
                0x0A, 0x04, 0x01, 0x02, 0x00, 0x0B,
            ],
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        let take = try #require(try module.instantiate(store: Store(engine: Engine())).exportedFunction(name: "take"))
        // The reference's function type and $arr are each the first type of their engine.
        let error = try #require(throws: Trap.self) {
            try withExtendedLifetime(otherStore) { try take([reference]) }
        }
        #expect(error.description == "Trap: parameter types don't match, expected [(ref null $268435456)], got [\(reference)]")
    }

    @Test(arguments: [
        (UInt32(0x0800_0000), UInt32(5000)), (5000, 0x0800_0000), (0x2800_0000, 0x0800_0000),
    ])
    func unregisteredTypeIsUnrelatedToRegisteredType(subtype: UInt32, supertype: UInt32) throws {
        // (module (type (func)))
        let module = try parseWasm(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
        ])
        let store = Store(engine: Engine())
        _ = try module.instantiate(store: store)
        #expect(!store.engine.typeRegistry.isSubtype(.concrete(typeIndex: subtype), of: .concrete(typeIndex: supertype)))
    }

    #if os(macOS) || os(Linux)
        @Test(.disabled(if: Engine.isAddressSanitizerEnabled, "AddressSanitizer aborts exit tests on macOS"))
        func maxTypeCountOfZeroTraps() async {
            await #expect(processExitsWith: .failure) {
                _ = Engine(configuration: EngineConfiguration(maxTypeCount: 0))
            }
        }

        @Test(.disabled(if: Engine.isAddressSanitizerEnabled, "AddressSanitizer aborts exit tests on macOS"))
        func maxTypeCountAboveMaximumTraps() async {
            await #expect(processExitsWith: .failure) {
                _ = Engine(configuration: EngineConfiguration(maxTypeCount: TypeRegistry.maxCapacity + 1))
            }
        }

        @Test(.disabled(if: Engine.isAddressSanitizerEnabled, "AddressSanitizer aborts exit tests on macOS"))
        func lookupOfTypeFromOtherEngineTraps() async throws {
            let result = try await #require(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                let (otherStore, reference) = try TypeRegistryTests.storeWithFunctionReferenceOfOtherEngine()
                // (module (type $t (func)) (table 1 funcref)
                //   (func (export "run") (param funcref)
                //     (table.set 0 (i32.const 0) (local.get 0)) (call_indirect (type $t) (i32.const 0))))
                let module = try parseWasm(bytes: [
                    0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                    0x01, 0x08, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x70, 0x00,
                    0x03, 0x02, 0x01, 0x01,
                    0x04, 0x04, 0x01, 0x70, 0x00, 0x01,
                    0x07, 0x07, 0x01, 0x03, 0x72, 0x75, 0x6E, 0x00, 0x00,
                    0x0A, 0x0F, 0x01, 0x0D, 0x00, 0x41, 0x00, 0x20, 0x00, 0x26, 0x00, 0x41, 0x00, 0x11, 0x00, 0x00, 0x0B,
                ])
                let run = try #require(try module.instantiate(store: Store(engine: Engine())).exportedFunction(name: "run"))
                // call_indirect finds the types unrelated, then looks the reference's type up for the trap's message.
                _ = try withExtendedLifetime(otherStore) { try run([reference]) }
            }
            #expect(String(decoding: result.standardErrorContent, as: UTF8.self).contains("Type 134221824 is not registered"))
        }

        // On 32-bit platforms a leaked registry holds about 7 KiB, too little for the threshold below.
        #if _pointerBitWidth(_64)
            static func memoryInUse() throws -> Int {
                #if os(macOS)
                    var statistics = malloc_statistics_t()
                    malloc_zone_statistics(nil, &statistics)
                    return Int(statistics.size_in_use)
                #else
                    let statm = try String(contentsOfFile: "/proc/self/statm", encoding: .utf8)
                    let residentPages = try #require(Int(statm.split(separator: " ")[1]))
                    return residentPages * sysconf(Int32(_SC_PAGESIZE))
                #endif
            }

            @Test(
                .disabled(
                    if: Engine.isAddressSanitizerEnabled,
                    "AddressSanitizer holds freed memory in quarantine, and aborts exit tests on macOS"
                )
            )
            func droppedEngineReleasesTypeRegistryMemory() async throws {
                // The child process keeps tests running in parallel out of the measurement.
                let result = try await #require(processExitsWith: .success, observing: [\.standardOutputContent]) {
                    // (module (func))
                    let module = try parseWasm(bytes: [
                        0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                        0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
                        0x03, 0x02, 0x01, 0x00,
                        0x0A, 0x04, 0x01, 0x02, 0x00, 0x0B,
                    ])
                    func instantiateInNewEngine() throws {
                        _ = try module.instantiate(store: Store(engine: Engine()))
                    }
                    // Warm-up, because on Linux the allocator keeps some freed pages resident.
                    for _ in 0..<8 {
                        try instantiateInNewEngine()
                    }
                    let before = try TypeRegistryTests.memoryInUse()
                    for _ in 0..<256 {
                        try instantiateInNewEngine()
                    }
                    print(try TypeRegistryTests.memoryInUse() - before, terminator: "")
                }
                let growth = try #require(Int(String(decoding: result.standardOutputContent, as: UTF8.self)))
                // A leaked registry keeps at least its 256 KiB page table.
                #expect(growth < 256 * 64 * 1024)
            }
        #endif
    #endif
}
