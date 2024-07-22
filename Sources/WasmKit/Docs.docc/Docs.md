# ``WasmKit``

A WebAssembly runtime written in Swift.

## Overview

**WasmKit** is a standalone and embeddable WebAssembly runtime implementation written in Swift.


## Quick start

This example shows how to instantiate a WebAssembly module, interact with the host process, and invoke a WebAssembly function.

```swift
import WasmKit
import WAT
import Foundation

// Convert a WAT file to a Wasm binary, then parse it.
let module = try parseWasm(
    bytes: try wat2wasm(
        """
        (module
          (import "printer" "print_i32" (func $print_i32 (param i32)))
          (func (export "print_add") (param $x i32) (param $y i32)
            (call $print_i32 (i32.add (local.get $x) (local.get $y)))
          )
        )
        """
    )
)

// Define a host function that prints an i32 value.
let hostPrint = HostFunction(type: FunctionType(parameters: [.i32])) { _, args in
    // This function is called from "print_add" in the WebAssembly module.
    print(args[0])
    return []
}
// Create a runtime importing the host function.
let runtime = Runtime(hostModules: [
    "printer": HostModule(functions: ["print_i32": hostPrint])
])
let instance = try runtime.instantiate(module: module)
// Invoke the exported function "print_add"
_ = try runtime.invoke(instance, function: "print_add", with: [.i32(42), .i32(3)])
```

See [examples](https://github.com/swiftwasm/WasmKit/tree/main/Examples) for executable examples.

## WASI Example

This example shows how to run WASI application on WasmKit.

```swift
import WasmKit
import WasmKitWASI
import WAT
import Foundation

// Parse a WASI-compliant WebAssembly module from a file.
let module = try parseWasm(filePath: "wasm/hello.wasm")

// Create a WASI instance forwarding to the host environment.
let wasi = try WASIBridgeToHost()
// Create a runtime with WASI host modules.
let runtime = Runtime(hostModules: wasi.hostModules)
let instance = try runtime.instantiate(module: module)

// Start the WASI command-line application.
let exitCode = try wasi.start(instance, runtime: runtime)
// Exit the Swift program with the WASI exit code.
exit(Int32(exitCode))
```

See [examples](https://github.com/swiftwasm/WasmKit/tree/main/Examples) for executable examples.

## Topics

### Basic Concepts

- ``Module``
- ``ModuleInstance``
- ``Runtime``
- ``Store``

### Binary Parser

- ``parseWasm(bytes:features:)``
- ``parseWasm(filePath:features:)``

### Extending Runtime

- ``HostModule``
- ``HostFunction``
- ``Caller``
- ``GuestMemory``
- ``UnsafeGuestPointer``
- ``UnsafeGuestRawPointer``
- ``UnsafeGuestBufferPointer``
- ``GuestPointee``
- ``GuestPrimitivePointee``

### Component Model

- ``CanonicalLifting``
- ``CanonicalLowering``
- ``CanonicalOptions``
- ``CanonicalCallContext``
- ``ComponentError``
