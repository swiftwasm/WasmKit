// The Embedded Swift platform layer for ESP-IDF, as declared by the
// toolchain's `swift/EmbeddedPlatform.h`. Recent development snapshots call
// these functions instead of `posix_memalign`, `free`, `putchar` and
// `arc4random_buf`. Older toolchains never reference them, and the linker
// drops them.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "esp_random.h"

#define SWIFT_ALLOC_ZERO_MEMORY 0x01ULL

static void *allocate(size_t alignment, size_t size, unsigned long long flags) {
    // A typed allocation may pass zero for the default alignment, and
    // `posix_memalign` rejects anything below the pointer size.
    if (alignment == 0) {
        alignment = 16;
    } else if (alignment < sizeof(void *)) {
        alignment = sizeof(void *);
    }
    void *pointer = NULL;
    if (posix_memalign(&pointer, alignment, size == 0 ? 1 : size) != 0) {
        return NULL;
    }
    if (flags & SWIFT_ALLOC_ZERO_MEMORY) {
        memset(pointer, 0, size);
    }
    return pointer;
}

void *_swift_allocate(size_t alignment, size_t size, unsigned long long flags) {
    return allocate(alignment, size, flags);
}

void _swift_deallocate(void *pointer, size_t alignment, size_t size, unsigned long long flags) {
    free(pointer);
}

void *_swift_typedAllocate(size_t size, size_t alignment, unsigned long long flags,
                           unsigned long long typeId) {
    return allocate(alignment, size, flags);
}

void _swift_typedDeallocate(void *pointer, size_t size, size_t alignment, unsigned long long flags,
                            unsigned long long typeId) {
    free(pointer);
}

void _swift_lockStandardOutput(void) {
    flockfile(stdout);
}

void _swift_unlockStandardOutput(void) {
    funlockfile(stdout);
}

size_t _swift_writeToStandardOutput(const unsigned char *chars, size_t count) {
    if (count == 0) {
        return 0;
    }
    return fwrite(chars, 1, count, stdout);
}

static const char *error_prefix(unsigned long long flags) {
    switch (flags & 0xff) {
    case 1:
        return "Precondition failed";
    case 2:
        return "Assertion failed";
    default:
        return "Fatal error";
    }
}

static void report_error(const unsigned char *message, size_t messageCount,
                         unsigned long long flags) {
    fputs(error_prefix(flags), stdout);
    if (messageCount > 0) {
        printf(": %.*s", (int)messageCount, (const char *)message);
    }
    fputc('\n', stdout);
}

void _swift_reportError(const unsigned char *message, size_t messageCount,
                        unsigned long long flags) {
    report_error(message, messageCount, flags);
}

void _swift_reportErrorAt(const unsigned char *message, size_t messageCount,
                          const unsigned char *fileName, size_t fileNameCount, size_t line,
                          unsigned long long flags) {
    if (fileNameCount > 0) {
        printf("%.*s:%u: ", (int)fileNameCount, (const char *)fileName, (unsigned)line);
    }
    report_error(message, messageCount, flags);
}

void _swift_generateRandom(void *buffer, size_t count) {
    esp_fill_random(buffer, count);
}

void _swift_generateRandomHashSeed(void *buffer, size_t count) {
    esp_fill_random(buffer, count);
}
