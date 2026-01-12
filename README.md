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

| Category | Feature | Status |
|----------|---------|--------|
| WebAssembly MVP | Parsing binary format | ✅ Implemented |
|                 | Parsing text format (WAT) | ✅ Implemented |
|                 | Execution | ✅ Implemented |
|                 | Validation | ✅ Implemented  |
| WebAssembly Proposal | [Reference types](https://github.com/WebAssembly/reference-types/blob/master/proposals/reference-types/Overview.md) | ✅ Implemented |
|                      | [Bulk memory operations](https://github.com/WebAssembly/bulk-memory-operations/blob/master/proposals/bulk-memory-operations/Overview.md) | ✅ Implemented |
|                      | [Mutable globals](https://github.com/WebAssembly/mutable-global/blob/master/proposals/mutable-global/Overview.md) | ✅ Implemented |
|                      | [Sign-extension operators](https://github.com/WebAssembly/spec/blob/master/proposals/sign-extension-ops/Overview.md) | ✅ Implemented |
|                      | [Non-trapping float-to-int conversions](https://github.com/WebAssembly/nontrapping-float-to-int-conversions/blob/main/proposals/nontrapping-float-to-int-conversion/Overview.md) | ✅ Implemented |
|                      | [Memory64](https://github.com/WebAssembly/memory64/blob/main/proposals/memory64/Overview.md) | ✅ Implemented |
|                      | [Tail call](https://github.com/WebAssembly/tail-call/blob/master/proposals/tail-call/Overview.md) | ✅ Implemented |
|                      | [Threads and atomics](https://github.com/WebAssembly/threads/blob/master/proposals/threads/Overview.md) | 🚧 Parser implemented |
|                      | [Typed Function References](https://github.com/WebAssembly/function-references/blob/main/proposals/function-references/Overview.md) | 🚧 Parser implemented  |
|                      | [Garbage Collection](https://github.com/WebAssembly/gc/blob/main/proposals/gc/Overview.md) |  📋 Todo |
| WASI | WASI Preview 1 | 🚧 [Majority of syscalls implemented](https://github.com/swiftwasm/WasmKit/blob/d9b56a7b3f979a72682c0d37f6cc71b3493dae65/Tests/WASITests/IntegrationTests.swift#L31) |


## Minimum Supported Swift Version

The minimum supported version is Swift 6.0, which is the version used to bootstrap the Swift toolchain on [ci.swift.org](https://ci.swift.org/).

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
