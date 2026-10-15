#ifndef WASMKIT_PLATFORM_H
#define WASMKIT_PLATFORM_H

// Clang nullability annotations; no-op on other compilers.
#if defined(__clang__)
#  define WASMKIT_NONNULL _Nonnull
#  define WASMKIT_NULLABLE _Nullable
#else
#  define WASMKIT_NONNULL
#  define WASMKIT_NULLABLE
#endif

// NOTE: The `swiftasynccc` attribute is considered to be a Clang extension
// rather than a language standard feature after LLVM 19. We check
// `__has_extension(swiftasynccc)` too for compatibility with older versions.
// See https://github.com/llvm/llvm-project/pull/85347
#if defined(__clang__) && !defined(__wasi__)
#  if __has_feature(swiftasynccc) || __has_extension(swiftasynccc)
#    define WASMKIT_HAS_SWIFTASYNCCC 1
#  else
#    define WASMKIT_HAS_SWIFTASYNCCC 0
#  endif
#else
#  define WASMKIT_HAS_SWIFTASYNCCC 0
#endif

// How a handler reaches the next one: the calling convention that makes the
// dispatch a jump rather than a call.
//
// `swiftasynccall` is the default where it exists, and additionally keeps
// `state` in the async context register. It is documented to guarantee tail
// calls and on some targets does not honour that: on armv7em the dispatch
// compiles to `blx`, a real call, so the native stack grows by a frame for
// every guest instruction and the interpreter runs off the end of it within
// milliseconds. `musttail` carries the same guarantee and is enforced -- a
// call the compiler cannot turn into a jump is an error rather than a silent
// call -- at the cost of passing `state` as an ordinary argument.
//
// Select one with -DWASMKIT_TC_USE=swiftasynccc or -DWASMKIT_TC_USE=musttail.
// Asking for one that this compiler and target cannot provide is an error:
// quietly falling back is how the armv7em breakage went unnoticed.
#define WASMKIT_TC_CAT_(a, b) a##b
#define WASMKIT_TC_CAT(a, b) WASMKIT_TC_CAT_(a, b)
#define WASMKIT_TC_OPTION_swiftasynccc 1
#define WASMKIT_TC_OPTION_musttail 2

#if defined(__clang__) && __has_attribute(musttail)
#  define WASMKIT_HAS_MUSTTAIL 1
#else
#  define WASMKIT_HAS_MUSTTAIL 0
#endif

#if defined(WASMKIT_TC_USE)
#  define WASMKIT_TC_CHOICE WASMKIT_TC_CAT(WASMKIT_TC_OPTION_, WASMKIT_TC_USE)
#  if WASMKIT_TC_CHOICE == 0
#    error "WASMKIT_TC_USE must be swiftasynccc or musttail"
#  elif WASMKIT_TC_CHOICE == WASMKIT_TC_OPTION_swiftasynccc && !WASMKIT_HAS_SWIFTASYNCCC
#    error "WASMKIT_TC_USE=swiftasynccc, but this compiler does not offer swiftasynccall"
#  elif WASMKIT_TC_CHOICE == WASMKIT_TC_OPTION_musttail && !WASMKIT_HAS_MUSTTAIL
#    error "WASMKIT_TC_USE=musttail, but this compiler does not offer the musttail attribute"
#  endif
#elif WASMKIT_HAS_SWIFTASYNCCC
#  define WASMKIT_TC_CHOICE WASMKIT_TC_OPTION_swiftasynccc
#else
#  define WASMKIT_TC_CHOICE 0
#endif

// Both conventions exist only where Clang supports Swift's calling conventions
// at all, which is x86, x86-64, ARM and AArch64 -- the handler bodies are Swift
// functions declared `SWIFT_CC(swift)`, so a target without that support has no
// direct threading whichever option it picks.
//
// The Swift side cannot read this macro from `#if`, so it repeats that
// architecture list instead; see `runDirectThreaded` in Execution.swift. Keep
// the two in step, and never let the Swift list be the more permissive one: it
// decides whether the names below are referenced at all.
#if WASMKIT_TC_CHOICE
#  define WASMKIT_USE_DIRECT_THREADED_CODE 1
#else
#  define WASMKIT_USE_DIRECT_THREADED_CODE 0
#endif

#if WASMKIT_TC_CHOICE == WASMKIT_TC_OPTION_musttail
// The plain C convention, so `state` is an ordinary argument rather than the
// async context register, and an enforced tail call.
#  define WASMKIT_TC_CC
#  define WASMKIT_TC_CONTEXT
#  define WASMKIT_TC_MUSTTAIL __attribute__((musttail))
#else
#  define WASMKIT_TC_CC SWIFT_CC(swiftasync)
#  define WASMKIT_TC_CONTEXT SWIFT_CONTEXT
#  define WASMKIT_TC_MUSTTAIL
#endif

#if defined(__APPLE__)
#  include <TargetConditionals.h>
#endif

#if defined(__linux__) || (defined(__APPLE__) && TARGET_OS_OSX)
#  define WASMKIT_MPROTECT_BOUND_CHECKING 1
#else
#  define WASMKIT_MPROTECT_BOUND_CHECKING 0
#endif

#if defined(__has_feature)
#  if __has_feature(address_sanitizer)
#    define WASMKIT_ADDRESS_SANITIZER_ENABLED 1
#  else
#    define WASMKIT_ADDRESS_SANITIZER_ENABLED 0
#  endif
#else
#  define WASMKIT_ADDRESS_SANITIZER_ENABLED 0
#endif

#define SWIFT_CC_swift __attribute__((swiftcall))
#define SWIFT_CC_swiftasync __attribute__((swiftasynccall))
#define SWIFT_CC(CC) SWIFT_CC_##CC

#define SWIFT_CONTEXT __attribute__((swift_context))
#define SWIFT_ERROR_RESULT __attribute__((swift_error_result))

#endif // WASMKIT_PLATFORM_H
