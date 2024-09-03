#ifndef WASMKIT__CWASMKIT_H
#define WASMKIT__CWASMKIT_H

#include <stddef.h>
#include <stdint.h>

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
typedef SWIFT_CC(swiftasync) void (*wasmkit_tc_exec)(
    uint64_t *_Nonnull sp, Pc, Md, Ms, SWIFT_CONTEXT void *_Nullable state);

#endif // WASMKIT__CWASMKIT_H
