#ifndef WASMKIT_TRAP_GUARD_H
#define WASMKIT_TRAP_GUARD_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*wasmkit_trap_guard_fn)(void *_Nullable ctx);

/// Runs `fn(ctx)` while converting SIGSEGV/SIGBUS faults inside the current
/// linear-memory reserved range into a non-local return.
///
/// Return value:
/// - 0: completed normally
/// - 1: trapped due to out-of-bounds linear-memory access
int wasmkit_trap_guard_run(wasmkit_trap_guard_fn _Nonnull fn, void *_Nullable ctx);

/// Updates the currently-active trap guard (if any) with the current memory base
/// and linear-memory reservation size (in bytes).
///
/// Passing `reservation_size == 0` disables handling of faults for the current thread.
void wasmkit_trap_guard_set_current_memory(void *_Nullable md, size_t reservation_size);

#ifdef __cplusplus
}
#endif

#endif // WASMKIT_TRAP_GUARD_H

