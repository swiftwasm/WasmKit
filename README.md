<img alt="WasmKit Icon" src="https://raw.github.com/wiki/akkyie/wakit/images/wakit_icon.png" width="100px">

# WasmKit

**WasmKit** is a standalone and embeddable [WebAssembly](https://webassembly.org) runtime (virtual machine) implementation and related tooling written in Swift. Starting with Swift 6.2, WasmKit CLI executable is included in [Swift toolchains distributed at swift.org](https://swift.org/install) for Linux and macOS.

## Usage

You can find introductory examples and API documentation on the [Swift Package Index documentation page](https://swiftpackageindex.com/swiftwasm/WasmKit/main/documentation/wasmkit).

### Command Line Tool

WasmKit provides a command line tool to run WebAssembly binaries compatible with [WASI](https://wasi.dev).

```sh
$ git clone https://github.com/swiftwasm/WasmKit.git
$ cd WasmKit
$ swift run wasmkit-cli run ./Examples/wasm/hello.wasm
Hello, World!
```

### As a Library

#### Swift Package Manager

To use WasmKit in your package, add it as a [Swift Package Manager](https://www.swift.org/documentation/package-manager/) dependency.

Run the following commands in the same directory as your `Package.swift` manifest to add the dependency:

```
swift package add-dependency https://github.com/swiftwasm/WasmKit --up-to-next-minor-from 0.2.0
swift package add-target-dependency WasmKit <your-package-target-name> --package WasmKit
```

You can also add the following snippet manually instead to your `Package.swift` file:

```swift
dependencies: [
    // ...other dependencies
    .package(url: "https://github.com/swiftwasm/WasmKit.git", .upToNextMinor(from: "0.2.0")),
],
// ...other package configuration
targets: [
    // ...other targets
    .target(
        name: "<your-package-target-name>",
        dependencies: [.product(name: "WasmKit", package: "WasmKit")],
    )
]
```

## Features

- [Reasonably fast](./Documentation/RegisterMachine.md#performance-evaluation)
- Minimal dependencies
    - The core runtime engine depends only on [swift-system](https://github.com/apple/swift-system).
    - No Foundation dependency
- Compact and embeddable
    - Debug build complete in 5 seconds[^1]
- Batteries included
    - WASI support, WAT (WebAssembly text format) parser/assembler, etc.


## Supported Platforms

WasmKit engine works on all major platforms supported by Swift. It is continuously tested on macOS, Ubuntu, Amazon Linux 2, Android, and Windows,
and should work on the following platforms:

- macOS 10.13+, iOS 12.0+, tvOS 12.0+, watchOS 6.0+
- Amazon Linux 2, Debian 12, Ubuntu 22.04+, Fedora 39+
- Android [API Level 30](https://developer.android.com/tools/releases/platforms)
- Windows 10+

## Implementation Status

### WebAssembly MVP

| Feature | Status |
|---------|--------|
| Parsing binary format | ✅ Implemented |
| Parsing text format (WAT) | ✅ Implemented |
| Execution | ✅ Implemented |
| Validation | ✅ Implemented |

### WebAssembly Proposals

Proposals are grouped by their [phase](https://github.com/WebAssembly/meetings/blob/main/process/phases.md) in the standardization process. See the [WebAssembly proposals repository](https://github.com/WebAssembly/proposals) for details.

#### Finished (Merged into the spec)

| Proposal | Status | WasmKit version |
|----------|--------|-----------------|
| [Bulk Memory Operations](https://github.com/WebAssembly/bulk-memory-operations) | ✅ Implemented | [0.0.2] |
| [Exception Handling](https://github.com/WebAssembly/exception-handling) | ✅ Implemented | `main` branch |
| [Fixed-width SIMD](https://github.com/webassembly/simd) | ✅ Implemented | `main` branch |
| [Import/Export of Mutable Globals](https://github.com/WebAssembly/mutable-global) | ✅ Implemented | [0.0.2] |
| [Memory64](https://github.com/WebAssembly/memory64) | ✅ Implemented | [0.0.2] |
| [Multi-value](https://github.com/WebAssembly/multi-value) | ✅ Implemented | [0.0.2] |
| [Non-trapping Float-to-Int Conversions](https://github.com/WebAssembly/nontrapping-float-to-int-conversions) | ✅ Implemented | [0.0.2] |
| [Reference Types](https://github.com/WebAssembly/reference-types) | ✅ Implemented | [0.0.2] |
| [Sign-extension Operators](https://github.com/WebAssembly/sign-extension-ops) | ✅ Implemented | [0.0.2] |
| [Tail Call](https://github.com/WebAssembly/tail-call) | ✅ Implemented | [0.1.4] |
| [Typed Function References](https://github.com/WebAssembly/function-references) | 🚧 Parser implemented | [0.2.0] |
| [Branch Hinting](https://github.com/WebAssembly/branch-hinting) | ❌ Not implemented | |
| [Custom Annotation Syntax in the Text Format](https://github.com/WebAssembly/annotations) | ❌ Not implemented | |
| [Extended Constant Expressions](https://github.com/WebAssembly/extended-const) | ❌ Not implemented | |
| [Garbage Collection](https://github.com/WebAssembly/gc) | ❌ Not implemented | |
| [Multiple Memories](https://github.com/WebAssembly/multi-memory) | ❌ Not implemented | |
| [Relaxed SIMD](https://github.com/WebAssembly/relaxed-simd) | ❌ Not implemented | |

[0.0.2]: https://github.com/swiftwasm/WasmKit/releases/tag/0.0.2
[0.1.4]: https://github.com/swiftwasm/WasmKit/releases/tag/0.1.4
[0.2.0]: https://github.com/swiftwasm/WasmKit/releases/tag/0.2.0

#### Phase 4 - Standardize the Feature (WG)

| Proposal | Status | WasmKit version |
|----------|--------|-----------------|
| [Threads and Atomics](https://github.com/webassembly/threads) | ✅ Implemented | `main` branch |

#### Phase 1 - Feature Proposal (CG)

| Proposal | Status | WasmKit version |
|----------|--------|-----------------|
| [Component Model](https://github.com/webassembly/component-model) | 🚧 In progress | `main` branch |

### WASI

| Feature | Status | WasmKit version |
|---------|--------|-----------------|
| [WASI 0.1](https://github.com/WebAssembly/WASI/tree/wasi-0.1) | 🚧 [Majority of syscalls implemented](https://github.com/swiftwasm/WasmKit/blob/d9b56a7b3f979a72682c0d37f6cc71b3493dae65/Tests/WASITests/IntegrationTests.swift#L31) | [0.0.2] |
| [WASI Threads](https://github.com/WebAssembly/wasi-threads) | ❌ Not implemented | |


## Minimum Supported Swift Version (MSSV)

Currently, the minimum supported version is Swift 6.1. The general strategy is to support last two minor versions of the Swift toolchain available at the time of WasmKit's release. At the same time, development branches of WasmKit tend to adopt newer development versions of the Swift toolchain.

## Testing

To run the WasmKit test suite, you need to checkout the test suite repositories first.

```sh
# Checkout test suite repositories
$ ./Vendor/checkout-dependency
# Run tests
$ swift test
```

## Acknowledgement

This project was originally developed by [@akkyie](https://github.com/akkyie), and is now maintained by the community.

[^1]: On a 2020 Mac mini (M1, 16GB RAM) with Swift 5.10. Measured by `swift package resolve && swift package clean && time swift build --product PrintAdd`.
License

## License

WasmKit runtime modules are licensed under MIT License. See [LICENSE](https://raw.githubusercontent.com/swiftwasm/WasmKit/refs/heads/main/LICENSE) file for license information.

GDB Remote Protocol support (`GDBRemoteProtocol` and `WasmKitGDBHandler` modules) is licensed separately under Apache License v2.0 with Runtime Library Exception, Copyright 2025 Apple Inc. and the Swift project authors.

See https://swift.org/LICENSE.txt for license information.

See https://swift.org/CONTRIBUTORS.txt for Swift project authors.
