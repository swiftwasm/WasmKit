<img alt="WAKit Icon" src="https://raw.github.com/wiki/akkyie/wakit/images/wakit_icon.png" width="100px">

# WasmKit

A WebAssembly runtime written in Swift. Originally developed and maintained by [@akkyie](https://github.com/akkyie).

Implements all of WebAssembly 2.0 binary parsing and execution core spec, with an exclusion of SIMD instructions. The validation and text format parts of the spec are not implemented yet.

It also has rudimentary support for [WASI](https://wasi.dev) with only a few WASI imports implemented currently, with a goal of eventual full support for `wasi_snapshot_preview1`. See `WASI` module for more details.

## Usage

### Command Line Tool

```sh
$ # Usage: wasmkit-cli run <path> <functionName> [<arguments>] ...
$ swift run wasmkit-cli run Examples/wasm/fib.wasm fib i32:10
[I32(89)]
```

### As a Library

#### Swift Package Manager

Add the URL of this repository to your `Package.swift` manifest. Then add the `WasmKit` library product as dependency to the target you'd like to use it with.

## Testing

To run the core spec test suite run this:

```sh
$ make spectest   # Prepare core spec tests and check their assertions with WasmKit
```
