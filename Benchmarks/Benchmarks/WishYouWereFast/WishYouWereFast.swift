import Benchmark
import WasmKit
import WasmKitWASI
import Foundation
import SystemPackage

let benchmarks = {
    let wishYouWereFast = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Vendor")
        .appendingPathComponent("wish-you-were-fast")
        .appendingPathComponent("wasm")
        .appendingPathComponent("suites")
        .appendingPathComponent("libsodium")

    let devNull = try! FileDescriptor.open("/dev/null", .readWrite)

    for file in try! FileManager.default.contentsOfDirectory(
        atPath: wishYouWereFast.path
    ) {
        guard file.hasSuffix(".wasm") else { continue }
        Benchmark("\(file)", configuration: .init(thresholds: [
            .peakMemoryResident: .relaxed,
        ])) { benchmark in
            let engine = Engine()
            let store = Store(engine: engine)
            let module = try parseWasm(
                filePath: FilePath(wishYouWereFast.appendingPathComponent(file).path)
            )
            let wasi = try WASIBridgeToHost(stdout: devNull, stderr: devNull)
            var imports = Imports()
            wasi.link(to: &imports, store: store)
            let instance = try module.instantiate(store: store, imports: imports)
            _ = try wasi.start(instance)
        }
    }
}
