#include <stdio.h>
#include <stdlib.h>

#include "w2c2_base.h"
#include "wasi/wasi.h"
#include "wasm-component-ld.h"

void
trap(
    Trap trap
) {
    fprintf(stderr, "TRAP: %s\n", trapDescription(trap));
    abort();
}

wasmMemory*
wasiMemory(
    void* instance
) {
    return wasmcomponentld_memory((wasmcomponentldInstance*)instance);
}

extern char** environ;

int
main(
    int argc,
    char* argv[]
) {
    if (!wasiInit(argc, argv, environ)) {
        fprintf(stderr, "failed to init WASI\n");
        return 1;
    }

    if (!wasiFileDescriptorAdd(-1, ".", NULL)) {
        fprintf(stderr, "failed to add current-directory preopen\n");
        return 1;
    }

    {
        wasmcomponentldInstance instance;
        wasmcomponentldInstantiate(&instance, NULL);
        wasmcomponentld__start(&instance);
        wasmcomponentldFreeInstance(&instance);
    }

    return 0;
}
