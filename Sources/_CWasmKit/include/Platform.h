#ifndef WASMKIT_PLATFORM_H
#define WASMKIT_PLATFORM_H

// NOTE: The `swiftasynccc` attribute is considered to be a Clang extension
// rather than a language standard feature after LLVM 19. We check
// `__has_attribute(swiftasynccc)` too for compatibility with older versions.
// See https://github.com/llvm/llvm-project/pull/85347
#if !defined(__wasi__) && (__has_feature(swiftasynccc) || __has_extension(swiftasynccc))
#  define WASMKIT_HAS_SWIFTASYNCCC 1
#else
#  define WASMKIT_HAS_SWIFTASYNCCC 0
#endif

#if WASMKIT_HAS_SWIFTASYNCCC
#  define WASMKIT_USE_DIRECT_THREADED_CODE 1
#else
#  define WASMKIT_USE_DIRECT_THREADED_CODE 0
#endif

#define SWIFT_CC_swift __attribute__((swiftcall))
#define SWIFT_CC_swiftasync __attribute__((swiftasynccall))
#define SWIFT_CC(CC) SWIFT_CC_##CC

#define SWIFT_CONTEXT __attribute__((swift_context))
#define SWIFT_ERROR_RESULT __attribute__((swift_error_result))

#endif // WASMKIT_PLATFORM_H
