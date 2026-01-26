# mprotect-based memory boundary checking

## Background

WasmKit currently performs software bounds checks for every linear-memory load/store in `Execution.memoryLoad` / `Execution.memoryStore` (`Sources/WasmKit/Execution/Instructions/Memory.swift`).

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
  - `.mprotect`: request mprotect+signals, but fall back to software if not available
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

Planned initial support:

- macOS (arm64/x86_64): enabled
- Linux (arm64/x86_64): enabled

Disabled (fallback to software checks):

- WASI (no `mprotect`/signals)
- `memory64` (uses software bounds checks)

## Testing & performance validation plan

1. Run a quick build + targeted tests.
2. Run CoreMark benchmark on `main` and on this branch frequently during development.
3. After confidence, run WishYouWereFast benchmark suite and compare results against `main`.

