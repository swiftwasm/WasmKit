# WasmKit Development Utilities

This directory contains a set of utilities that are useful for developing WasmKit.

## Usage

Re-generates all the auto-generated files

```console
$ swift run WasmKitDevUtils
```

Re-generates only the internal VM instruction related files

```console
$ swift run WasmKitDevUtils generate-internal-instruction
```

Re-generates only the Core Wasm instruction related files based on `Instructions.json`.

```console
$ swift run WasmKitDevUtils generate-wasm-instruction
```
