import Benchmark
import WasmKit
import WAT

let benchmarks = {
    Benchmark("empty instantiation") { benchmark in
        for _ in benchmark.scaledIterations {
            let engine = Engine()
            let store = Store(engine: engine)
            let module = try parseWasm(bytes: wat2wasm("""
            (module
                (func (export "_start"))
            )
            """))
            _ = try module.instantiate(store: store)
        }
    }
}
