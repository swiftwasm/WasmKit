#ifndef WASMKIT_TRAP_GUARD_H
#define WASMKIT_TRAP_GUARD_H

#include <stddef.h>
#include <stdbool.h>

#include "Platform.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*wasmkit_trap_guard_fn)(void *WASMKIT_NULLABLE ctx);

/// Runs `fn(ctx)` while converting SIGSEGV/SIGBUS faults inside the current
/// linear-memory reserved range into a non-local return.
///
/// Return value:
/// - false: completed normally
/// - true: trapped due to out-of-bounds linear-memory access
bool wasmkit_trap_guard_run(wasmkit_trap_guard_fn WASMKIT_NONNULL fn, void *WASMKIT_NULLABLE ctx);

/// Updates the currently-active trap guard (if any) with the current memory base
/// and linear-memory reservation size (in bytes).
///
/// Passing `reservation_size == 0` disables handling of faults for the current thread.
void wasmkit_trap_guard_set_current_memory(void *WASMKIT_NULLABLE md, size_t reservation_size);

#ifdef __cplusplus
}
#endif

#endif // WASMKIT_TRAP_GUARD_H
