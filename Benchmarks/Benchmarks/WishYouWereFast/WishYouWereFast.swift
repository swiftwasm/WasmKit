import Benchmark
import WasmKit
import WasmKitWASI
import Foundation

let benchmarks: @Sendable () -> () = {
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

    let devNull = FileHandle(forUpdatingAtPath: "/dev/null")!.fileDescriptor

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
                filePath: wishYouWereFast.appendingPathComponent(file).path
            )
            let wasi = try WASIBridgeToHost(fileSystem: .host().withStdio(stdout: devNull, stderr: devNull))
            _ = try wasi.runAndClose { wasi in
                var imports = Imports()
                wasi.link(to: &imports, store: store)
                let instance = try module.instantiate(store: store, imports: imports)
                return try wasi.start(instance)
            }
        }
    }
}
