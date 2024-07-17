// This file is used to provide a "just enough" implementation of some C standard library functions
// required by Embedded target builds.
#include <stdint.h>
#include <stddef.h>
#define WASM_PAGE_SIZE 0x10000

size_t __builtin_wasm_memory_grow(int32_t index, size_t delta);
void *__builtin_memcpy(void *dest, const void *src, size_t n);

static void* alignedAlloc(size_t alignment, size_t size) {
    size_t basePageSize = __builtin_wasm_memory_grow(0, (size + 0xffff) / 0x10000);
    if (basePageSize == (size_t)-1) {
        return NULL;
    }
    size_t base = basePageSize * WASM_PAGE_SIZE;
    base = (base + alignment - 1) & -alignment;
    return (void*)base;
}

/// NOTE: always allocates a new memory page by `memory.grow`
int posix_memalign(void** memptr, size_t alignment, size_t size) {
    void* ptr = alignedAlloc(alignment, size);
    if (ptr == NULL) {
        return -1;
    }
    *memptr = ptr;
    return 0;
}

/// NOTE: always allocates a new memory page by `memory.grow` and copies the old data
void* cabi_realloc(void* old, size_t oldSize, size_t align, size_t newSize) {
    if (old != NULL) {
        void* new = alignedAlloc(align, newSize);
        if (new != NULL) {
            __builtin_memcpy(new, old, oldSize < newSize ? oldSize : newSize);
        }
        return new;
    } else {
        return alignedAlloc(align, newSize);
    }
}

void *memmove(void *dest, const void *src, size_t n) {
    return __builtin_memcpy(dest, src, n);
}

void *memcpy(void *dest, const void *src, size_t n) {
    // `memory.copy` is safe even if `src` and `dest` overlap
    // > Copying takes place as if an intermediate buffer were used, allowing the destination and source to overlap.
    // > https://github.com/WebAssembly/bulk-memory-operations/blob/master/proposals/bulk-memory-operations/Overview.md
    return __builtin_memcpy(dest, src, n);
}

/// NOTE: does nothing as we don't manage memory chunks
void free(void *ptr) {}

/// NOTE: just returns the input character as is, no output is produced
int putchar(int c) {
    return c;
}

/// NOTE: fills the buffer with a constant value
void arc4random_buf(void *buf, size_t n) {
    for (size_t i = 0; i < n; i++) {
        ((uint8_t *)buf)[i] = (uint8_t)42;
    }
}
