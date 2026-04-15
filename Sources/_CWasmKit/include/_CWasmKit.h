#ifndef WASMKIT__CWASMKIT_H
#define WASMKIT__CWASMKIT_H

#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "Platform.h"

// MARK: - Hardware Atomic Operations for Wasm Shared Memory

#if __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error "WasmKit atomic operations only support little-endian platforms"
#endif

#define WASMKIT_DEFINE_ATOMICS(WIDTH, CTYPE) \
static inline CTYPE wasmkit_atomic_load_##WIDTH(const void *_Nonnull ptr) { \
    return __atomic_load_n((const CTYPE *)ptr, __ATOMIC_SEQ_CST); \
} \
static inline void wasmkit_atomic_store_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    __atomic_store_n((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_add_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_fetch_add((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_sub_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_fetch_sub((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_and_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_fetch_and((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_or_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_fetch_or((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_xor_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_fetch_xor((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline CTYPE wasmkit_atomic_rmw_xchg_##WIDTH(void *_Nonnull ptr, CTYPE val) { \
    return __atomic_exchange_n((CTYPE *)ptr, val, __ATOMIC_SEQ_CST); \
} \
static inline _Bool wasmkit_atomic_cmpxchg_##WIDTH( \
    void *_Nonnull ptr, CTYPE *_Nonnull expected, CTYPE desired \
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
typedef uint64_t *_Nonnull Sp;
typedef void *_Nullable Pc;
typedef void *_Nullable Md;
typedef size_t Ms;

#include "TrapGuard.h"

#if WASMKIT_USE_DIRECT_THREADED_CODE
/// The function type for executing a single instruction and transitioning to
/// the next instruction by tail calling. `swiftasync` calling convention is
/// used to keep `state` in the context register and to force tail calling.
///
/// See https://clang.llvm.org/docs/AttributeReference.html#swiftasynccall for
/// more information about `swiftasynccall`.
typedef SWIFT_CC(swiftasync) void (* _Nonnull wasmkit_tc_exec)(
    uint64_t *_Nonnull sp, Pc, Md, Ms, SWIFT_CONTEXT void *_Nullable state);

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
    wasmkit_tc_exec exec, Sp sp, Pc pc, Md md, Ms ms, void *_Nullable state
) {
  exec(sp, pc, md, ms, state);
}
#endif

static inline void wasmkit_fwrite_stderr(const char *_Nonnull str, size_t len) {
  fwrite(str, 1, len, stderr);
}

int wasmkit_address_sanitizer_enabled(void);

// MARK: - Swift Runtime Functions

struct SwiftError;
#ifdef __cplusplus
extern "C" {
#endif
extern void swift_errorRelease(const struct SwiftError *_Nonnull object);
#ifdef __cplusplus
}
#endif

/// Releases the given Swift error object.
static inline void wasmkit_swift_errorRelease(const void *_Nonnull object) {
#ifdef __cplusplus
    swift_errorRelease(static_cast<const struct SwiftError *_Nonnull>(object));
#else
    swift_errorRelease(object);
#endif
}

#endif // WASMKIT__CWASMKIT_H
