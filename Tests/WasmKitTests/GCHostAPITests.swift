import Testing
import WAT
import WasmParser

@testable import WasmKit

/// The host's access to GC objects. Only the host API is tested here; how
/// WebAssembly uses objects is covered by the spec suite and ExtraSuite/gc.
@Suite struct GCHostAPITests {
    static let wat = """
        (module
          (type $box (struct (field $value (mut i32))))
          (type $bytes (array (mut i8)))
          (func (export "read") (param (ref $box)) (result i32)
            (struct.get $box $value (local.get 0))
          )
          (func (export "bytes") (result (ref $bytes))
            (array.new_fixed $bytes 3 (i32.const 1) (i32.const 2) (i32.const 3))
          )
          (func (export "sum") (param $array (ref $bytes)) (result i32)
            (i32.add
              (array.get_u $bytes (local.get $array) (i32.const 0))
              (i32.add
                (array.get_u $bytes (local.get $array) (i32.const 1))
                (array.get_u $bytes (local.get $array) (i32.const 2))
              )
            )
          )
          ;; Allocates more than the 1 MiB heap holds, so that the heap collects
          ;; and the host's objects move.
          (func (export "churn")
            (local $count i32)
            (local.set $count (i32.const 100))
            (block $done
              (loop $loop
                (br_if $done (i32.eqz (local.get $count)))
                (drop (array.new_default $bytes (i32.const 65536)))
                (local.set $count (i32.sub (local.get $count) (i32.const 1)))
                (br $loop)
              )
            )
          )
        )
        """

    private func instantiate() throws -> (Store, Instance) {
        let features: WasmFeatureSet = [.referenceTypes, .gc]
        var configuration = EngineConfiguration(features: features)
        configuration.maxGCHeapSize = 1 << 20
        let store = Store(engine: Engine(configuration: configuration))
        let module = try parseWasm(bytes: wat2wasm(Self.wat, features: features), features: features)
        return (store, try module.instantiate(store: store))
    }

    @Test func hostStructIsTheModulesType() throws {
        let (store, instance) = try instantiate()
        // The same type as the module's $box, so the module accepts the struct.
        let box = try store.engine.register(structType: StructType(fields: [FieldType(storage: .value(.i32), isMutable: true)]))
        let value = try StructRef(store: store, type: box, fields: [.i32(40)])
        try instance.exports[function: "churn"]!()
        try value.setField(0, .i32(42))
        #expect(try instance.exports[function: "read"]!([.ref(.any(value.reference))]) == [.i32(42)])
        #expect(try value.field(0) == .i32(42))
    }

    @Test func hostReadsAndWritesAnArrayFromWebAssembly() throws {
        let (store, instance) = try instantiate()
        guard case .ref(.any(let reference?)) = try instance.exports[function: "bytes"]!()[0],
            let bytes = reference.asArray(in: store)
        else {
            Issue.record("expected an array")
            return
        }
        #expect(reference.asStruct(in: store) == nil)
        try instance.exports[function: "churn"]!()
        #expect(try bytes.count == 3)
        try bytes.set(2, .i32(10))
        #expect(try bytes.get(2) == .i32(10))
        #expect(try instance.exports[function: "sum"]!([.ref(.any(reference))]) == [.i32(13)])
    }

    @Test func handleStopsWorkingWhenItsScopeEnds() throws {
        let (store, instance) = try instantiate()
        let reference = try store.withRootScope {
            try instance.exports[function: "bytes"]!()[0]
        }
        #expect(throws: WasmKitError.self) {
            try instance.exports[function: "sum"]!([reference])
        }
    }
}
