# Register-based Interpreter Design

## Introduction

This document describes the design and rationale of the WasmKit register-based interpreter. The interpreter is designed to be reasonably fast and memory-efficient without sacrificing the simplicity of the codebase.

## Interpreter History

**First Generation**

The original interpreter of WasmKit interpreted structured WebAssembly instructions directly without any intermediate representation. The interpreter used a switch-case statement to dispatch the execution of each instruction and every block/loop/if instruction had its own stack frame. The interpreter was simple and easy to understand, but it was slow and memory-inefficient.

**Second Generation**

The second generation[^1] added a thin translation pass that converted WebAssembly instructions into a stack-based linear intermediate representation. The translation pass pre-computed stack-height information and branch offsets to simplify branch handling. Those information were computed by abstractly interpreting the WebAssembly instructions while doing the [validation](https://webassembly.github.io/spec/core/valid/index.html) step.

The second generation interpreter significantly improved the branching performance and resulted in ~5x speedup compared to the first generation interpreter.

<details>

<summary>CoreMark benchmark results of the second generation interpreter and other runtimes</summary>

```
===== Running CoreMark with WasmKit... =====
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 849462320
Total time (secs): 13.734364
Iterations/Sec   : 291.240274
Iterations       : 4000
Compiler version : GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c)
Compiler flags   : -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x65c5
Correct operation validated. See README.md for run and reporting rules.
CoreMark 1.0 : 291.240274 / GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c) -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks    / STACK

===== Running CoreMark with wasmi... =====
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 2252434821
Total time (secs): 15.137337
Iterations/Sec   : 1321.236383
Iterations       : 20000
Compiler version : GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c)
Compiler flags   : -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x382f
Correct operation validated. See README.md for run and reporting rules.
CoreMark 1.0 : 1321.236383 / GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c) -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks    / STACK

===== Running CoreMark with wasmtime... =====
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 170628066
Total time (secs): 17.350497
Iterations/Sec   : 11527.047157
Iterations       : 200000
Compiler version : GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c)
Compiler flags   : -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x4983
Correct operation validated. See README.md for run and reporting rules.
CoreMark 1.0 : 11527.047157 / GCCClang 18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c) -O3 -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks    / STACK
```

</details>


## Motivation

The second generation interpreter was a significant improvement over the first generation, but it was still not fast enough to run [some of exhaustive test suites of Swift Standard Library](https://github.com/swiftlang/swift/tree/main/test/stdlib).

Based on the profiling results, the interpreter was spending over 60% of the time in `local.get`, and `{i32,i64,f32,f64}.const` instructions. Those instructions frequently appear when lowering LLVM IR to WebAssembly without the [Register Stackification pass](https://github.com/llvm/llvm-project/blob/llvmorg-18.1.8/llvm/lib/Target/WebAssembly/WebAssemblyRegStackify.cpp), which is usually applied only when `-O` optimization enabled, and the most of the Swift Standard Library tests are compiled without `-O`.

According to "A Fast WebAssembly Interpreter Design in WASM-Micro-Runtime" [^2], the described register-based interpreter design can remove "provider" instructions (e.g., `local.get`, `{i32,i64,f32,f64}.const`) during the translation step and embed register information directly into "consumer" instructions (e.g., `i32.add`, `call`, etc.).

The register-based interpreter design is expected to reduce the number of instructions executed and improve the performance of the interpreter, especially for non-optimized WebAssembly code.

## Design Overview

TBD

### Stack frame layout

```
| Const Pool | Local Variables | Dynamic |

### VM instruction representation

TBD

## Implementation Plan

TBD

## Alternative considerations

TBD

## References

[^1]: https://github.com/swiftwasm/WasmKit/pull/70
[^2]: Jun Xu, Liang He, Xin Wang, Wenyong Huang, Ning Wang. “A Fast WebAssembly Interpreter Design in WASM-Micro-Runtime.” Intel, 7 Oct. 2021, https://www.intel.com/content/www/us/en/developer/articles/technical/webassembly-interpreter-design-wasm-micro-runtime.html
[^3]: [Baseline Compilation in Wasmtime](https://github.com/bytecodealliance/rfcs/blob/de8616ba2fe01f3e94467a0f6ef3e4195c274334/accepted/wasmtime-baseline-compilation.md)
