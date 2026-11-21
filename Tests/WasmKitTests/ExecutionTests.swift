import Testing
import WAT

@testable import WasmKit

@Suite
struct ExecutionTests {

    @Test
    func dropWithRelinkingOptimization() throws {
        let engine = Engine()
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
            ),
            engine: engine
        )
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    @Test
    func updateCurrentMemoryCacheOnGrow() throws {
        let engine = Engine()
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
            ),
            engine: engine
        )
        let store = Store(engine: engine)
        let instance = try module.instantiate(store: store)
        let _start = try #require(instance.exports[function: "_start"])
        let results = try _start()
        #expect(results == [.i32(42)])
    }

    /// A tail call to a host function moves the arguments over the caller's
    /// saved slots, and the host function's results have to reach the caller's
    /// caller.
    @Test
    func tailCallHostFunction() throws {
        let engine = Engine()
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                    (import "env" "sum5" (func $sum5 (param i64 i64 i64 i64 i64) (result i64)))
                    (func $tail (result i64)
                        (return_call $sum5
                            (i64.const 1) (i64.const 20) (i64.const 300) (i64.const 4000) (i64.const 50000)))
                    (func (export "_start") (param i64) (result i64)
                        (i64.add (call $tail) (local.get 0)))
                )
                """
            ),
            engine: engine
        )
        let store = Store(engine: engine)
        var imports = Imports()
        imports.define(
            module: "env", name: "sum5",
            try Function(store: store, parameters: Array(repeating: .i64, count: 5), results: [.i64]) { _, args in
                [.i64(args.reduce(0) { $0 + $1.i64 })]
            })
        let instance = try module.instantiate(store: store, imports: imports)
        let _start = try #require(instance.exports[function: "_start"])
        #expect(try _start([.i64(600000)]) == [.i64(654321)])
    }

    func expectTrap(_ wat: String, assertTrap: (Trap) throws -> Void) throws {
        let engine = Engine()
        let module = try parseWasm(
            bytes: wat2wasm(wat, options: EncodeOptions(nameSection: true)),
            engine: engine
        )

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

    /// A function body whose final `end` is followed by more operators is
    /// malformed. The expression parser only stops at an `end` that exhausts the
    /// code entry, so the translator has to reject the trailing operators itself
    /// instead of translating them against the finished root frame.
    @Test
    func rejectsOperatorsAfterEndOfFunctionBody() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,  // magic and version
            0x01, 0x04, 0x01, 0x60, 0x00, 0x00,  // type: [0] = () -> ()
            0x03, 0x02, 0x01, 0x00,  // function: [0] : type 0
            // code: [0] = no locals, `end`, then a trailing `nop` and `end`
            0x0A, 0x06, 0x01, 0x04, 0x00, 0x0B, 0x01, 0x0B,
        ]
        let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
        let module = try parseWasm(bytes: bytes, engine: engine)
        let store = Store(engine: engine)
        let error = #expect(throws: WasmKitError.self) {
            try module.instantiate(store: store)
        }
        #expect(
            error?.description.contains(#"Instruction cannot be appeared after "end" of function"#) == true,
            "expected a validation error, got \(error.map(String.init(describing:)) ?? "no error")"
        )
    }

    /// An `if` block can only have one `else`. A second one used to reach
    /// `pinLabelHere` for a label the first `else` had already pinned.
    @Test
    func rejectsASecondElseInTheSameIfBlock() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,  // magic and version
            0x01, 0x04, 0x01, 0x60, 0x00, 0x00,  // type: [0] = () -> ()
            0x03, 0x02, 0x01, 0x00,  // function: [0] : type 0
            // code: [0] = no locals, `i32.const 0`, `if`, `else`, `else`, `end`, `end`
            0x0A, 0x0B, 0x01, 0x09, 0x00, 0x41, 0x00, 0x04, 0x40, 0x05, 0x05, 0x0B, 0x0B,
        ]
        let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
        let module = try parseWasm(bytes: bytes, engine: engine)
        let store = Store(engine: engine)
        let error = #expect(throws: WasmKitError.self) {
            try module.instantiate(store: store)
        }
        #expect(
            error?.description.contains("expected `if` control frame on top of the stack for `else`") == true,
            "expected a validation error, got \(error.map(String.init(describing:)) ?? "no error")"
        )
    }

    @Test
    func rejectsFunctionImportOfStructType() throws {
        let engine = Engine()
        // (module (type (struct)) (import "m" "f" (func (type 0))))
        let module = try parseWasm(
            bytes: [
                0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
                0x01, 0x03, 0x01, 0x5F, 0x00,
                0x02, 0x07, 0x01, 0x01, 0x6D, 0x01, 0x66, 0x00, 0x00,
            ],
            engine: engine,
            features: [.referenceTypes, .exceptionHandling, .gc]
        )
        let store = Store(engine: engine)
        let function = try Function(store: store, parameters: []) { _, _ in [] }
        let error = try #require(throws: WasmKitError.self) {
            try module.instantiate(store: store, imports: ["m": ["f": function]])
        }
        #expect(error.description == "Type index 0 does not define a function type")
    }
}
