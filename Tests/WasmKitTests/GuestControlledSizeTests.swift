import Testing
import WAT

@testable import WasmKit

/// A guest picks its own sizes, indices and offsets. None of them may abort the
/// host process, leak host memory, or be trusted past a bounds check.
@Suite
struct GuestControlledSizeTests {

    private static func instantiate(
        _ wat: String,
        compilationMode: EngineConfiguration.CompilationMode = .eager,
        boundsChecking: EngineConfiguration.MemoryBoundsChecking? = nil
    ) throws -> (Instance, Store) {
        let module = try parseWasm(bytes: try wat2wasm(wat, features: .all), features: .all)
        let engine = Engine(
            configuration: EngineConfiguration(
                compilationMode: compilationMode, memoryBoundsChecking: boundsChecking
            )
        )
        let store = Store(engine: engine)
        return (try module.instantiate(store: store), store)
    }

    /// Each of these used to abort the host with a Swift runtime failure, because
    /// a guest `i64` was narrowed with `Int(_:)` before the bounds check that
    /// follows it.
    @Test(
        arguments: [
            #"(module (table $t i64 0 funcref) (func (export "f") (result i64) (table.grow $t (ref.null func) (i64.const 0x8000000000000000))))"#,
            #"(module (table i64 1 funcref) (func (export "f") (i64.const 0) (ref.null func) (i64.const 0x8000000000000000) (table.fill 0)))"#,
            #"(module (table i64 1 funcref) (func (export "f") (i64.const 0) (i64.const 0) (i64.const 0x8000000000000000) (table.copy 0 0)))"#,
            #"(module (table i64 1 funcref) (func (export "f") (result funcref) (table.get 0 (i64.const -1))))"#,
            #"(module (type $t (func)) (table i64 1 funcref) (func (export "f") (call_indirect 0 (type $t) (i64.const -1))))"#,
            #"(module (memory i64 1) (func (export "f") (result i64) (memory.grow (i64.const 0x8000000000000000))))"#,
            #"(module (memory i64 1) (func (export "f") (i64.const 0) (i32.const 0) (i64.const 0x8000000000000000) (memory.fill)))"#,
            // `checkGrow`: the page total and its byte count each overflow.
            #"(module (memory i64 1) (func (export "f") (result i64) (memory.grow (i64.const 0x7FFFFFFFFFFFFFFF))))"#,
            #"(module (memory i64 0) (func (export "f") (result i64) (memory.grow (i64.const 0x0004000000000000))))"#,
        ]
    )
    func aHugeGuestOperandIsATrapNotAHostAbort(wat: String) throws {
        let (instance, _) = try Self.instantiate(wat)
        let f = try #require(instance.exports[function: "f"])
        // Either a clean Wasm trap or a defined failure value; never a crash.
        _ = try? f()
    }

    /// `(module (table 0xffffffff funcref))` is 41 bytes, valid under plain MVP,
    /// and used to abort with `failed to allocate 68719476752 bytes`.
    @Test func aTableTooLargeToAllocateIsRejected() throws {
        #expect(throws: (any Error).self) {
            _ = try Self.instantiate(#"(module (table 0xffffffff funcref))"#)
        }
    }

    /// Interpreter encoding limits that a plain MVP module can exceed.
    @Test func aBranchTableBeyondTheInterpretersCountIsRejected() throws {
        let targets = String(repeating: "0 ", count: 65536)
        #expect(throws: (any Error).self) {
            _ = try Self.instantiate("(module (func (export \"f\") (block (br_table \(targets) (i32.const 0)))))")
        }
    }

    @Test func aBlockTypeBeyondTheInterpretersSlotCountIsRejected() throws {
        let results = String(repeating: "i32 ", count: 70000)
        #expect(throws: (any Error).self) {
            _ = try Self.instantiate("(module (type $t (func (result \(results)))) (func (export \"f\") (type $t) unreachable))")
        }
    }

    /// `select` with a result type validated nothing: it pushed the operand's
    /// type but took the copy width from the annotation, so only half of a
    /// `v128` was written and the rest of the result was whatever the stack
    /// slot happened to hold -- host data, observable by the guest.
    @Test func typedSelectRejectsOperandsThatDoNotMatchTheAnnotation() throws {
        let wat = """
            (module (func (export "f") (param i32) (result v128)
              v128.const i64x2 0x1010101010101010 0x2020202020202020
              v128.const i64x2 0x3030303030303030 0x4040404040404040
              local.get 0
              (select (result i64))))
            """
        #expect(throws: (any Error).self) {
            _ = try Self.instantiate(wat)
        }
    }

    /// A host function may re-enter the guest and grow the caller's memory. A
    /// malloc-backed memory is reallocated by `grow`, so the interpreter's
    /// cached base/bound has to be refreshed when the host call returns --
    /// otherwise the next load or store goes through a freed pointer.
    @Test func aHostCallThatGrowsMemoryDoesNotLeaveTheCachedMemoryStale() throws {
        let wat = """
            (module
              (import "env" "cb" (func $cb))
              (memory (export "mem") 1 100)
              (func (export "growit") (result i32) (memory.grow (i32.const 8)))
              (func (export "start") (result i32)
                (call $cb)
                ;; Only in bounds once the callback has grown the memory, so a
                ;; stale cached bound rejects it and a stale cached base writes
                ;; through freed storage.
                (i32.store (i32.const 100000) (i32.const 0x5A5A5A5A))
                (i32.load (i32.const 100000))))
            """
        let module = try parseWasm(bytes: try wat2wasm(wat, features: .all), features: .all)
        // Software bounds checking uses the malloc backing, where growing moves
        // the buffer. Under mprotect the base is stable and the bug only shows
        // up as a spurious trap.
        let engine = Engine(
            configuration: EngineConfiguration(compilationMode: .eager, memoryBoundsChecking: .software)
        )
        let store = Store(engine: engine)

        // The callback re-enters the guest, which is what moves the memory.
        final class Box: @unchecked Sendable { var instance: Instance? }
        let box = Box()
        var imports = Imports()
        imports.define(
            module: "env", name: "cb",
            Function(store: store, type: FunctionType(parameters: [], results: [])) { _, _ in
                _ = try box.instance?.exports[function: "growit"]?()
                return []
            }
        )
        let instance = try module.instantiate(store: store, imports: imports)
        box.instance = instance

        let start = try #require(instance.exports[function: "start"])
        #expect(try start() == [.i32(0x5A5A_5A5A)])
    }
}
