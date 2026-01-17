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

This section describes the high-level design of the register-based interpreter.

### Instruction set

Most of each VM instruction correspond to a single WebAssembly instruction, but they encode their operand and result registers into the instruction itself. For example, `Instruction.i32Add(lhs: Reg, rhs: Reg, result: Reg)` corresponds to the `i32.add` WebAssembly instruction, and it takes two registers as input and produces one register as output.
Exceptions are "provider" instructions, such as `local.get`, `{i32,i64,f32,f64}.const`, etc., which are no-ops at runtime. They are encoded as registers in instruction operands, so thre is no corresponding VM instruction for them.

A *register* in this context is a 64-bit slot in the stack frame that can uniformly hold any of the WebAssembly value types (i32, i64, f32, f64, ref). The register is identified by a 16-bit index.

### Translation

The translation pass converts WebAssembly instructions into a sequence of VM instructions. The translation is done in a single instruction traversal, and it abstractly interprets the WebAssembly instructions to track stack value sources (constants, locals, other instructions)

For example, the following WebAssembly code:

```wat
local.get 0
local.get 1
i32.add
i32.const 1
i32.add
local.set 0
end
```

is translated into the following VM instructions:

```
;; [reg:0] Local 0
;; [reg:1] Local 1
;; [reg:2] Const 0 = i32:1
;; [reg:6] Dynamic 0
reg:6 = i32.add reg:0, reg:1
reg:0 = i32.add reg:6, reg:2
return
```

Note that the last `local.set 0` instruction is fused directly into the `i32.add` instruction, and the `i32.const 1` instruction is embedded into the `i32.add` instruction, which references the constant slot in the stack frame.

Most of the translation process is straightforward and structured control-flow instructions are a bit more complex. Structured control-flow instructions (block, loop, if) are translated into a flatten branch-based instruction sequence as well as the second generation interpreter. For example, the following WebAssembly code:

```wat
local.get 0
if i32
  i32.const 1
else
  i32.const 2
end
local.set 0
```

is translated into the following VM instructions:

```
;; [reg:0] Local 0
;; [reg:1] Const 0 = i32:1
;; [reg:2] Const 1 = i32:2
;; [reg:5] Dynamic 0
0x00: br_if_not reg:0, +4 ; 0x6
0x02: reg:5 = copy reg:1
0x04: br +2 ; 0x8
0x06: reg:5 = copy reg:2
0x08: reg:0 = copy reg:5
```

See [`Translator.swift`](../Sources/WasmKit/Translator.swift) for the translation pass implementation.

You can see translated VM instructions by running the `wasmkit-cli explore` command.

### Stack frame layout

See doc comments on `StackLayout` type. The stack frame layout design is heavily inspired by stitch WebAssembly interpreter[^4].

Basically, the stack frame consists of four parts: frame header, locals, dynamic stack, and constant pool.

1. The frame header contains the saved stack pointer, return address, current instance, and value slots for parameters and return values. 
2. The locals part contains the local variables of the current function.
3. The constant pool part contains the constant values
    - The size of the constant pool is determined by a heuristic based on the Wasm-level code size. The translation pass determines the size at the beginning of the translation process to statically know value slot indices without fixing up them at the end of the translation process.
4. The dynamic stack part contains the dynamic stack values, which are the intermediate values produced by the WebAssembly instructions.
    - The size of the dynamic stack is the maximum height of the stack determined by the translation pass and is fixed at the end of the translation process.

#### Slots vs values

WasmKit’s runtime stack is indexed in **64-bit slots** (`StackSlot == UInt64`). Most Wasm value types occupy one slot, but `v128` occupies **two consecutive slots**:

- `i32/i64/f32/f64/ref`: 1 slot
- `v128`: 2 slots (`lo` then `hi`)

Register indices always refer to the **first slot** of a value (for `v128`, `reg` is the `lo` slot and `reg+1` is the `hi` slot).

This affects:

- Frame header sizing (parameters/results are sized in slots, not “number of values”)
- Local layout (locals are laid out in slots; `v128` locals reserve 2 slots)
- Dynamic stack height (computed in slots)

#### Example layout (with `v128`)

For a function with `(param i32 v128) (result v128)` and one local `i64`, the slot layout looks like:

| Slot offset | Description |
|---:|---|
| `-(H)+0` | Param/Result region (`i32` param0) |
| `-(H)+1` | Param/Result region (`v128` param1 lo / result0 lo) |
| `-(H)+2` | Param/Result region (`v128` param1 hi / result0 hi) |
| `-3` | Saved Instance |
| `-2` | Saved PC |
| `-1` | Saved SP |
| `0` | Local 0 (`i64`) |
| `1` | Const pool (first constant slot, if any) |
| `…` | Dynamic stack (slot-addressed) |

Where `H` is the total frame header size in slots (param/result region + saving slots).

Value slots in the frame header, locals, dynamic stack, and constant pool are all accessible by the register index (slot index).

### Instruction encoding

The VM instructions are encoded as a variable-length 64-bit slot sequence. The first 64-bit head slot is used to encode the instruction opcode kind. The rest of the slots are used to encode immediate operands.

The head slot value is different based on the threading model as mentioned in the next section. For direct-threaded, the head slot value is a pointer to the instruction handler function. For token-threaded, the head slot value is an opcode id.

### Threading model

We use the threaded code technique for instruction dispatch. Note that "threaded code" here is not related to the "thread" in the multi-threading context. It is a technique to implement a virtual machine interpreter efficiently[^5].

The interpreter supports two threading models: direct-threaded and token-threaded. The direct-threaded model is the default threading model on most platforms, and the token-threaded model is a fallback option for platforms that do not support guaranteed tail call.

There is nothing special; we just use a traditional interpreter technique to minimize the overhead instruction dispatch.

Typically, there are two ways to implement the direct-threaded model in C: using [Labels as Values](https://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html) extension or using guaranteed tail call (`musttail` in LLVM).

Swift does not support either of them, so we ask C-interop for help.
A little-known gem of the Swift compiler is C-interop, which uses Clang as a library and can mix Swift code and code in C headers as a single translation unit, and optimize them together.

We tried both Label as Values and guaranteed tail call approaches, and concluded that the guaranteed tail call approach is better fit for us.

In the Label as Values approach, there is a large single function with a lot of labels and includes all the instruction implementations. Theoretically, compiler can know the all necessary information to give us the "optimal" code. However, in practice, the compiler uses several heuristics and does not always generate the optimal code for this scale of function. For example, the register pressure is always pretty high in the interpreter function, and it often spills important variables like `sp` and `pc`, which significantly degrades the performance. We tried to tame the compiler by teaching hot/cold paths, but it's very tricky and time-consuming.

On the other hand, the guaranteed tail call approach is more straightforward and easier to tune. The instruction handler functions are all separated, and the compiler can optimize them individually. It will not mix hot/cold paths if we separate them at the translation stage. Generated machine code is more predictable and easier to read. Therefore, we chose the guaranteed tail call approach for the direct-threaded model implementation.

The instruction handler functions are defined in C headers. Those C functions call Swift functions implementing the actual instruction semantics, and then they tail-call the next instruction handler function.
We use [`swiftasync`](https://clang.llvm.org/docs/AttributeReference.html#swiftasynccall) calling convention for the C instruction handler functions to guarantee tail call and keep `self` context in a dedicated register.

In this way, we can implement instruction semantics in Swift and can dispatch instructions efficiently. 

Here is an example of the instruction handler function in C header and the corresponding Swift implementation:

```c
// In C header
typedef SWIFT_CC(swiftasync) void (* _Nonnull wasmkit_tc_exec)(
    uint64_t *_Nonnull sp, Pc, Md, Ms, SWIFT_CONTEXT void *_Nullable state);

SWIFT_CC(swiftasync) static inline void wasmkit_tc_i32Add(Sp sp, Pc pc, Md md, Ms ms, SWIFT_CONTEXT void *state) {
    SWIFT_CC(swift) uint64_t wasmkit_execute_i32Add(Sp *sp, Pc *pc, Md *md, Ms *ms, SWIFT_CONTEXT void *state, SWIFT_ERROR_RESULT void **error);
    void * _Nullable error = NULL; uint64_t next;
    INLINE_CALL next = wasmkit_execute_i32Add(&sp, &pc, &md, &ms, state, &error);
    return ((wasmkit_tc_exec)next)(sp, pc, md, ms, state);
}

// In Swift
import CWasmKit.InlineCode // Import C header
extension Execution {
    @_silgen_name("wasmkit_execute_i32Add") @inline(__always)
    mutating func execute_i32Add(sp: UnsafeMutablePointer<Sp>, pc: UnsafeMutablePointer<Pc>, md: UnsafeMutablePointer<Md>, ms: UnsafeMutablePointer<Ms>) -> CodeSlot {
        let immediate = Instruction.BinaryOperand.load(from: &pc.pointee)
        sp.pointee[i32: immediate.result] = sp.pointee[i32: immediate.lhs].add(sp.pointee[i32: immediate.rhs])
        let next = pc.pointee.pointee
        pc.pointee = pc.pointee.advanced(by: 1)
        return next
    }
}
```

Those boilerplate code is generated by the [`Utilities/Sources/VMGen.swift`](../Utilities/Sources/VMGen.swift) script.

## Performance evaluation

We have not done a comprehensive performance evaluation yet, but we have run the CoreMark benchmark to compare the performance of the register-based interpreter with the second generation interpreter. The benchmark was run on a 2020 Mac mini (M1, 16GB RAM) with `swift-DEVELOPMENT-SNAPSHOT-2024-09-17-a` toolchain and compiled with `swift build -c release`.

The below figure shows the score is 7.4x higher than the second generation interpreter.

![CoreMark score (higher is better)](https://github.com/user-attachments/assets/2c400efe-fe17-452d-b86e-747c2aba5ae8)

Additionally, we have compared our new interpreter with other top-tier WebAssembly interpreters; [wasm3](https://github.com/wasm3/wasm3), [stitch](https://github.com/makepad/stitch), and [wasmi](https://github.com/wasmi-labs/wasmi). The result shows that our interpreter is well competitive with them.

![CoreMark score in interpreter class (higher is better)](https://github.com/user-attachments/assets/f43c129c-0745-4e52-8e92-17dadc0c7fdd)

## References

[^1]: https://github.com/swiftwasm/WasmKit/pull/70
[^2]: Jun Xu, Liang He, Xin Wang, Wenyong Huang, Ning Wang. “A Fast WebAssembly Interpreter Design in WASM-Micro-Runtime.” Intel, 7 Oct. 2021, https://www.intel.com/content/www/us/en/developer/articles/technical/webassembly-interpreter-design-wasm-micro-runtime.html
[^3]: [Baseline Compilation in Wasmtime](https://github.com/bytecodealliance/rfcs/blob/de8616ba2fe01f3e94467a0f6ef3e4195c274334/accepted/wasmtime-baseline-compilation.md)
[^4]: stitch WebAssembly interpreter by @ejpbruel2 https://github.com/makepad/stitch
[^5]: https://en.wikipedia.org/wiki/Threaded_code
