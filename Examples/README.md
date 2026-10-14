# Examples

This directory contains a number of examples that demonstrate how to use the `WasmKit` library.

## Running

From this directory:

```sh
swift run PrintAdd
swift run Factorial
swift run StringPassing
swift run WASI-Hello
swift run HostCallSuspension
```

On macOS these commands do not build at the moment. This package declares macOS 10.13, while
WasmKit requires macOS 15, so SwiftPM refuses the `WasmKit` and `WAT` products. The
`HostCallSuspension` section shows how to run that example from a separate package meanwhile.

## StringPassing

`StringPassing` demonstrates a common UTF-8 string ABI for host <-> guest interop:

- WebAssembly passes a `(ptr: i32, len: i32)` pair into an imported host function (`printer.print_str`), and the host reads the bytes from the module's exported `memory`.
- The host allocates space in guest memory by calling an exported `alloc(size: i32) -> i32`, writes UTF-8 bytes into the returned region, then calls an exported `checksum(ptr: i32, len: i32) -> i32`.

## HostCallSuspension

`HostCallSuspension` runs a guest as a `ResumableCall` whose imported host function throws a
`SuspensionRequest` instead of returning. The embedder answers each host call after an `await`
with `resume(returning:answering:)`, and the guest continues after the call without running the
host function again. It also shows the difference between completing a host call with an error,
which a guest exception handler can catch, and cancelling the call with `resume(throwing:)`.

Until this package declares macOS 15, the example can run on macOS from a separate package that
does. From the root of the WasmKit checkout:

```sh
dir=$(mktemp -d)
mkdir "$dir/Sources"
cp -R Examples/Sources/HostCallSuspension "$dir/Sources/"
cat > "$dir/Package.swift" <<EOF
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "HostCallSuspension",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "WasmKit", path: "$PWD")],
    targets: [
        .executableTarget(
            name: "HostCallSuspension",
            dependencies: [
                .product(name: "WasmKit", package: "WasmKit"),
                .product(name: "WAT", package: "WasmKit"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
EOF
swift run --package-path "$dir" HostCallSuspension
```
