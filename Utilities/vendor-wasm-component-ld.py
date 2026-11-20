#!/usr/bin/env python3

import os
import shutil
import subprocess
import sys


SOURCE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CHECKOUT_DEPENDENCY = os.path.join(SOURCE_ROOT, "Vendor", "checkout-dependency")

W2C2_SOURCE_DIR = os.path.join(SOURCE_ROOT, "Vendor", "w2c2")
W2C2_BUILD_DIR = os.path.join(SOURCE_ROOT, ".build", "w2c2")
W2C2_BINARY = os.path.join(W2C2_BUILD_DIR, "w2c2", "w2c2")

WASM_COMPONENT_LD_SOURCE_DIR = os.path.join(SOURCE_ROOT, "Vendor", "wasm-component-ld")
WASM_COMPONENT_LD_TARGET_DIR = os.path.join(SOURCE_ROOT, ".build", "wasm-component-ld")
INPUT_WASM = os.path.join(
    SOURCE_ROOT,
    ".build",
    "wasm-component-ld",
    "wasm32-wasip1",
    "release",
    "wasm-component-ld.wasm",
)
OUTPUT_DIR = os.path.join(SOURCE_ROOT, "Sources", "wasm-component-ld")
OUTPUT_C = os.path.join(OUTPUT_DIR, "wasm-component-ld.c")
OUTPUT_H = os.path.join(OUTPUT_DIR, "wasm-component-ld.h")
OUTPUT_W2C2_DIR = os.path.join(OUTPUT_DIR, "w2c2")
OUTPUT_WASI_DIR = os.path.join(OUTPUT_DIR, "wasi")
OUTPUT_W2C2_BASE_H = os.path.join(OUTPUT_DIR, "w2c2_base.h")
OUTPUT_MAIN_C = os.path.join(OUTPUT_DIR, "main.c")

W2C2_BASE_H = os.path.join(W2C2_SOURCE_DIR, "w2c2", "w2c2_base.h")
W2C2_WASI_H = os.path.join(W2C2_SOURCE_DIR, "wasi", "wasi.h")
W2C2_WASI_C = os.path.join(W2C2_SOURCE_DIR, "wasi", "wasi.c")
W2C2_MAC_H = os.path.join(W2C2_SOURCE_DIR, "wasi", "mac.h")
W2C2_MAC_C = os.path.join(W2C2_SOURCE_DIR, "wasi", "mac.c")
W2C2_WIN32_H = os.path.join(W2C2_SOURCE_DIR, "wasi", "win32.h")
W2C2_WIN32_C = os.path.join(W2C2_SOURCE_DIR, "wasi", "win32.c")

MAIN_C_SOURCE = """#include <stdio.h>
#include <stdlib.h>

#include "w2c2_base.h"
#include "wasi/wasi.h"
#include "wasm-component-ld.h"

void
trap(
    Trap trap
) {
    fprintf(stderr, "TRAP: %s\\n", trapDescription(trap));
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
        fprintf(stderr, "failed to init WASI\\n");
        return 1;
    }

    if (!wasiFileDescriptorAdd(-1, ".", NULL)) {
        fprintf(stderr, "failed to add current-directory preopen\\n");
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
"""


def run(arguments, cwd=None):
    print("Running: " + " ".join(arguments))
    subprocess.run(arguments, check=True, cwd=cwd)


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def copy_file(src, dst):
    print("Copying: " + src + " -> " + dst)
    shutil.copyfile(src, dst)


def main():
    if not os.path.isdir(W2C2_SOURCE_DIR) or not os.path.isdir(WASM_COMPONENT_LD_SOURCE_DIR):
        run([CHECKOUT_DEPENDENCY, "w2c2", "wasm-component-ld"])

    if not os.path.isdir(W2C2_SOURCE_DIR):
        fail("error: w2c2 source not found at " + W2C2_SOURCE_DIR)
    if not os.path.isdir(WASM_COMPONENT_LD_SOURCE_DIR):
        fail("error: wasm-component-ld source not found at " + WASM_COMPONENT_LD_SOURCE_DIR)

    os.makedirs(W2C2_BUILD_DIR, exist_ok=True)
    os.makedirs(WASM_COMPONENT_LD_TARGET_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_W2C2_DIR, exist_ok=True)
    os.makedirs(OUTPUT_WASI_DIR, exist_ok=True)

    run(
        [
            "cargo",
            "build",
            "--target",
            "wasm32-wasip1",
            "--release",
            "--target-dir",
            "./.build/wasm-component-ld/",
            "--manifest-path",
            "Vendor/wasm-component-ld/Cargo.toml",
        ],
        cwd=SOURCE_ROOT,
    )

    if not os.path.isfile(INPUT_WASM):
        fail("error: expected output wasm not found at " + INPUT_WASM)

    run(["cmake", "-S", W2C2_SOURCE_DIR, "-B", W2C2_BUILD_DIR, "-G", "Ninja"])
    run(["cmake", "--build", W2C2_BUILD_DIR])
    run([W2C2_BINARY, INPUT_WASM, OUTPUT_C])

    copy_file(W2C2_BASE_H, OUTPUT_W2C2_BASE_H)
    copy_file(W2C2_BASE_H, os.path.join(OUTPUT_W2C2_DIR, "w2c2_base.h"))
    copy_file(W2C2_WASI_H, os.path.join(OUTPUT_WASI_DIR, "wasi.h"))
    copy_file(W2C2_WASI_C, os.path.join(OUTPUT_WASI_DIR, "wasi.c"))
    copy_file(W2C2_MAC_H, os.path.join(OUTPUT_WASI_DIR, "mac.h"))
    copy_file(W2C2_MAC_C, os.path.join(OUTPUT_WASI_DIR, "mac.c"))
    copy_file(W2C2_WIN32_H, os.path.join(OUTPUT_WASI_DIR, "win32.h"))
    copy_file(W2C2_WIN32_C, os.path.join(OUTPUT_WASI_DIR, "win32.c"))

    with open(OUTPUT_MAIN_C, "w") as f:
        f.write(MAIN_C_SOURCE)
    print("Wrote: " + OUTPUT_MAIN_C)

    print("Generated:")
    print("  " + OUTPUT_C)
    print("  " + OUTPUT_H)


if __name__ == "__main__":
    main()
