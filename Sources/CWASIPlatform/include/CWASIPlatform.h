#include <time.h>

// wasi-libc's CLOCK_* macros expand to pointers, which ClangImporter can't
// import as constants; expose them as functions instead.
inline static clockid_t wasi_platform_monotonic_clockid() {
  return CLOCK_MONOTONIC;
}
inline static clockid_t wasi_platform_realtime_clockid() {
  return CLOCK_REALTIME;
}
