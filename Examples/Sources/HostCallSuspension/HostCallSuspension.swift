/// This example demonstrates how a host function can suspend the guest until its result is ready.

import WasmKit
import WAT

@main
struct Example {
    static let wat = """
        (module
          (import "env" "lookup" (func $lookup (param i32) (result i32)))
          (func (export "total") (result i32)
            (i32.add (call $lookup (i32.const 1)) (call $lookup (i32.const 2)))))
        """

    static func main() async throws {
        let store = Store(engine: Engine())
        var lookups = 0
        let lookup = Function(store: store, parameters: [.i32], results: [.i32]) { _, arguments in
            lookups += 1
            // Suspend instead of blocking this thread until the result is ready.
            throw SuspensionRequest(id: UInt64(arguments[0].i32))
        }
        let module = try parseWasm(bytes: try wat2wasm(wat))
        let instance = try module.instantiate(store: store, imports: ["env": ["lookup": lookup]])
        let total = instance.exports[function: "total"]!

        let call = try ResumableCall(function: total)
        var status = try call.resume()
        while case .suspended(let suspension) = status, case .hostCall(let id, _) = suspension.reason {
            let value = await fetchValue(for: id)
            print("lookup(\(id)) = \(value)")
            status = try call.resume(returning: [.i32(value)])
        }
        if case .returned(let results) = status {
            print("total returned \(results), and lookup ran \(lookups) times")
        }

        let cancelled = try ResumableCall(function: total)
        _ = try cancelled.resume()
        do {
            try cancelled.resume(throwing: CancellationError())
        } catch {
            print("cancelling threw \(error), and the call is finished: \(cancelled.isFinished)")
        }
    }

    /// Stands in for work that finishes later, such as a network request.
    static func fetchValue(for id: UInt64) async -> UInt32 {
        await Task.yield()
        return UInt32(id) * 100
    }
}
