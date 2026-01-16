# Examples

This directory contains a number of examples that demonstrate how to use the `WasmKit` library.

## Running

From this directory:

```sh
swift run PrintAdd
swift run Factorial
swift run StringPassing
swift run WASI-Hello
```

## StringPassing

`StringPassing` demonstrates a common UTF-8 string ABI for host <-> guest interop:

- WebAssembly passes a `(ptr: i32, len: i32)` pair into an imported host function (`printer.print_str`), and the host reads the bytes from the module's exported `memory`.
- The host allocates space in guest memory by calling an exported `alloc(size: i32) -> i32`, writes UTF-8 bytes into the returned region, then calls an exported `checksum(ptr: i32, len: i32) -> i32`.
