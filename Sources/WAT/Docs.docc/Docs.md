# ``WAT``

A library for working with WebAssembly Text format.


## Overview

WAT is a library for working with WebAssembly Text format. It provides a parser and encoder from WebAssembly Text format to WebAssembly binary format.


## Usage

```swift
import WAT

let wat = try parseWAT("""
(module
  (func $add (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.add)
  (export "add" (func $add))
)
""")

let wasm = try wat.encode()
```

### Parsing WAST

WAST is an superset of WAT that includes additional directives for testing. You can parse WAST using the `parseWAST` function.

```swift
import WAT

var wast = try parseWAST("""
(module
  (func $add (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.add)
  (export "add" (func $add))
)
(assert_return (invoke "add" (i32.const 1) (i32.const 2)) (i32.const 3))
""")

while let (directive, location) = try wast.nextDirective() {
    print("\(location): \(directive)")
}
```


## Topics

### Parsing

- ``parseWAT(_:features:)``
- ``parseWAST(_:features:)``


### Encode to binary format

- ``wat2wasm(_:features:)``

### WAST structures

- ``Wast``
- ``WastDirective``
- ``ModuleDirective``
- ``ModuleSource``
- ``WastInvoke``
- ``WastExecute``
- ``WastExpectValue``
