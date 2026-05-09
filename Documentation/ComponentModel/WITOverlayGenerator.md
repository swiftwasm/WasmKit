# WITOverlayGenerator — Usage Guide

`WITOverlayGenerator` generates Swift bindings from a [WIT](https://component-model.bytecodealliance.org/design/wit.html) (WebAssembly Interface Types) package. Given a `.wit` file that describes a *world* or *interface*, it produces Swift source that lets you either:

- **implement** the interface as a WebAssembly guest component (compiled with SwiftWasm), or
- **call** the interface from a Swift host runtime that embeds WasmKit.

## Concepts

| Term | Meaning |
|------|---------|
| **WIT** | The IDL used by the WebAssembly Component Model to describe interfaces. |
| **Guest** | The Wasm module that *implements* an interface. |
| **Host** | The Swift process that *runs* the Wasm module via WasmKit. |
| **Overlay** | The generated Swift glue code that bridges WIT types to/from Swift. |

The generator supports two targets, selected with `--target`:

| `--target` | Generated code | Typical use |
|------------|---------------|-------------|
| `guest` | `#if arch(wasm32)` guards, `@_expose(wasm, ...)` entry points, Canonical-ABI lift/lower | Wasm component compiled with `swiftc -target wasm32-...` |
| `host` | `import WasmKit` bindings, function-call wrappers | macOS/Linux host that embeds WasmKit |

## Usage via SPM build plugin (`WITOverlayPlugin`)

`WITOverlayPlugin` is a **build tool plugin**: it runs automatically during `swift build` and generates a Swift overlay file for each target that uses it.

### 1. Add WasmKit as a package dependency

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/swiftwasm/WasmKit.git", .upToNextMinor(from: "0.2.0")),
],
```

### 2. Configure the target

```swift
.target(
    name: "MyComponent",
    dependencies: [
        // Required shim for the Canonical ABI runtime helpers
        .product(name: "_CabiShims", package: "WasmKit"),
    ],
    plugins: [
        .plugin(name: "WITOverlayPlugin", package: "WasmKit"),
    ]
),
```

> **Note:** `_CabiShims` **must** be listed as a dependency; the plugin emits a build error if it is absent.

### 3. Place your WIT file

Create a `wit/` directory directly inside the target's source directory and put your `.wit` file there:

```
Sources/
  MyComponent/
    wit/
      my-world.wit    ← WIT package consumed by the plugin
    MyComponent.swift ← your Swift implementation
```

Example `my-world.wit`:

```wit
package example:my-component;

world my-world {
    export greet: func(name: string) -> string;
}
```

### 4. Build

```sh
swift build
```

The plugin invokes `wit-tool generate-overlay --target guest <wit-dir>` and writes the generated file to the plugin work directory as `<TargetName>Overlay.swift`. That file is compiled automatically alongside your own Swift sources.

The generated file contains the `#if arch(wasm32)` -guarded Canonical-ABI entry points that the Wasm component model linker expects.

---

## Usage via `wit-tool` CLI

For scripted or CI workflows you can call the CLI directly:

```sh
swift run wit-tool generate-overlay \
    --target guest \
    path/to/wit/ \
    -o path/to/GeneratedOverlay.swift
```

Omit `-o` to print the generated source to stdout.

For a host-side binding:

```sh
swift run wit-tool generate-overlay \
    --target host \
    path/to/wit/ \
    -o path/to/HostBindings.swift
```

The host-side output `import WasmKit` and provides typed Swift wrappers that call into a loaded `WasmKit.Runtime` instance.

### Validating a WIT package

Before generating, you can validate your WIT package:

```sh
swift run wit-tool validate path/to/wit/
# or a single file:
swift run wit-tool validate path/to/interface.wit
```

---

## Type mapping

| WIT type | Guest Swift type | Notes |
|----------|-----------------|-------|
| `bool` | `Bool` | |
| `u8`–`u64`, `s8`–`s64` | `UInt8`–`UInt64`, `Int8`–`Int64` | |
| `f32`, `f64` | `Float`, `Double` | |
| `string` | `String` | Copied through Wasm linear memory |
| `record { … }` | `struct` | Fields mapped recursively |
| `variant { … }` | `enum` with associated values | |
| `enum { … }` | `enum` (no payloads) | |
| `list<T>` | `[T]` | |
| `option<T>` | `T?` | |
| `result<T, E>` | `Result<T, E>` | |

The Canonical ABI encoding/decoding is handled by the generated overlay code; you do not need to write any manual memory management.

---

## See also

- [CanonicalABI.md](CanonicalABI.md) — how WIT values are encoded as core Wasm values
- [SemanticsNotes.md](SemanticsNotes.md) — WIT semantics analysis in WasmKit
- [WITExtractor.md](WITExtractor.md) — going the other direction: Swift module → WIT
- [WebAssembly Component Model spec](https://github.com/WebAssembly/component-model)
