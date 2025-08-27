#ifndef WASMKIT__CWASMKIT_H
#define WASMKIT__CWASMKIT_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "Platform.h"

// MARK: - Execution Parameters
// See ExecutionContext.swift for more information about each execution
// parameter.
typedef uint64_t *_Nonnull Sp;
typedef void *_Nullable Pc;
typedef void *_Nullable Md;
typedef size_t Ms;

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

static inline void wasmkit_fwrite_stderr(const char *_Nonnull str, size_t len) {
  fwrite(str, 1, len, stderr);
}

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
