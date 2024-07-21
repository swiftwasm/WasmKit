<img alt="WasmKit Icon" src="https://raw.github.com/wiki/akkyie/wakit/images/wakit_icon.png" width="100px">

# WasmKit

**WasmKit** is a standalone and embeddable WebAssembly runtime implementation written in Swift.

## Usage

### Command Line Tool

WasmKit provides a command line tool to run WebAssembly binaries compliant with WASI.

```sh
$ git clone https://github.com/swiftwasm/WasmKit.git
$ cd WasmKit
$ swift run wasmkit-cli run ./Examples/hello.wasm
Hello, World!
```

### As a Library

#### Swift Package Manager

You can use WasmKit as a [Swift Package Manager](https://www.swift.org/documentation/package-manager/) dependency by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/swiftwasm/WasmKit.git", from: "0.0.5"),
],
```

You can find API documentation on the [Swift Package Index](https://swiftpackageindex.com/swiftwasm/WasmKit/main/documentation/wasmkit).


## Implementation Status

| Category | Feature | Status |
|----------|---------|--------|
| WebAssembly MVP | Parsing binary format | ✅ Implemented |
|                 | Parsing text format (WAT) | ✅ Implemented |
|                 | Execution | ✅ Implemented |
|                 | Validation | 🚧 Partially implemented |
| WebAssembly Proposal | [Reference types](https://github.com/WebAssembly/reference-types/blob/master/proposals/reference-types/Overview.md) | ✅ Implemented |
|                      | [Bulk memory operations](https://github.com/WebAssembly/bulk-memory-operations/blob/master/proposals/bulk-memory-operations/Overview.md) | ✅ Implemented |
|                      | [Mutable globals](https://github.com/WebAssembly/mutable-global/blob/master/proposals/mutable-global/Overview.md) | ✅ Implemented |
|                      | [Sign-extension operators](https://github.com/WebAssembly/spec/blob/master/proposals/sign-extension-ops/Overview.md) | ✅ Implemented |
|                      | [Non-trapping float-to-int conversions](https://github.com/WebAssembly/nontrapping-float-to-int-conversions/blob/main/proposals/nontrapping-float-to-int-conversion/Overview.md) | ✅ Implemented |
|                      | [Memory64](https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md) | ✅ Implemented |
|                      | [Threads and atomics](https://github.com/WebAssembly/threads/blob/master/proposals/threads/Overview.md) | 🚧 Parser implemented |
| WASI | WASI Preview 1 | ✅ Implemented |


## Testing

To run the core spec test suite run this:

```sh
# Checkout the core spec test suite
$ ./Vendor/checkout-dependency spectest
# Prepare core spec tests and check their assertions with WasmKit
$ make spectest

# Checkout WASI spec test suite
$ ./Vendor/checkout-dependency wasi-testsuite
# Install Python dependencies for running WASI spec tests
$ python3 -m pip install -r ./Vendor/wasi-testsuite/test-runner/requirements.txt
# Run WASI spec tests
$ make wasitest
```


## Acknowledgement

This project is originally developed by [@akkyie](https://github.com/akkyie), and now maintained by the community.
