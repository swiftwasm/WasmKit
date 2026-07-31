import Testing
import WAT
import WasmParser

@testable import WasmKit

@Suite
struct ExecutionTests {

    @Test
    func dropWithRelinkingOptimization() throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (func (export "_start") (result i32) (local $x i32)
                        (i32.const 42)
                        (i32.const 0)
                        (i32.eqz)
                        (drop)
                        (local.set $x)
                        (local.get $x)
                    )
                )
                """
            )
        )
        let engine = Engine()
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    @Test
    func moduleValidateWithoutInstantiating() throws {
        // validate() never allocates, so a max-size memory and 0xffff_ffff-entry table pass without OOM.
        let maxMemory = try parseWasm(bytes: wat2wasm("(module (memory 65536))"))
        try maxMemory.validate()
        let maxTable = try parseWasm(bytes: wat2wasm("(module (table 0xffff_ffff funcref))"))
        try maxTable.validate()

        // The parser does not enforce the page max, so (memory 65537) decodes and only
        // ModuleValidator.checkMemoryType rejects it.
        let overMax = try parseWasm(bytes: wat2wasm("(module (memory 65537))"))
        #expect(throws: WasmKitError.self) { try overMax.validate() }

        // validate() checks the start signature but does not run its body, so this unreachable start never traps.
        let withStart = try parseWasm(bytes: wat2wasm("(module (func) (func unreachable) (start 1))"))
        try withStart.validate()
    }

    @Test
    func relaxedSimdOpsExecute() throws {
        // Exercises the 4 relaxed_trunc ops the spectest never runs (i32x4_relaxed_trunc.wast has no
        // assert_return) plus the dot products. Each func returns 1 iff the op matches its expected vector.
        let module = try parseWasm(
            bytes: wat2wasm(
                #"""
                (module
                  (func (export "madd") (result i32)
                    (i32.and
                      (i32x4.all_true (f32x4.eq
                        (f32x4.relaxed_madd (v128.const f32x4 2 0 0 0) (v128.const f32x4 3 0 0 0) (v128.const f32x4 4 0 0 0))
                        (v128.const f32x4 10 0 0 0)))
                      (i32x4.all_true (f32x4.eq
                        (f32x4.relaxed_nmadd (v128.const f32x4 2 0 0 0) (v128.const f32x4 3 0 0 0) (v128.const f32x4 4 0 0 0))
                        (v128.const f32x4 -2 0 0 0)))))
                  (func (export "trunc") (result i32)
                    (i32x4.all_true (i32x4.eq
                      (i32x4.relaxed_trunc_f32x4_s (v128.const f32x4 1.9 -1.9 0 0))
                      (v128.const i32x4 1 4294967295 0 0))))
                  (func (export "dot") (result i32)
                    (i16x8.all_true (i16x8.eq
                      (i16x8.relaxed_dot_i8x16_i7x16_s
                        (v128.const i8x16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
                        (v128.const i8x16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))
                      (v128.const i16x8 1 13 41 85 145 221 313 421))))
                  (func (export "dotadd") (result i32)
                    (i32x4.all_true (i32x4.eq
                      (i32x4.relaxed_dot_i8x16_i7x16_add_s
                        (v128.const i8x16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
                        (v128.const i8x16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
                        (v128.const i32x4 0 1 2 3))
                      (v128.const i32x4 14 127 368 737)))))
                """#
            )
        )
        let instance = try module.instantiate(store: Store(engine: Engine()))
        for name in ["madd", "trunc", "dot", "dotadd"] {
            let f = try #require(instance.exports[function: name])
            #expect(try f() == [.i32(1)], "relaxed-simd \(name) produced wrong result")
        }
    }

    @Test
    func updateCurrentMemoryCacheOnGrow() throws {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (memory 0)
                    (func (export "_start") (result i32)
                        (drop (memory.grow (i32.const 1)))
                        (i32.store (i32.const 1) (i32.const 42))
                        (i32.load (i32.const 1))
                    )
                )
                """
            )
        )
        let engine = Engine()
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    func expectTrap(_ wat: String, assertTrap: (Trap) throws -> Void) throws {
        let module = try parseWasm(
            bytes: wat2wasm(wat, options: EncodeOptions(nameSection: true))
        )

        let engine = Engine()
        let store = Store(engine: engine)
        var imports = Imports()
        for importEntry in module.imports {
            guard case .function(let type) = importEntry.descriptor else { continue }
            let function = try Function(
                store: store,
                type: module.resolveFunctionType(type),
                body: { _, _ in
                    return []
                }
            )
            imports.define(importEntry, .function(function))
        }
        let instance = try module.instantiate(store: store, imports: imports)
        let _start = try #require(instance.exports[function: "_start"])

        let trap: Trap
        do {
            let _ = try _start()
            #expect((false), "Expected trap")
            return
        } catch let _trap as Trap {
            trap = _trap
        } catch {
            #expect((false), "Expected trap: \(error)")
            return
        }
        try assertTrap(trap)
    }

    @Test
    func backtraceBasic() throws {
        try expectTrap(
            """
            (module
                (func $foo
                    unreachable
                )
                (func $bar
                    (call $foo)
                )
                (func (export "_start")
                    (call $bar)
                )
            )
            """
        ) { trap in
            #expect(
                trap.backtrace?.symbols.compactMap(\.name) == [
                    "foo",
                    "bar",
                    "_start",
                ])
        }
    }

    @Test
    func backtraceWithImports() throws {
        try expectTrap(
            """
            (module
                (func (import "env" "bar"))
                (func
                    unreachable
                )
                (func $bar
                    (call 1)
                )
                (func (export "_start")
                    (call $bar)
                )
            )
            """
        ) { trap in
            #expect(
                trap.backtrace?.symbols.compactMap(\.name) == [
                    "wasm function[1]",
                    "bar",
                    "_start",
                ])
        }
    }

    @Test
    func multiMemoryBulkOpsMutateTheIndexedMemory() throws {
        // Cross-memory `memory.copy 1 0` is the path no vendored file exercises; verified host-side via memory 1.
        let features: WasmFeatureSet = [.referenceTypes, .multiMemory]
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (memory 1)                  ;; memory 0, copy source
                  (memory (export "mem") 1)   ;; memory 1, fill/copy/init target
                  (data (memory 0) (i32.const 0) "\\aa\\bb\\cc\\dd")  ;; active -> memory 0
                  (data "\\11\\22\\33\\44")                           ;; passive segment 1
                  (func (export "fillM1")
                    (memory.fill 1 (i32.const 0) (i32.const 0x07) (i32.const 3)))
                  (func (export "copyToM1")
                    (memory.copy 1 0 (i32.const 8) (i32.const 0) (i32.const 4)))
                  (func (export "initM1")
                    (memory.init 1 1 (i32.const 16) (i32.const 0) (i32.const 4)))
                  (func (export "fillOOB")
                    (memory.fill 1 (i32.const 0) (i32.const 0) (i32.const 0x1_0001))))
                """,
                features: features
            ),
            features: features
        )
        let engine = Engine(configuration: EngineConfiguration(features: features))
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)

        let fillM1 = try #require(instance.exports[function: "fillM1"])
        let copyToM1 = try #require(instance.exports[function: "copyToM1"])
        let initM1 = try #require(instance.exports[function: "initM1"])
        _ = try fillM1()
        _ = try copyToM1()
        _ = try initM1()

        let mem = try #require(instance.exports[memory: "mem"])
        mem.withUnsafeBufferPointer(offset: 0, count: 24) { buffer in
            #expect(Array(buffer[0..<3]) == [0x07, 0x07, 0x07])  // memory.fill into memory 1
            #expect(Array(buffer[8..<12]) == [0xaa, 0xbb, 0xcc, 0xdd])  // cross-memory memory.copy 1 0
            #expect(Array(buffer[16..<20]) == [0x11, 0x22, 0x33, 0x44])  // memory.init from passive segment 1
        }

        // The indexed bulk path traps on out-of-bounds just like memory 0.
        let fillOOB = try #require(instance.exports[function: "fillOOB"])
        #expect(throws: Trap.self) { _ = try fillOOB() }
    }
}
