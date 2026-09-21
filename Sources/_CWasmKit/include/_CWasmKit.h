#ifndef WASMKIT__CWASMKIT_H
#define WASMKIT__CWASMKIT_H

#include <stddef.h>
#include <stdint.h>
// <stdint.h> must precede <stdatomic.h>: some bare-metal C libraries (newlib)
// declare the atomic typedefs in terms of int_least8_t and friends without
// including <stdint.h> themselves.
#include <stdatomic.h>

#include "Platform.h"

// MARK: - Hardware Atomic Operations for Wasm Shared Memory

#if __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error "WasmKit atomic operations only support little-endian platforms"
#endif

#define WASMKIT_DEFINE_ATOMICS(WIDTH, CTYPE) \
static inline CTYPE wasmkit_atomic_load_##WIDTH(const void *WASMKIT_NONNULL ptr) { \
    return __atomic_load_n((const CTYPE *)ptr, __ATOMIC_SEQ_CST); \
} \
static inline void wasmkit_atomic_store_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    __atomic_store_n((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_add_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_fetch_add((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_sub_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_fetch_sub((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_and_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_fetch_and((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_or_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_fetch_or((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_xor_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_fetch_xor((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_xchg_##WIDTH(void *WASMKIT_NONNULL ptr, CTYPE val) { \
    return __atomic_exchange_n((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline _Bool wasmkit_atomic_cmpxchg_##WIDTH( \
    void *WASMKIT_NONNULL ptr, CTYPE *WASMKIT_NONNULL expected, CTYPE desired \
) { \
    return __atomic_compare_exchange_n( \
        (CTYPE *)ptr, expected, desired, 0, \
        __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST); \
}

WASMKIT_DEFINE_ATOMICS(8,  uint8_t)
WASMKIT_DEFINE_ATOMICS(16, uint16_t)
WASMKIT_DEFINE_ATOMICS(32, uint32_t)
WASMKIT_DEFINE_ATOMICS(64, uint64_t)
#undef WASMKIT_DEFINE_ATOMICS

static inline void wasmkit_atomic_fence(void) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

// MARK: - Execution Parameters
// See ExecutionContext.swift for more information about each execution
// parameter.
typedef uint64_t *WASMKIT_NONNULL Sp;
typedef void *WASMKIT_NULLABLE Pc;
typedef void *WASMKIT_NULLABLE Md;
// NOTE: `uintptr_t`, not `size_t`: they have the same representation, but Swift's
// ClangImporter maps `size_t` to `Int` and `uintptr_t` to `UInt`, and `Ms` must be
// unsigned on the Swift side so that a bounds check is a single unsigned compare.
typedef uintptr_t Ms;

#include "TrapGuard.h"

#if WASMKIT_USE_DIRECT_THREADED_CODE
/// The function type for executing a single instruction and transitioning to
/// the next instruction by tail calling. `swiftasync` calling convention is
/// used to keep `state` in the context register and to force tail calling.
///
/// See https://clang.llvm.org/docs/AttributeReference.html#swiftasynccall for
/// more information about `swiftasynccall`.
///
/// `ireg` and `freg` are the integer and float accumulators. Each is live only
/// between the handler that produces a value into it and the handler right
/// after it.
typedef WASMKIT_TC_CC void (* WASMKIT_NONNULL wasmkit_tc_exec)(
    uint64_t *WASMKIT_NONNULL sp, Pc, Md, Ms, uint64_t ireg, double freg,
    WASMKIT_TC_CONTEXT void *WASMKIT_NULLABLE state);

/// Declares an accumulator value that the next handler never reads, for a
/// handler that does not use the accumulator. Leaving it indeterminate lets a
/// handler with a call in it pass on whatever the register holds instead of
/// preserving the incoming value across the call.
#define WASMKIT_DEAD_ACCUMULATOR(type, name)                \
    _Pragma("clang diagnostic push")                        \
    _Pragma("clang diagnostic ignored \"-Wuninitialized\"") \
    type name = name;                                       \
    _Pragma("clang diagnostic pop")

/// The entry point for executing a direct-threaded interpreter loop.
/// The interpreter loop is implemented as a tail-recursive function that
/// executes a single instruction and transitions to the next instruction by
/// tail calling.
///
/// NOTE: This entry point must be implemented in C for now because of an issue
/// with the ClangImporter that ignores the explicitly specified calling
/// convention and it leads to a miscompilation of the tail call.
/// See https://github.com/swiftlang/swift/issues/69264
static inline void wasmkit_tc_start(
    wasmkit_tc_exec exec, Sp sp, Pc pc, Md md, Ms ms, void *WASMKIT_NULLABLE state
) {
  exec(sp, pc, md, ms, 0, 0.0, state);
}
#endif

int wasmkit_address_sanitizer_enabled(void);

// MARK: - Swift Runtime Functions

struct SwiftError;
#ifdef __cplusplus
extern "C" {
#endif
extern void swift_errorRelease(const struct SwiftError *WASMKIT_NONNULL object);
#ifdef __cplusplus
}
#endif

/// Releases the given Swift error object.
static inline void wasmkit_swift_errorRelease(const void *WASMKIT_NONNULL object) {
#ifdef __cplusplus
    swift_errorRelease(static_cast<const struct SwiftError *WASMKIT_NONNULL>(object));
#else
    swift_errorRelease(object);
#endif
}

// MARK: - Allocation that can fail

// Swift's `UnsafeMutableRawPointer.allocate` and `Array(repeating:count:)` go
// through `swift_slowAlloc`, which calls `swift::crash("Could not allocate
// memory.")` when the allocator returns null -- there is no failable form in
// the standard library. A guest chooses its own memory and table sizes, so
// those allocations have to be able to report failure instead of taking the
// host process down. These wrap the C allocator, which every target this
// package supports provides.

// A freestanding target has no hosted <stdlib.h>, and Embedded Swift's runtime
// declares only `posix_memalign` and `free` (EmbeddedRuntime.swift), so those
// are the allocation symbols available there.
#if defined(__has_include)
#  if __has_include(<stdlib.h>)
#    include <stdlib.h>
#    define WASMKIT_HOSTED_LIBC 1
#  endif
#endif
#ifndef WASMKIT_HOSTED_LIBC
int posix_memalign(void *WASMKIT_NULLABLE *WASMKIT_NONNULL memptr, size_t alignment, size_t size);
void free(void *WASMKIT_NULLABLE ptr);
#endif

/// Zero-filled allocation of `byteCount` bytes, or NULL if it cannot be
/// satisfied.
///
/// `calloc` lets the allocator serve a large request from fresh zero pages
/// without writing to them, so a large allocation that is never used costs no
/// physical memory. The freestanding path has to clear by hand.
static inline void *WASMKIT_NULLABLE wasmkit_alloc_zeroed(size_t byteCount) {
    // Ask for at least one byte, so a zero-sized request still yields a pointer
    // that `wasmkit_free` can release.
    size_t size = byteCount ? byteCount : 1;
#ifdef WASMKIT_HOSTED_LIBC
    return calloc(size, 1);
#else
    void *ptr = 0;
    // A power of two and a multiple of sizeof(void *) on every target here, and
    // wider than anything this storage holds.
    if (posix_memalign(&ptr, 16, size) != 0) {
        return 0;
    }
    __builtin_memset(ptr, 0, size);
    return ptr;
#endif
}

/// Releases storage from ``wasmkit_alloc_zeroed``. A NULL pointer is ignored.
static inline void wasmkit_free(void *WASMKIT_NULLABLE ptr) {
    free(ptr);
}

#endif // WASMKIT__CWASMKIT_H
