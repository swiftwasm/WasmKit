# WITExtractor — Usage Guide

`WITExtractor` derives a [WIT](https://component-model.bytecodealliance.org/design/wit.html) (WebAssembly Interface Types) interface description from an **existing Swift module**. It is the reverse of `WITOverlayGenerator`: you start with Swift source and get a `.wit` file plus a Swift overlay that exports your module as a Wasm component.

## When to use it

Use `WITExtractor` when you have a Swift library you want to expose as a WebAssembly component but you do not want to maintain a hand-written WIT file. The extractor introspects the compiled module and generates both:

1. A `.wit` file — the component interface other languages can consume.
2. A Swift overlay `.swift` file — Canonical-ABI entry points that export your Swift functions to the component model host.

> **Opt-in via `@_spi(WIT)`:** Only declarations annotated with `@_spi(WIT)` are included in the extracted interface. Public declarations without this attribute are deliberately skipped so you can keep an existing public API surface while exposing a focused subset to WIT. See the example below.

## How it works

`WITExtractor` shells out to `swift-api-digester` (bundled with the Swift toolchain) to obtain a JSON description of the module's public API. It then:

1. **Collects types** — maps Swift types to WIT types (see table below).
2. **Builds a source summary** — collects public functions, structs, and enums.
3. **Translates to WIT** — emits a `package <namespace>:<package-name>` block containing a single interface named after the module.
4. **Generates a Swift overlay** — emits `@_expose(wasm, ...)` entry points that lift/lower Canonical-ABI values.

> **Platform constraint:** `WITExtractor` requires macOS 11+ because it uses `Foundation.Process` to launch `swift-api-digester`. It is not available on iOS, watchOS, tvOS, or visionOS.

## Type mapping

The extractor translates public Swift types into WIT types as follows:

| Swift | WIT | Notes |
|-------|-----|-------|
| `struct` with stored properties | `record { … }` | Each stored property becomes a named field |
| `enum` with no associated values | `enum { … }` | Case names are kebab-cased |
| `enum` with associated values | `variant { … }` | Payload types are mapped recursively |
| `func(…) -> T` (free function) | `<name>: func(…) -> T` | Only top-level public functions |
| `Bool` | `bool` | |
| `Int8`–`Int64`, `UInt8`–`UInt64` | `s8`–`s64`, `u8`–`u64` | |
| `Float`, `Double` | `f32`, `f64` | |
| `String` | `string` | |

Types that cannot be mapped emit a diagnostic and are skipped; the rest of the interface is still emitted.

---

## Usage via SPM command plugin (`WITExtractorPlugin`)

`WITExtractorPlugin` is a **command plugin** (not a build plugin), so you run it explicitly with `swift package plugin`.

### 1. Add WasmKit as a dependency

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/swiftwasm/WasmKit.git", .upToNextMinor(from: "0.2.0")),
],
```

### 2. Run the plugin

```sh
swift package plugin --allow-writing-to-package-directory \
    extract-wit \
    --target MyLibrary
```

The plugin:
1. Builds `MyLibrary` in the default configuration.
2. Locates `swift-api-digester` next to `swiftc` in the active toolchain.
3. Runs `wit-tool extract-wit` with the built module.
4. Writes two output files to the plugin work directory:
   - `MyLibrary.wit` — the extracted WIT interface.
   - `MyLibrary_WITOverlay.swift` — the Swift export shim.

Pass `--output-mapping <path>` to write a JSON file containing the exact output paths:

```sh
swift package plugin --allow-writing-to-package-directory \
    extract-wit \
    --target MyLibrary \
    --output-mapping /tmp/output-paths.json
```

```json
{
  "witOutputPath": "/path/to/.build/plugins/WITExtractorPlugin/.../MyLibrary.wit",
  "swiftOutputPath": "/path/to/.build/plugins/WITExtractorPlugin/.../MyLibrary_WITOverlay.swift"
}
```

### Setting the toolchain path manually

If the plugin cannot infer `swift-api-digester` from the build log, set the environment variable:

```sh
WIT_EXTRACTOR_SWIFTC_PATH=/path/to/swiftc \
    swift package plugin --allow-writing-to-package-directory \
    extract-wit --target MyLibrary
```

---

## Usage via `wit-tool` CLI

For scripted use, call the `extract-wit` subcommand on the `WITTool` executable directly:

```sh
swift run WITTool extract-wit \
    --swift-api-digester $(xcrun --find swift-api-digester) \
    --module-name MyLibrary \
    --package-name my-library \
    --wit-output-path ./output/my-library.wit \
    --swift-output-path ./output/MyLibrary_WITOverlay.swift \
    -- -I .build/debug/Modules
```

Arguments after `--` are forwarded verbatim to `swift-api-digester`.

| Flag | Required | Description |
|------|----------|-------------|
| `--swift-api-digester` | Yes | Path to the `swift-api-digester` binary |
| `--module-name` | Yes | Swift module name to introspect |
| `--package-name` | Yes | WIT package name (used in `package <ns>:<name>`) |
| `--namespace` | No (default: `swift`) | WIT namespace |
| `--wit-output-path` | Yes | Where to write the `.wit` file |
| `--swift-output-path` | Yes | Where to write the overlay `.swift` file |

---

## End-to-end example

Given a Swift module `MathLib` with the following public API:

```swift
// Sources/MathLib/MathLib.swift
@_spi(WIT)
public struct Vector2 {
    public var x: Float
    public var y: Float
    public init(x: Float, y: Float) { self.x = x; self.y = y }
}

@_spi(WIT)
public func addVectors(_ a: Vector2, _ b: Vector2) -> Vector2 {
    Vector2(x: a.x + b.x, y: a.y + b.y)
}
```

(Without `@_spi(WIT)` these declarations would be skipped by the extractor.)

Running the plugin against this target:

```sh
swift package plugin --allow-writing-to-package-directory extract-wit --target MathLib
```

(The plugin derives the WIT package name from `context.package.displayName`. To set it explicitly, use the CLI form with `--package-name math-lib`.) Produces a WIT file similar to:

```wit
// DO NOT EDIT.
//
// Generated by the WITExtractor

package swift:math-lib

interface math-lib {
    record vector2 {
        x: f32,
        y: f32,
    }

    add-vectors: func(a: vector2, b: vector2) -> vector2;
}
```

And a Swift overlay that provides the `@_expose(wasm, "math-lib#add-vectors")` entry point required by the component model ABI.

---

## Diagnostics

Types or functions that cannot be mapped are reported as diagnostics on stderr. The rest of the interface is still generated. For example:

```
warning: skipping field 'items' of 'Cart': unsupported type 'Array<Product>'
```

Review diagnostics to understand which parts of your API were excluded.

---

## See also

- [WITOverlayGenerator.md](WITOverlayGenerator.md) — going the other direction: WIT → Swift bindings
- [CanonicalABI.md](CanonicalABI.md) — how WIT values are encoded over core Wasm
- [WebAssembly Component Model spec](https://github.com/WebAssembly/component-model)
