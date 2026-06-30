#ifndef WASMKIT_TRAP_GUARD_H
#define WASMKIT_TRAP_GUARD_H

#include <stddef.h>
#include <stdbool.h>
#include "Platform.h"

#if WASMKIT_MPROTECT_BOUND_CHECKING
#include <stdatomic.h>
#endif

#ifndef _Nullable
#  ifndef __clang__
#    define _Nullable
#  endif
#endif

#ifndef _Nonnull
#  ifndef __clang__
#    define _Nonnull
#  endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*wasmkit_trap_guard_fn)(void *_Nullable ctx);

/// Runs `fn(ctx)` while converting SIGSEGV/SIGBUS faults inside the current
/// linear-memory reserved range into a non-local return.
///
/// Return value:
/// - false: completed normally
/// - true: trapped due to out-of-bounds linear-memory access
bool wasmkit_trap_guard_run(wasmkit_trap_guard_fn _Nonnull fn, void *_Nullable ctx);

/// Updates the currently-active trap guard (if any) with the current memory base
/// and linear-memory reservation size (in bytes).
///
/// Passing `reservation_size == 0` disables handling of faults for the current thread.
void wasmkit_trap_guard_set_current_memory(void *_Nullable md, size_t reservation_size);

// MARK: - Shared Memory Guard (signal handler spinlock coordination)

#if WASMKIT_MPROTECT_BOUND_CHECKING

/// Guard struct for coordinating shared memory grow with the signal handler.
///
/// The signal handler acquires the spinlock when a fault lands in
/// [base_pointer, base_pointer + max_byte_count). If the faulting address is
/// below current_byte_count, pages are committed and the handler returns
/// (retrying the instruction). Otherwise it's a genuine OOB trap.
typedef struct wasmkit_shared_memory_guard {
    atomic_flag spinlock;
    _Atomic(size_t) current_byte_count;
    void *_Nonnull base_pointer;
    size_t max_byte_count;
} wasmkit_shared_memory_guard_t;

/// Register a shared memory guard for signal handler coordination.
/// Returns 0 on success, -1 if the registry is full.
int wasmkit_shared_memory_guard_register(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Unregister a shared memory guard. Must be called before deallocation.
void wasmkit_shared_memory_guard_unregister(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Acquire the guard's spinlock (for use by grow).
void wasmkit_shared_memory_guard_lock(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Release the guard's spinlock.
void wasmkit_shared_memory_guard_unlock(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Atomically set the committed byte count (use from Swift — Swift strips _Atomic).
void wasmkit_shared_memory_guard_set_size(wasmkit_shared_memory_guard_t *_Nonnull guard, size_t size);

/// Atomically get the committed byte count.
size_t wasmkit_shared_memory_guard_get_size(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Initialize a shared memory guard struct with the given parameters.
void wasmkit_shared_memory_guard_init(wasmkit_shared_memory_guard_t *_Nonnull guard,
                                       void *_Nonnull base_pointer,
                                       size_t max_byte_count,
                                       size_t initial_byte_count);

/// Acquire the guard's spinlock for grow operations, blocking SIGSEGV/SIGBUS first.
/// This prevents self-deadlock if a signal arrives while the lock is held.
/// Must be paired with unlock_for_grow. Must not be called recursively.
void wasmkit_shared_memory_guard_lock_for_grow(wasmkit_shared_memory_guard_t *_Nonnull guard);

/// Release the guard's spinlock after grow, restoring the previous signal mask.
void wasmkit_shared_memory_guard_unlock_for_grow(wasmkit_shared_memory_guard_t *_Nonnull guard);

#else

// Stubs when mprotect bound checking is disabled.
typedef struct wasmkit_shared_memory_guard {
    char spinlock;
    size_t current_byte_count;
    void *_Nonnull base_pointer;
    size_t max_byte_count;
} wasmkit_shared_memory_guard_t;

static inline int wasmkit_shared_memory_guard_register(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; return 0; }
static inline void wasmkit_shared_memory_guard_unregister(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; }
static inline void wasmkit_shared_memory_guard_init(wasmkit_shared_memory_guard_t *_Nonnull g,
                                                     void *_Nonnull base_pointer,
                                                     size_t max_byte_count,
                                                     size_t initial_byte_count) {
    g->spinlock = 0;
    g->base_pointer = base_pointer;
    g->max_byte_count = max_byte_count;
    g->current_byte_count = initial_byte_count;
}
static inline void wasmkit_shared_memory_guard_lock(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; }
static inline void wasmkit_shared_memory_guard_unlock(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; }
static inline void wasmkit_shared_memory_guard_lock_for_grow(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; }
static inline void wasmkit_shared_memory_guard_unlock_for_grow(wasmkit_shared_memory_guard_t *_Nonnull g) { (void)g; }
static inline void wasmkit_shared_memory_guard_set_size(wasmkit_shared_memory_guard_t *_Nonnull g, size_t s) { g->current_byte_count = s; }
static inline size_t wasmkit_shared_memory_guard_get_size(wasmkit_shared_memory_guard_t *_Nonnull g) { return g->current_byte_count; }

#endif

#ifdef __cplusplus
}
#endif

#endif // WASMKIT_TRAP_GUARD_H
