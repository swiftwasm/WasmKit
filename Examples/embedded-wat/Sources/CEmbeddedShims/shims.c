#if defined(__APPLE__)
#include <stdbool.h>
#include <stdint.h>

__attribute__((used)) bool
embedded_wat_isOSVersionAtLeast(intptr_t major, intptr_t minor, intptr_t patch)
    __asm__("_$es26_stdlib_isOSVersionAtLeastyBi1_Bw_BwBwtF");

bool embedded_wat_isOSVersionAtLeast(intptr_t major, intptr_t minor, intptr_t patch) {
    return true;
}
#endif
