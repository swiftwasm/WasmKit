import Testing
import WAT
import WasmParser

@testable import WasmKit

/// Errors from host functions that the guest reaches through a tail call.
///
/// A tail call moves its arguments to the start of the caller's parameter area and runs the host
/// function in a frame placed above them. The arguments and the new frame's saved slots may land
/// on the caller's saved slots. A trap from the host function is still reported from the caller's
/// frame, so building its backtrace reads those slots.
///
/// Every store checks bounds in software. The guest's description relies on that, and the tests
/// check the configuration the engine settles on, since an argument only requests it.
@Suite
struct TailCallHostTrapTests {
    /// The guest.
    ///
    /// Each tail caller has one parameter slot, four constant slots and no locals, so its saved
    /// slots are slots 5, 6 and 7 of its parameter area. `spill` passes eight arguments to `wide`,
    /// which cover all three. `indirect` passes the same arguments through the table and `byRef`
    /// through a function reference. `partial` passes three arguments to `three`. They stay below
    /// the saved slots, but the host frame's own saved slots then start at slot 3, so its saved SP
    /// lands on the caller's saved function. `short` passes one argument and reaches no saved slot,
    /// and `plain` calls `wide` without a tail call. Each `run_` export multiplies its callee's
    /// result by three, so its frame stays below the callee's.
    static let wat = """
        (module
          (type $wideType (func (param i32 i32 i32 i32 i32 i32 i32 i32) (result i32)))
          (import "env" "wide" (func $wide (type $wideType)))
          (import "env" "three" (func $three (param i32 i32 i32) (result i32)))
          (import "env" "one" (func $one (param i32) (result i32)))
          (table funcref (elem $wide))
          (tag $t (param i32))
          (func $spill (export "spill") (param i32) (result i32)
            (return_call $wide
              (local.get 0) (i32.const 1) (i32.const 2) (i32.const 3)
              (i32.const 4) (i32.const 5) (i32.const 6) (i32.const 7)))
          (func $indirect (export "indirect") (param i32) (result i32)
            (return_call_indirect (type $wideType)
              (local.get 0) (i32.const 1) (i32.const 2) (i32.const 3)
              (i32.const 4) (i32.const 5) (i32.const 6) (i32.const 7) (i32.const 0)))
          (func $byRef (export "byRef") (param i32) (result i32)
            (return_call_ref $wideType
              (local.get 0) (i32.const 1) (i32.const 2) (i32.const 3)
              (i32.const 4) (i32.const 5) (i32.const 6) (i32.const 7) (ref.func $wide)))
          (func $partial (export "partial") (param i32) (result i32)
            (return_call $three (local.get 0) (i32.const 1) (i32.const 2)))
          (func $short (export "short") (param i32) (result i32)
            (return_call $one (local.get 0)))
          (func $plain (export "plain") (param i32) (result i32)
            (call $wide
              (local.get 0) (i32.const 1) (i32.const 2) (i32.const 3)
              (i32.const 4) (i32.const 5) (i32.const 6) (i32.const 7)))
          (func (export "run_spill") (param i32) (result i32) (i32.mul (call $spill (local.get 0)) (i32.const 3)))
          (func (export "run_indirect") (param i32) (result i32) (i32.mul (call $indirect (local.get 0)) (i32.const 3)))
          (func (export "run_byRef") (param i32) (result i32) (i32.mul (call $byRef (local.get 0)) (i32.const 3)))
          (func (export "run_partial") (param i32) (result i32) (i32.mul (call $partial (local.get 0)) (i32.const 3)))
          (func (export "run_short") (param i32) (result i32) (i32.mul (call $short (local.get 0)) (i32.const 3)))
          (func (export "run_plain") (param i32) (result i32) (i32.mul (call $plain (local.get 0)) (i32.const 3)))
          (func (export "raise") (param i32) (throw $t (local.get 0)))
          (func (export "caught") (param i32) (result i32)
            (block $h (result i32)
              (try_table (result i32) (catch $t $h)
                (i32.mul (call $spill (local.get 0)) (i32.const 3))))))
        """

    /// The features of ``wat``. `byRef` needs typed function references.
    static let features: WasmFeatureSet = [.tailCall, .exceptionHandling, .referenceTypes, .functionReferences]

    /// A function of the guest that reaches a host function.
    enum Path: String, CaseIterable, Sendable {
        case spill, indirect, byRef, partial, short, plain

        /// The export that calls this function and multiplies its result by three.
        var runner: String { "run_\(rawValue)" }

        /// The import that this function calls.
        var host: String {
            switch self {
            case .spill, .indirect, .byRef, .plain: "wide"
            case .partial: "three"
            case .short: "one"
            }
        }

        /// The arguments that the host function receives when the runner is called with 9.
        var arguments: [Value] {
            let count =
                switch self {
                case .spill, .indirect, .byRef, .plain: 8
                case .partial: 3
                case .short: 1
                }
            return [.i32(9)] + (1..<count).map { .i32(UInt32($0)) }
        }
    }

    /// How a test enters the guest.
    enum Entry: String, CaseIterable, Sendable {
        /// A plain call of the export.
        case synchronous
        /// A ``ResumableCall`` of the export.
        case resumable
    }

    /// An engine configuration together with an entry, so that one argument list covers both.
    struct Variant: Sendable, CustomTestStringConvertible {
        let threadingModel: EngineConfiguration.ThreadingModel
        let epochInterruption: Bool
        let entry: Entry
        var testDescription: String {
            "\(threadingModel) \(epochInterruption ? "epoch" : "no epoch") \(entry)"
        }
    }

    /// Every tested threading model, with and without epoch interruption, through either entry.
    static let variants: [Variant] = testedThreadingModels.flatMap { model in
        [false, true].flatMap { epoch in
            Entry.allCases.map { Variant(threadingModel: model, epochInterruption: epoch, entry: $0) }
        }
    }

    /// The trap that the host functions throw.
    static let hostTrap = Trap(.message(.init("host trap")))

    /// An error from a host function that is not a trap.
    struct HostFailure: Error, Equatable {}

    /// The arguments of every host call, by import name.
    final class Calls {
        var arguments: [String: [[Value]]] = [:]
    }

    /// A store with the guest instantiated in it.
    struct Guest {
        let store: Store
        let instance: Instance
        let calls: Calls

        /// The export named `name`.
        func export(_ name: String) throws -> Function {
            try #require(instance.exports[function: name])
        }
    }

    /// Instantiates the guest with the same host function behind every import.
    ///
    /// With epoch interruption, the store gets a deadline that the guest never reaches, since
    /// nothing advances the epoch. The guest then runs its epoch checks without stopping.
    ///
    /// - Parameters:
    ///   - threadingModel: The threading model to request.
    ///   - epochInterruption: Whether the engine instruments the guest with epoch checks.
    ///   - host: The host function. It receives the arguments and how many times the import it runs
    ///     as has been called, this call included.
    /// - Returns: The guest, which records the arguments of every host call.
    /// - Throws: Encoding, parsing or instantiation failures.
    static func makeGuest(
        _ threadingModel: EngineConfiguration.ThreadingModel, epochInterruption: Bool = false,
        host: @escaping (_ arguments: [Value], _ call: Int) throws -> [Value]
    ) throws -> Guest {
        let store = Store(
            engine: Engine(
                configuration: EngineConfiguration(
                    threadingModel: threadingModel, features: features, memoryBoundsChecking: .software,
                    epochInterruption: epochInterruption)))
        let configuration = store.engine.configuration
        #expect(configuration.threadingModel == threadingModel)
        #expect(configuration.memoryBoundsChecking == .software)
        #expect(configuration.epochInterruption == epochInterruption)
        if epochInterruption {
            store.setEpochDeadline(ticksBeyondCurrent: 1000)
        }
        let module = try parseWasm(
            bytes: wat2wasm(wat, features: features, options: EncodeOptions(nameSection: true)), features: features)
        let calls = Calls()
        var imports = Imports()
        for (name, count) in [("wide", 8), ("three", 3), ("one", 1)] {
            imports.define(
                module: "env", name: name,
                Function(store: store, parameters: Array(repeating: .i32, count: count), results: [.i32]) {
                    _, arguments in
                    calls.arguments[name, default: []].append(arguments)
                    return try host(arguments, calls.arguments[name, default: []].count)
                })
        }
        return Guest(store: store, instance: try module.instantiate(store: store, imports: imports), calls: calls)
    }

    /// The wrapping sum of `values`, which a host function returns when it does not fail.
    static func sum(_ values: [Value]) -> UInt32 {
        values.reduce(0) { $0 &+ $1.i32 }
    }

    /// Checks that `trap` is ``hostTrap`` and that its backtrace names exactly `frames`, innermost
    /// first. A missing trap has already been recorded by the caller's expectation.
    static func expectHostTrap(_ trap: Trap?, frames: [String?], sourceLocation: SourceLocation = #_sourceLocation) {
        guard let trap else { return }
        #expect(trap.reason.description == "host trap", sourceLocation: sourceLocation)
        #expect(trap.backtrace?.symbols.map(\.name) == frames, sourceLocation: sourceLocation)
    }

    /// Confirms the frame layout that the guest's description relies on.
    @Test(arguments: testedThreadingModels, [false, true])
    func theTailCallersSavedSlotsAreSlotsFiveToSeven(
        threadingModel: EngineConfiguration.ThreadingModel, epochInterruption: Bool
    ) throws {
        let guest = try Self.makeGuest(threadingModel, epochInterruption: epochInterruption) { _, _ in [] }
        for path in [Path.spill, .indirect, .byRef, .partial, .short] {
            let code = try guest.export(path.rawValue).handle.wasm.ensureCompiled(store: StoreRef(guest.store))
            #expect(code.entryOffset - StackLayout.numberOfSavingSlots == 5, "\(path)")
        }
    }

    /// Reports a host function's trap from the frame that reached it, whichever way it did, and
    /// leaves the store able to run the same call again.
    ///
    /// Through `spill`, `indirect` and `byRef`, the arguments cover the caller's saved slots, which
    /// the backtrace starts from. Through `partial`, only the saved function is covered, so a stale
    /// slot would show as a wrong frame name rather than a crash. `short` and `plain` reach no
    /// saved slot.
    @Test(arguments: variants, Path.allCases)
    func aHostTrapNamesTheFramesBelowTheHostFunction(_ variant: Variant, path: Path) throws {
        let guest = try Self.makeGuest(variant.threadingModel, epochInterruption: variant.epochInterruption) {
            arguments, call in
            guard call > 1 else { throw Self.hostTrap }
            return [.i32(Self.sum(arguments))]
        }
        let runner = try guest.export(path.runner)
        let expected: [Value] = [.i32(Self.sum(path.arguments) &* 3)]
        switch variant.entry {
        case .synchronous:
            let trap = #expect(throws: Trap.self) { try runner([.i32(9)]) }
            Self.expectHostTrap(trap, frames: [path.rawValue, path.runner])
            #expect(guest.calls.arguments[path.host] == [path.arguments])
            #expect(try runner([.i32(9)]) == expected)
        case .resumable:
            let call = try ResumableCall(function: runner, arguments: [.i32(9)])
            let trap = #expect(throws: Trap.self) { _ = try call.resume() }
            Self.expectHostTrap(trap, frames: [path.rawValue, path.runner])
            #expect(guest.calls.arguments[path.host] == [path.arguments])
            #expect(call.isFinished)
            // The trap finished the call, so its stack is free for the next one.
            guard let stack = call.takeStack() else {
                Issue.record("expected the stack of the finished call")
                return
            }
            let next = try ResumableCall(function: runner, arguments: [.i32(9)], on: stack)
            guard case .returned(let results) = try next.resume() else {
                Issue.record("expected the next call to return")
                return
            }
            #expect(results == expected)
        }
        #expect(guest.calls.arguments[path.host]?.count == 2)
    }

    /// Delivers each host function's result through every path when nothing fails.
    @Test(arguments: testedThreadingModels, Entry.allCases)
    func everyPathReturnsTheHostsResult(threadingModel: EngineConfiguration.ThreadingModel, entry: Entry) throws {
        let guest = try Self.makeGuest(threadingModel) { arguments, _ in [.i32(Self.sum(arguments))] }
        for path in Path.allCases {
            let runner = try guest.export(path.runner)
            let results: [Value]
            switch entry {
            case .synchronous:
                results = try runner([.i32(9)])
            case .resumable:
                guard case .returned(let returned) = try ResumableCall(function: runner, arguments: [.i32(9)]).resume()
                else {
                    Issue.record("expected \(path) to return")
                    continue
                }
                results = returned
            }
            #expect(results == [.i32(Self.sum(path.arguments) &* 3)], "\(path)")
        }
    }

    /// Passes an error that is not a trap through unchanged, and leaves the store able to run the
    /// same call again.
    @Test(arguments: testedThreadingModels, Entry.allCases)
    func aHostErrorThatIsNotATrapPassesThrough(threadingModel: EngineConfiguration.ThreadingModel, entry: Entry) throws {
        let guest = try Self.makeGuest(threadingModel) { arguments, call in
            guard call > 1 else { throw HostFailure() }
            return [.i32(Self.sum(arguments))]
        }
        let runner = try guest.export("run_spill")
        #expect(throws: HostFailure()) {
            switch entry {
            case .synchronous: _ = try runner([.i32(9)])
            case .resumable: _ = try ResumableCall(function: runner, arguments: [.i32(9)]).resume()
            }
        }
        #expect(guest.calls.arguments["wide"] == [Path.spill.arguments])
        #expect(try runner([.i32(9)]) == [.i32(111)])
    }

    /// Lets a handler below the tail caller catch the exception that the host function throws.
    @Test(arguments: testedThreadingModels)
    func aGuestHandlerCatchesTheHostsException(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var exception: WasmKitException?
        let guest = try Self.makeGuest(threadingModel) { _, _ in
            guard let exception else { throw HostFailure() }
            throw exception
        }
        exception = #expect(throws: WasmKitException.self) { try guest.export("raise")([.i32(77)]) }
        #expect(try guest.export("caught")([.i32(9)]) == [.i32(77)])
        #expect(guest.calls.arguments["wide"] == [Path.spill.arguments])
    }
}
