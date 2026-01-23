import Benchmark
import Foundation
import WAT
import WasmKit

let benchmarks: @Sendable () -> () = {
    Benchmark("parseWasmBenchmark", closure: { (benchmark: Benchmark, setupResult: [(path: String, location: Location, bytes: [UInt8])]) in
        for _ in benchmark.scaledIterations {
            for (path, location, bytes) in setupResult {
                blackHole({ () -> Module? in
                    do {
                        let module = try parseWasm(bytes: bytes, features: .all)
                        return module
                    } catch {
                        print("Found error while parsing \(path) at \(location): \(error)")
                    }
                    return nil
                }())
            }
        }
    }, setup: {
        let packagePath = FilePath(#filePath)
            .removingLastComponent()
            .removingLastComponent()
            .removingLastComponent()
            .removingLastComponent()

        let spectestsPath = packagePath
            .appending(["Vendor", "testsuite"])

        let wastOutputPath = packagePath.appending(".build")

        var wasm = [(path: String, location: Location, bytes: [UInt8])]()
        for path in FileManager.shared.contentsOfDirectory(atPath: spectestsPath.string) {
            guard path.extension == "wast" else { continue }

            do {
                var wast = try parseWAST(.init(contentsOf: path), features: .all)
                var lastModule: (location: Location, wat: Wat)?
                while let (directive, _) = try wast.nextDirective() {
                    switch directive {
                    case .module(let wat):
                        guard case .text(let source) = wat.source else { continue }
                        lastModule = (wat.location, source)

                    case .assertReturn:
                        guard var lastModule else { continue }
                        wasm.append((entry.path.string, lastModule.location, try lastModule.wat.encode()))

                    default: continue
                    }
                }
            } catch {
                print("Error while parsing \(entry.path): \(error)")
            }
        }

        print("Collected \(wasm.count) Wasm files for benchmarking, \(wasm.map(\.bytes.count).reduce(0, +)) bytes in total")
        return wasm
    })
}
