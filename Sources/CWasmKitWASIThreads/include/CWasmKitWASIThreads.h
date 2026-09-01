#ifndef CWasmKitWASIThreads_h
#define CWasmKitWASIThreads_h

#include <stddef.h>

typedef void (*wasmkit_wasi_threads_entry)(void *);
typedef struct wasmkit_wasi_threads_event wasmkit_wasi_threads_event;

/// Starts a detached pthread. `stack_size == 0` selects the platform default.
/// Returns zero on success or the pthread error number on failure.
int wasmkit_wasi_threads_start(
    wasmkit_wasi_threads_entry entry,
    void *context,
    size_t stack_size
);

/// A one-shot, blocking event used for worker startup handshakes.
wasmkit_wasi_threads_event *wasmkit_wasi_threads_event_create(void);
void wasmkit_wasi_threads_event_destroy(wasmkit_wasi_threads_event *event);
void wasmkit_wasi_threads_event_wait(wasmkit_wasi_threads_event *event);
void wasmkit_wasi_threads_event_signal(wasmkit_wasi_threads_event *event);

#endif
