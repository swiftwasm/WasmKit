# Benchmarks

This directory contains a set of benchmarks that can be used to compare the performance of the WasmKit runtime with other WebAssembly runtimes.

The benchmarks are divided in two types:

* Bencmarking WasmKit library via [`package-benchmark`](https://github.com/ordo-one/package-benchmark) harness;
* Benchmarking Wasm runtime executables end-to-end, implemented with a `bench.py` script.

Setup and running instructions depend on the type of benchmarking you're interested.

## WasmKit Library Benchmarks

### Prerequisites

Check out benchmark dependencies with this terminal invocation in the root of WasmKit repository clone:

```sh
./Vendor/checkout-dependency --category benchmark
```
## Running Libary Benchmarks

After `Vendor/checkout-dependency` invocation listed above completed successfully, navigate back to the `Benchmarks` directory and start benchmarks:

```sh
swift package benchmark
```

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
