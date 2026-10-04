# GC benchmarks

Workloads for WasmKit's garbage collector, written in the text format with GC
instructions. Convert them to binary with any WAT tool, then run them with the
`gc` feature:

```console
$ wasm-tools parse binary_trees.wat -o binary_trees.wasm
$ swift build -c release --product wasmkit-cli
$ ../../.build/release/wasmkit-cli run --feature gc binary_trees.wasm run i32:16
[i32(14723759)]
$ wasm-tools parse deep_stack.wat -o deep_stack.wasm
$ ../../.build/release/wasmkit-cli run --feature gc deep_stack.wasm run i32:1000 i32:2000000
[i32(500500)]
```

- `binary_trees.wat`: the Benchmarks Game program. Many short-lived trees next
  to one long-lived tree, so collections are frequent and most objects die young.
- `deep_stack.wat`: an allocation loop at the bottom of a deep recursion whose
  frames each keep an object in a local, so every collection walks many frames.
