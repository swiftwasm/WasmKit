# ``WasmKit``

A WebAssembly runtime written in Swift.

## Overview

**WasmKit** is a standalone and embeddable WebAssembly runtime implementation written in Swift.


## Quick start

This example shows how to instantiate a WebAssembly module, interact with the host process, and invoke a WebAssembly function.

```swift
import WasmKit
import WAT

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

// Create engine and store
let engine = Engine()
let store = Store(engine: engine)

// Instantiate a parsed module with importing a host function
let instance = try module.instantiate(
    store: store,
    // Import a host function that prints an i32 value.
    imports: [
        "printer": [
            "print_i32": Function(store: store, parameters: [.i32]) { _, args in
                // This function is called from "print_add" in the WebAssembly module.
                print(args[0])
                return []
            }
        ]
    ]
)
// Invoke the exported function "print_add"
let printAdd = instance.exports[function: "print_add"]!
try printAdd([.i32(42), .i32(3)])
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
// Create engine and store
let engine = Engine()
let store = Store(engine: engine)
// Instantiate a parsed module importing WASI
var imports = Imports()
wasi.link(to: &imports, store: store)
let instance = try module.instantiate(store: store, imports: imports)

// Start the WASI command-line application.
let exitCode = try wasi.start(instance)
// Exit the Swift program with the WASI exit code.
exit(Int32(exitCode))
```

See [examples](https://github.com/swiftwasm/WasmKit/tree/main/Examples) for executable examples.

## Topics

### Basic Concepts

- ``Engine``
- ``Store``
- ``Module``
- ``Instance``
- ``Function``

### Binary Parser

- ``parseWasm(bytes:features:)``
- ``parseWasm(filePath:features:)``

### Other WebAssembly Entities

- ``Global``
- ``Memory``
- ``Table``

### Extending Runtime

- ``Imports``
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
