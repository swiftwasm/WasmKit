# ``WasmKit``

A WebAssembly runtime written in Swift.

## Overview

WasmKit is a standalone and embeddable WebAssembly runtime implementation for Swift.


## Quick start

This example shows how to instantiate a WebAssembly module, interact with the host process, and invoke a WebAssembly function.

```swift
import WasmKit
import Foundation

let bytes = try Data(contentsOf: URL(filePath: "./add.wasm"))
let module = try parseWasm(bytes: Array(bytes))

let hostPrint = HostFunction(type: FunctionType(parameters: [.i32])) { _, args in
    print(args[0])
    return []
}
let runtime = Runtime(hostModules: [
    "printer": HostModule(functions: ["print_i32": hostPrint])
])
let instance = try runtime.instantiate(module: module)
_ = try runtime.invoke(instance, function: "print_add", with: [.i32(42), .i32(3)])
```

The `add.wasm` file is generated from this code using `wat2wasm add.wat` command available in [WABT](https://github.com/WebAssembly/wabt):

```wat
(module
  (import "printer" "print_i32" (func $print_i32 (param i32)))
  (func (export "print_add") (param $x i32) (param $y i32)
    (call $print_i32 (i32.add (local.get $x) (local.get $y)))
  )
)
```

## WASI Example

This example shows how to run WASI application on WasmKit.

```swift
import WasmKit
import WASI
import Foundation

let bytes = try Data(contentsOf: URL(filePath: "./main.wasm"))
let module = try parseWasm(bytes: Array(bytes))

let wasi = try WASIBridgeToHost()
let runtime = Runtime(hostModules: wasi.hostModules)
let instance = try runtime.instantiate(module: module)
_ = try runtime.invoke(instance, function: "_start")
```

## Topics

### Basic Concepts

- ``Module``
- ``ModuleInstance``
- ``Runtime``
- ``Store``

### Binary Parser

- ``parseWasm(bytes:features:)``
- ``parseWasm(filePath:features:)``
- ``WasmFeatureSet``
- ``WasmParserError``

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

### Hook Runtime

- ``RuntimeInterceptor``
- ``GuestTimeProfiler``
