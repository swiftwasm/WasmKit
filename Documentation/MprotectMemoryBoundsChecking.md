# mprotect-based memory bounds checking

## Background

WasmKit has two linear-memory allocation strategies:

- `software`: linear memory accesses are checked explicitly in the interpreter before touching memory.
- `mprotect`: wasm32 linear memories are backed by a large virtual address reservation whose inaccessible tail can be used to turn out-of-bounds accesses into synchronous faults.

The `mprotect` strategy is kept because it is still useful as the memory representation for future JIT code generation, where unchecked accesses can turn those faults into Wasm traps efficiently.

## Current state

Today, WasmKit interpreters do **not** use `mprotect` faults to eliminate per-access bounds checks.

Even when `EngineConfiguration.memoryBoundsChecking` is `.mprotect`, interpreter loads and stores still use the normal checked VM instructions. The `mprotect`-backed linear memory implementation remains available, but the interpreter does not emit separate unchecked load/store opcodes anymore.

## Why the interpreter does not use unchecked accesses

The earlier interpreter design used additional unchecked load/store instruction variants so the VM could rely on `mprotect` faults instead of an explicit bounds check. We no longer do that for three reasons.

### 1. It makes the VM loop larger

Supporting both checked and unchecked memory operations requires more internal instruction kinds and more dispatch code in the interpreter loop. That increases VM code size and maintenance cost for a small benefit.

### 2. The speedup is small in the interpreter

Unlike JIT-generated code, interpreter bounds checks live at a stable location in the code address space. In the common case, the out-of-bounds branch is not taken, so branch prediction handles it well. Removing that check therefore does not buy much in practice, because the interpreter still pays the rest of the dispatch overhead either way.

This is different from JIT code, where folding the check into the memory access can matter more.

### 3. `siglongjmp` imposes strict frame-safety rules

Recovering from an out-of-bounds fault in `mprotect` mode uses `sigsetjmp` / `siglongjmp`. That recovery mechanism does not run language-level cleanup code. It restores register state and transfers control directly back to the trap guard.

Because of that, any call frames that may be active when an out-of-bounds access happens must be safe to abandon abruptly. In practice, this means the faulting path must avoid epilogue work such as:

- `defer`
- value destruction / cleanup that must run on normal return
- other implicit teardown work in skipped frames

That is a much tighter constraint than we want for normal interpreter code, and it is easy to violate accidentally as the VM evolves.

## Linear memory layout

For wasm32 memories, the `mprotect` implementation reserves:

- `4 GiB` for the wasm32 address space
- plus an extra internal guard tail (`memoryOffsetGuardSize`)

The extra tail is retained for future unchecked constant-offset accesses in JIT-generated code. It is currently an internal engine detail rather than a public tuning knob.

The layout is:

- `[base, base + committed)` is `PROT_READ | PROT_WRITE`
- `[base + committed, base + reservation)` is `PROT_NONE`

Memory growth commits more of that reserved range with `mprotect` and does not relocate the existing contents.

## Trap handling

WasmKit still has trap-guard infrastructure for converting faults in the reserved range into Wasm traps:

- process-wide `sigaction` handlers for `SIGSEGV` / `SIGBUS`
- a per-thread trap guard
- `sigsetjmp` / `siglongjmp` to return from the signal handler to the guarded execution entry point

That machinery remains relevant for the `mprotect` memory implementation and future JIT work, but it is no longer on the hot path for ordinary interpreter memory accesses.

## Configuration behavior

`EngineConfiguration.MemoryBoundsChecking` currently has two modes:

- `.mprotect`: prefer the `mprotect`-backed linear memory implementation when available
- `.software`: always use software bounds checks and the software-backed memory implementation

The request is advisory. The engine falls back to `.software` when `mprotect` is unavailable or incompatible with the current configuration, such as:

- platforms without the required `mprotect` / signal support
- AddressSanitizer builds
- token threading

## Non-goals

- Using `mprotect` to remove interpreter bounds checks in the current VM
- Supporting the same reservation strategy for `memory64`
- Implementing a Windows-specific equivalent of the current POSIX-based approach yet
