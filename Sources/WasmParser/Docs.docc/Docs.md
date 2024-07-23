# ``WasmParser``

A WebAssembly binary parser library.

## Overview

WasmParser is a library for parsing WebAssembly binary format. It provides a parser for [WebAssembly binary format](https://webassembly.github.io/spec/core/binary/index.html).


## Quick start

To parse a WebAssembly binary file, you can use the `Parser` struct and its `parseNext()` method to incrementally parse the binary.

```swift
import WasmParser

var parser = Parser(bytes: [
    0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
    0x01, 0x7e, 0x01, 0x7e, 0x03, 0x02, 0x01, 0x00, 0x07, 0x07, 0x01, 0x03,
    0x66, 0x61, 0x63, 0x00, 0x00, 0x0a, 0x17, 0x01, 0x15, 0x00, 0x20, 0x00,
    0x50, 0x04, 0x7e, 0x42, 0x01, 0x05, 0x20, 0x00, 0x20, 0x00, 0x42, 0x01,
    0x7d, 0x10, 0x00, 0x7e, 0x0b, 0x0b
])

while let payload = try parser.parseNext() {
    switch payload {
    case .header(let version): print("Version: \(version)")
    case .customSection(let customSection): print("Custom section: \(customSection)")
    case .typeSection(let types): print("Type section: \(types)")
    case .importSection(let importSection): print("Import section: \(importSection)")
    case .functionSection(let types): print("Function section: \(types)")
    case .tableSection(let tableSection): print("Table section: \(tableSection)")
    case .memorySection(let memorySection): print("Memory section: \(memorySection)")
    case .globalSection(let globalSection): print("Global section: \(globalSection)")
    case .exportSection(let exportSection): print("Export section: \(exportSection)")
    case .startSection(let functionIndex): print("Start section: \(functionIndex)")
    case .elementSection(let elementSection): print("Element section: \(elementSection)")
    case .codeSection(let codeSection): print("Code section: \(codeSection)")
    case .dataSection(let dataSection): print("Data section: \(dataSection)")
    case .dataCount(let count): print("Data count: \(count)")
    }
}
```

## Topics

### Parsing

- ``Parser``
- ``Parser/parseNext()``
- ``parseExpression(bytes:features:hasDataCount:visitor:)``
- ``parseExpression(stream:features:hasDataCount:visitor:)``
- ``NameSectionParser``

### Visitor

- ``InstructionVisitor``
- ``VoidInstructionVisitor``
- ``AnyInstructionVisitor``
- ``InstructionTracingVisitor``


### Core Module Elements

- ``FunctionType``
- ``Import``
- ``ImportDescriptor``
- ``Export``
- ``ExportDescriptor``
- ``Table``
- ``TableType``
- ``Global``
- ``GlobalType``
- ``Memory``
- ``MemoryType``
- ``Mutability``
- ``Limits``
- ``DataSegment``
- ``ElementSegment``
- ``Code``
- ``CustomSection``

### Instruction Types

- ``Instruction``
- ``BrTable``
- ``BlockType``
- ``MemArg``

### Index Types

- ``TypeIndex``
- ``FunctionIndex``
- ``TableIndex``
- ``GlobalIndex``
- ``MemoryIndex``
- ``ElementIndex``
- ``DataIndex``
