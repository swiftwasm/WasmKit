# mprotect-based memory boundary checking

## Background

WasmKit supports two strategies for linear-memory bounds checking. The default software path performs an explicit bounds check for every load/store in `Execution.memoryLoad` / `Execution.memoryStore` (`Sources/WasmKit/Execution/Instructions/Memory.swift`).

On platforms where virtual memory protection and synchronous fault handling are available, we can remove these per-access checks by:

1. Reserving a large virtual address range for each linear memory.
2. Committing (read/write) only the currently-accessible portion.
3. Leaving the rest as inaccessible (PROT_NONE).
4. Converting protection faults (SIGSEGV/SIGBUS) originating from that reserved range into the WebAssembly trap `out of bounds memory access`.

This is the same general technique used by other runtimes:

- **wasmtime** uses guard regions/virtual-memory traps to elide bounds checks when it can rely on host traps.
- **wasm-micro-runtime (WAMR)** has an `OS_ENABLE_HW_BOUND_CHECK` mode that uses `mprotect` plus signal handling and `setjmp`/`longjmp` to convert faults into an out-of-bounds exception.

## Goals

- Remove per-load/per-store software bounds checks on supported platforms (mprotect fast path).
- Keep the existing software-check implementation for platforms where we cannot rely on `mprotect` + signals.
- Ensure the software fallback does **not** add overhead to the mprotect fast path.
- Preserve existing trap semantics (`TrapReason.memoryOutOfBounds`) for out-of-bounds linear memory access.
- Avoid performance regressions (validate with CoreMark; then run a longer benchmark suite).

## Non-goals

- Supporting the same optimization for `memory64` (address space is not practically reservable in full).
- Implementing the optimization on platforms without POSIX-style memory protection and synchronous fault handlers (e.g. WASI).

## Design

### Configuration (runtime)

Bounds checking mode is configured at runtime via `EngineConfiguration`:

- `memoryBoundsChecking`
  - `.auto` (default): prefer mprotect+signals when supported, otherwise software
  - `.mprotect`: require mprotect+signals; propagate errors if mmap/mprotect fails
  - `.software`: always use software bounds checks
- `memoryOffsetGuardSize` (bytes): the maximum constant `memarg.offset` range for which WasmKit is allowed to emit unchecked (mprotect-based) loads/stores.

### Linear memory layout (wasm32)

For wasm32 linear memories (`!isMemory64`), reserve `4GiB + memoryOffsetGuardSize` bytes of virtual address space:

- `[base, base + committed)` is `PROT_READ|PROT_WRITE`
- `[base + committed, base + 4GiB + guard)` is `PROT_NONE`

Loads/stores without software bounds checks are only emitted when:

`memarg.offset + access_size <= memoryOffsetGuardSize`

If `memarg.offset` is larger than the guard, WasmKit falls back to the software bounds-checking opcode for that instruction to keep the mprotect fast path branch-free.

TODO: Explore reducing reservation size further by proving smaller index ranges for some instructions and emitting unchecked ops only in those cases.

### Memory growth

Memory growth becomes:

- Validate limits as today (`maxPageCount`, `ResourceLimiter`).
- `mprotect` the newly-added range from `PROT_NONE` to `PROT_READ|PROT_WRITE`.
- Update `byteCount` (committed size) without relocating/copying the old contents.

### Trap handling

When mprotect mode is active, WasmKit runs the interpreter loop under a per-thread trap guard implemented with:

- process-wide `sigaction` handlers for SIGSEGV/SIGBUS, and
- `sigsetjmp`/`siglongjmp` to convert faults in the reserved range into a normal return path.

The handler:

- Checks whether a trap guard is active on the current thread.
- If active, checks whether `si_addr` is inside the current linear memory reserved range `[md, md + reservation)`.
- If yes, performs `siglongjmp` back to the guard (aborting the interpreter loop).
- Otherwise, chains to the previously-installed handler.

### No fast-path overhead from fallback

All branching between mprotect-fast-path and software-fast-path is done at translation time, by emitting distinct internal VM opcodes for unchecked loads/stores. The mprotect-enabled build does not pay a runtime “mode check” on each access.

## Platform support matrix

Supported:

- macOS (arm64/x86_64)
- Linux (arm64/x86_64)

Falls back to software checks:

- Windows (requires a separate implementation for WinAPI)
- WASI (no `mprotect`/signals)
- `memory64` (address space too large to reserve)
- Token threading model (see Limitations section below)

## Limitations and safety

### Token threading is not supported

mprotect-based bounds checking requires the direct threading model because `siglongjmp` from the signal handler must only unwind through C frames. The token threading model dispatches instructions through Swift frames, which `siglongjmp` cannot safely skip. Attempting to use `.mprotect` or `.auto` with `.token` threading raises `EngineConfigurationError.mprotectRequiresDirectThreading`.

### SA_ONSTACK for defensive stack safety

The signal handler is installed with `SA_ONSTACK` so that it runs on an alternate signal stack (if one has been configured via `sigaltstack`). Combined with `SA_NODEFER` (which allows re-entry so that `siglongjmp` can re-raise the signal disposition), `SA_ONSTACK` prevents infinite handler recursion if the handler itself faults due to a stack overflow.

### Multi-memory: only memory 0 uses unchecked access

The trap guard tracks a single linear memory base and reservation size per thread. Unchecked (mprotect-guarded) loads and stores are therefore restricted to memory index 0. If multi-memory support is added, each memory would need its own guard registration and the signal handler would need to check all registered ranges.

### Error propagation differs between .auto and .mprotect

When `.mprotect` is explicitly requested by the user, `mmap`/`mprotect` failures during memory allocation are propagated as errors so that resource exhaustion (e.g. `vm.max_map_count` on Linux) is not masked. With `.auto`, the same failures are silently swallowed and the runtime falls back to software bounds checks.

