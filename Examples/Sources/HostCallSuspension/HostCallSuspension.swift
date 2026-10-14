/// This example demonstrates a host function that suspends the guest instead of returning, so that
/// the embedder can do the host function's work outside of it, and the two ways to end such a host
/// call with an error.

import WasmKit
import WAT

@main
struct Example {
    static let wat = """
        (module
          (import "env" "lookup" (func $lookup (param i32) (result i32)))
          (tag $missing)
          (func (export "missing") (throw $missing))
          (func (export "total") (result i32)
            (i32.add (call $lookup (i32.const 1)) (call $lookup (i32.const 2))))
          (func (export "guarded") (result i32)
            (block $caught
              (try_table (catch $missing $caught)
                (return (call $lookup (i32.const 3)))))
            (i32.const 0)))
        """

    static func main() async throws {
        // Exception handling, which the guest's try_table needs, is on by default.
        let store = Store(engine: Engine())
        var lookups = 0
        let lookup = Function(store: store, parameters: [.i32], results: [.i32]) { _, arguments in
            lookups += 1
            // The answer is not ready here. Suspend the guest rather than block this thread.
            throw SuspensionRequest(tag: UInt64(arguments[0].i32))
        }
        let module = try parseWasm(bytes: try wat2wasm(wat))
        let instance = try module.instantiate(store: store, imports: ["env": ["lookup": lookup]])

        // Each host call is answered after an `await`, outside the host function, which does not
        // run again. The guest continues right after the call.
        let total = try ResumableCall(function: instance.exports[function: "total"]!)
        var status = try total.resume()
        while case .suspended(let suspension) = status {
            guard case .hostCall(let key, _) = suspension.reason else {
                fatalError("only host calls suspend this guest")
            }
            let value = await answer(key)
            print("lookup(\(key)) answered with \(value)")
            status = try total.resume(returning: [.i32(value)], answering: suspension)
        }
        if case .returned(let results) = status {
            print("total returned \(results), and the host function ran \(lookups) times")
        }

        // A WebAssembly exception for the guest to catch, taken from the guest itself.
        var exception: (any Error)?
        do { _ = try instance.exports[function: "missing"]!() } catch { exception = error }

        // Failing a host call is what throwing from the host function would have done, so the guest's
        // handler catches the exception.
        let guarded = try ResumableCall(function: instance.exports[function: "guarded"]!)
        if case .suspended(let suspension) = try guarded.resume(),
            case .returned(let results) = try guarded.resume(failing: exception!, answering: suspension)
        {
            print("failing lookup(3) let the guest catch it, and guarded returned \(results)")
        }

        // Cancelling ends the call where it is. The guest cannot catch anything, so an exception is
        // refused and any other error comes straight back.
        let cancelled = try ResumableCall(function: instance.exports[function: "guarded"]!)
        _ = try cancelled.resume()
        do {
            try cancelled.resume(throwing: exception!)
        } catch let error as ResumableCallError {
            print("cancelling with the exception was refused: \(error)")
        }
        do {
            try cancelled.resume(throwing: CancellationError())
        } catch {
            print("cancelling threw \(error), and the call is finished: \(cancelled.isFinished)")
        }
    }

    /// Stands in for work that finishes later, such as a network request.
    static func answer(_ key: UInt64) async -> UInt32 {
        await Task.yield()
        return UInt32(key) * 100
    }
}
