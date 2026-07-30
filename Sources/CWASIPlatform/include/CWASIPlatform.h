#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <time.h>

// wasi-libc's CLOCK_* macros expand to pointers, which ClangImporter can't
// import as constants; expose them as functions instead.
inline static clockid_t wasi_platform_monotonic_clockid() {
  return CLOCK_MONOTONIC;
}
inline static clockid_t wasi_platform_realtime_clockid() {
  return CLOCK_REALTIME;
}

// wasi-libc defines these as macros derived from WASI ABI constants, which
// ClangImporter can't import; re-expose them under importable names.
enum {
  WASI_PLATFORM_O_APPEND = O_APPEND,
  WASI_PLATFORM_O_NONBLOCK = O_NONBLOCK,
  WASI_PLATFORM_O_NOFOLLOW = O_NOFOLLOW,
  WASI_PLATFORM_O_DIRECTORY = O_DIRECTORY,
  WASI_PLATFORM_O_CREAT = O_CREAT,
  WASI_PLATFORM_O_EXCL = O_EXCL,
  WASI_PLATFORM_O_TRUNC = O_TRUNC,
  WASI_PLATFORM_PATH_MAX = PATH_MAX,
  WASI_PLATFORM_DT_BLK = DT_BLK,
  WASI_PLATFORM_DT_CHR = DT_CHR,
  WASI_PLATFORM_DT_DIR = DT_DIR,
  WASI_PLATFORM_DT_LNK = DT_LNK,
  WASI_PLATFORM_DT_REG = DT_REG,
};
