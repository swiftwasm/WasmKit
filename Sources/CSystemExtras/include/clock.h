#include <time.h>

inline static clockid_t csystemextras_monotonic_clockid() {
  return CLOCK_MONOTONIC;
}
inline static clockid_t csystemextras_realtime_clockid() {
  return CLOCK_REALTIME;
}
