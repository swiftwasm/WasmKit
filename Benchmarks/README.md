# Benchmarks

This directory contains a set of benchmarks that can be used to compare the performance of the WasmKit runtime with other WebAssembly runtimes.

The benchmarks are divided in three types:

* Bencmarking WasmKit library via [`ordo-one/benchmark`](https://github.com/ordo-one/benchmark) harness;
* Benchmarking Wasm runtime executables end-to-end, implemented with a `bench.py` script;
* Replaying the [wasmi-benchmarks](https://github.com/wasmi-labs/wasmi-benchmarks) suite against the WasmKit library, so WasmKit can be compared with wasmi, wasm3 and stitch on the same inputs.

Setup and running instructions depend on the type of benchmarking you're interested.

## WasmKit Library Benchmarks

### Prerequisites

Check out benchmark dependencies with this terminal invocation in the root of WasmKit repository clone:

```sh
./Vendor/checkout-dependency --category benchmark
```

### Running Libary Benchmarks

After `Vendor/checkout-dependency` invocation listed above completed successfully, navigate back to the `Benchmarks` directory and start benchmarks:

```sh
swift package benchmark
```

## Executable Benchmarks

### Prerequisites

To build executable benchmarks, you need to install [wasi-sdk](https://github.com/WebAssembly/wasi-sdk) and set the `WASI_SDK_PATH` environment variable to the installation directory.

### Running the Benchmarks

Run all benchmarks:

```console
$ ./bench.py
```

Filtering examples:

```console
$ ./bench.py --benchmark CoreMark
$ ./bench.py --engine WasmKit
```

See `./bench.py --help` for more options.

## wasmi-benchmarks Replay

`WasmiBenchmarks` replays the `execute/*` cases and CoreMark from the
[wasmi-benchmarks](https://github.com/wasmi-labs/wasmi-benchmarks) suite through the
WasmKit library, using the same modules, the same inputs and the same result
assertions as the suite's own `benches/criterion/execute.rs`. That makes its
numbers directly comparable with a run of wasmi's criterion harness on the same
machine.

### Prerequisites

The suite is vendored (together with its `res/rust` submodule, which carries the
prebuilt `cases/*/out.wasm` modules) by the `benchmark` category:

```console
$ ./Vendor/checkout-dependency --category benchmark
```

This checks the suite out into `Vendor/wasmi-benchmarks`. No wasi-sdk and no Rust
toolchain are needed to run the WasmKit side.

### Running

Through `bench.py`, which writes `wasmi-benchmarks.csv` into the results directory:

```console
$ ./bench.py --benchmark WasmiBenchmarks
```

Or directly, which is more convenient while iterating because it takes a filter
and engine-configuration flags:

```console
$ swift build -c release --package-path . --product WasmiBenchmarks
$ ./.build/release/WasmiBenchmarks                    # everything
$ ./.build/release/WasmiBenchmarks counter            # only cases matching "counter"
$ ./.build/release/WasmiBenchmarks coremark
$ ./.build/release/WasmiBenchmarks --token            # token-threaded dispatch
$ ./.build/release/WasmiBenchmarks --eager            # eager compilation
$ ./.build/release/WasmiBenchmarks --software-bounds  # software memory bounds checks
```

Pass `--root <path>` to point at a wasmi-benchmarks checkout other than
`Vendor/wasmi-benchmarks`. The harness exits non-zero if any result assertion
fails, and prints CSV on stdout:

```
execute/counter-local,2.708,2.516,739
execute/counter-param,6.476,3.115,310
execute/counter-global,1.762,1.664,1136
coremark,3215.69
```

The `execute/*` columns are `name,mean_ms,min_ms,iterations`: each case is warmed
up for ~1 s and then measured for ~2 s (at least 10 iterations), which mirrors
what criterion does. For CoreMark the single column is the score reported by the
guest, where higher is better.

### Comparing against wasmi, wasm3 and stitch

Only numbers taken from the same machine in the same session are comparable. Run
the other engines from the vendored checkout itself, which needs a Rust
toolchain:

```console
$ cd ../Vendor/wasmi-benchmarks
$ cargo run --profile bench          # CoreMark scores for every engine
$ cargo bench --bench criterion --no-default-features --features wasmi-v2,wasm3,stitch -- execute/
```

Criterion reports the per-case time as a range; compare its estimate against the
`mean_ms` column above, and compare the CoreMark scores directly.
