# Benchmarks

This directory contains a set of benchmarks that can be used to compare the performance of the WasmKit runtime with other WebAssembly runtimes.

## Prerequisites

To build benchmarks, you need to install [wasi-sdk](https://github.com/WebAssembly/wasi-sdk) and set the `WASI_SDK_PATH` environment variable to the installation directory.

## Running the Benchmarks

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
