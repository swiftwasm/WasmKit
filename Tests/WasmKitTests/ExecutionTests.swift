import Testing
import WAT

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
        let module = try parseWasm(bytes: bytes)
        let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
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
        let module = try parseWasm(bytes: bytes)
        let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
        let store = Store(engine: engine)
        let error = #expect(throws: WasmKitError.self) {
            try module.instantiate(store: store)
        }
        #expect(
            error?.description.contains("expected `if` control frame on top of the stack for `else`") == true,
            "expected a validation error, got \(error.map(String.init(describing:)) ?? "no error")"
        )
    }
}
