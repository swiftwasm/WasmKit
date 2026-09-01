# WASI Threads

WasmKit supports the core WASI Threads Preview 1 ABI in the CLI:

```console
wasmkit-cli run --wasi-threads --wasi-threads-max 8 program.wasm
```

This enables the `wasi.thread-spawn` import with signature `(i32) -> i32`.
Each successful call returns a positive, monotonically increasing thread ID and
starts a fresh module instance in a fresh `Store`. The child calls
`wasi_thread_start(i32 threadID, i32 startArgument)`.

The mode assumes a `wasm32-wasi-threads` module importing one shared memory as
`env.memory`. That shared backing is the only mutable state shared between
instances. Modules with imported tables, mutable globals, extra memories, or
other non-standard shapes are unsupported embedder configurations.

`--wasi-threads-max` defaults to 64 and includes the main guest thread, so a
limit of one permits no children. IDs are allocated from 1 through
`0x1FFFFFFF`, are never reused, and failed attempts after reservation also
consume an ID.

This is intentionally a process-oriented CLI capability, not a general
long-lived embedding API. A worker trap or `proc_exit` terminates the host
process; returning from `_start` also terminates it, allowing the operating
system to clean up detached workers. It requires a 64-bit macOS or Linux host,
the `MultiThread` package trait, direct-threaded execution, the threads
feature, mprotect bounds checking, and an engine without an interceptor.
