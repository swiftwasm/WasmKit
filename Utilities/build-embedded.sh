#!/bin/bash
# Compile-checks the WasmKit engine for a bare-metal Embedded Swift target.
#
# This is the cheap, toolchain-only half of the ESP32 support: it catches
# Embedded Swift regressions (unsupported language features, OS dependencies
# leaking into shared code) without requiring ESP-IDF or QEMU. The full
# on-target build lives in Examples/embedded-esp32/smoke-test.sh.
set -euo pipefail

TARGET="${EMBEDDED_TARGET:-riscv32-none-none-eabi}"
SWIFTC="${SWIFTC:-swiftc}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/.build/embedded-check"
mkdir -p "$BUILD"

common=(
    -target "$TARGET"
    -enable-experimental-feature Embedded
    -wmo -parse-as-library -Osize
    -package-name wasmkit
    -I "$BUILD"
)

compile_module() {
    local name="$1"
    shift
    echo "Compiling $name for $TARGET"
    # shellcheck disable=SC2046
    "$SWIFTC" "${common[@]}" "$@" \
        $(find "$ROOT/Sources/$name" -name '*.swift') \
        -module-name "$name" \
        -emit-module -emit-module-path "$BUILD/$name.swiftmodule" \
        -c -o "$BUILD/$name.o"
}

compile_module WasmTypes
compile_module WasmParser
compile_module WasmKit -Xcc "-I$ROOT/Sources/_CWasmKit/include"
compile_module GDBRemoteProtocol

echo "OK: WasmKit compiles for $TARGET with Embedded Swift"
