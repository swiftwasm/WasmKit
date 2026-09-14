# Execution-control microbenchmarks

Run the commands below from Benchmarks/ExecutionControl. This standalone macOS package compares arithmetic token dispatch, repeated short exports, frequent native imports and caught guest exceptions. Every batch checks its result. A process selects user-initiated QoS. Store construction, parsing, instantiation and lazy translation happen before recorded samples. The ordinary and controlled variants share one patched executable. Memory bounds checking is explicitly software based for every mode.

Build the same source against two local engine checkouts. The baseline should be unchanged main at 15d04d51d6e031f5eabf9b2faba236d6cc26b723, and the patched checkout should contain the proposed change. Use the same Swift compiler for both builds. Set WASMKIT_BENCH_ENGINE to the absolute engine checkout and WASMKIT_BENCH_CONTROL_API to 0 for the baseline or 1 for the patched build.

```sh
WASMKIT_BENCH_ENGINE=/path/to/main WASMKIT_BENCH_CONTROL_API=0 swift build -c release --scratch-path .build/baseline
WASMKIT_BENCH_ENGINE=/path/to/patch WASMKIT_BENCH_CONTROL_API=1 swift build -c release --scratch-path .build/patched
.build/baseline/release/engine-bench --verify-only
.build/patched/release/engine-bench --mode controlled --verify-only
python3 run-comparison.py --baseline .build/baseline/release/engine-bench --patched .build/patched/release/engine-bench --output .build/results
```

The runner uses all six permutations of process order, two discarded batches and seven recorded batches per workload. It saves every command, executable hash, raw sample and process error stream. The summary includes the median, full range, standard deviation and median absolute deviation. Retain the source and compiler version with the results. Adjust batch sizes so each sample takes several hundred milliseconds on the measurement machine. Quiet other builds and workloads before timing.

Token mode compares unchanged main, the patched ordinary Store and the patched live controller with an interval of 1,024. The --threading direct option performs a separate comparison of ordinary stores. Controlled direct dispatch is unsupported. The optional --fixture and --renders arguments in the runner support a separate downstream executable and are unused by this package.

Timing results apply to the tested machine, compiler and workloads. They do not establish zero overhead or a universal execution-cost bound.
