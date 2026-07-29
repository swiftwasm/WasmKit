#!/bin/bash
# Smoke test for WasmKit on ESP32 (Embedded Swift + ESP-IDF).
#
# Builds this example for ESP32-C6 and, with --qemu, also builds it for
# ESP32-C3 and boots it in Espressif's QEMU, checking that the guest wasm
# module actually executes ("2 + 3 = 5" on the serial console; QEMU has no
# ESP32-C6 machine, hence the C3 run).
#
# Requirements:
#   - ESP-IDF v5.5+ installed and its tools provisioned (`install.sh esp32c6`).
#     Discovered via $IDF_PATH, or ~/esp/esp-idf*.
#   - A Swift toolchain with the Embedded riscv32-none-none-eabi stdlib
#     (development snapshots from swift.org). Discovered via $SWIFT_TOOLCHAIN
#     (path to a .xctoolchain), or the newest match under
#     {~,}/Library/Developer/Toolchains.
#   - For --qemu: qemu-system-riscv32 from Espressif
#     (`idf_tools.py install qemu-riscv32`) or on PATH.
#
# Usage:
#   ./smoke-test.sh          # build for esp32c6
#   ./smoke-test.sh --qemu   # additionally run the esp32c3 build in QEMU

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
run_qemu=false
[ "${1:-}" = "--qemu" ] && run_qemu=true

log() { echo "==> $*"; }
die() { echo "error: $*" >&2; exit 1; }

# --- Locate ESP-IDF -----------------------------------------------------------
if [ -z "${IDF_PATH:-}" ]; then
    for d in "$HOME"/esp/esp-idf*; do
        [ -f "$d/export.sh" ] && IDF_PATH="$d"
    done
fi
[ -n "${IDF_PATH:-}" ] && [ -f "$IDF_PATH/export.sh" ] || die "ESP-IDF not found; set IDF_PATH"
log "Using ESP-IDF: $IDF_PATH"

# --- Locate an Embedded Swift toolchain with riscv32 stdlib -------------------
embedded_stdlib="usr/lib/swift/embedded/riscv32-none-none-eabi"
if [ -z "${SWIFT_TOOLCHAIN:-}" ]; then
    best_version=""
    for tc in "$HOME"/Library/Developer/Toolchains/swift-*.xctoolchain \
              /Library/Developer/Toolchains/swift-*.xctoolchain; do
        [ -d "$tc/$embedded_stdlib" ] || continue
        [ "$(basename "$tc")" = "swift-latest.xctoolchain" ] && continue
        # Pick the newest compiler; Embedded Swift restrictions relax over time
        # (e.g. untyped throws needs a 6.5+ snapshot).
        version="$("$tc/usr/bin/swiftc" --version 2>/dev/null | head -1 | sed -n 's/.*Swift version \([0-9.]*\).*/\1/p')"
        if [ -z "$best_version" ] || [ "$(printf '%s\n%s\n' "$best_version" "$version" | sort -V | tail -1)" = "$version" ]; then
            best_version="$version"
            SWIFT_TOOLCHAIN="$tc"
        fi
    done
fi
[ -n "${SWIFT_TOOLCHAIN:-}" ] && [ -d "$SWIFT_TOOLCHAIN/$embedded_stdlib" ] \
    || die "no Swift toolchain with the Embedded riscv32-none-none-eabi stdlib found; set SWIFT_TOOLCHAIN"
log "Using Swift toolchain: $SWIFT_TOOLCHAIN"

# --- ESP-IDF linker-script patch for Embedded Swift's GOT ---------------------
# Embedded Swift emits a GOT-indirect reference to the Unicode data table
# symbols; stock ESP-IDF discards .got/.got.plt and the link fails with
# "discarded output section: `.got.plt'". Keep the (read-only) GOT in flash.
patch_ld_template() {
    local template="$IDF_PATH/components/esp_system/ld/$1/sections.ld.in"
    [ -f "$template" ] || return 0
    if ! grep -q 'Embedded Swift may emit GOT-indirect references' "$template"; then
        log "Patching $template to keep .got sections"
        python3 - "$template" <<'EOF'
import sys
path = sys.argv[1]
s = open(path).read()
anchor = "    _flash_rodata_start = ABSOLUTE(.);\n"
insert = anchor + """
    /* Embedded Swift may emit GOT-indirect references (e.g. to Unicode data
     * table symbols). The GOT is read-only here; keep it instead of relying
     * on the generic discard below. */
    *(.got)
    *(.got.plt)
"""
assert anchor in s, f"anchor not found in {path}"
open(path, "w").write(s.replace(anchor, insert, 1))
EOF
    fi
}
patch_ld_template esp32c6
patch_ld_template esp32c3

# --- Environment ---------------------------------------------------------------
export WASMKIT_ROOT="${WASMKIT_ROOT:-$(cd "$here/../.." && pwd)}"
log "Using WasmKit: $WASMKIT_ROOT"
# shellcheck disable=SC1091
source "$IDF_PATH/export.sh" > /dev/null
export PATH="$SWIFT_TOOLCHAIN/usr/bin:$PATH"
export SWIFT_EMBEDDED_LIB_DIR="$SWIFT_TOOLCHAIN/$embedded_stdlib"

cd "$here"

# --- Build for ESP32-C6 ---------------------------------------------------------
log "Building for esp32c6"
idf.py -B build.c6 -D SDKCONFIG=sdkconfig.c6 set-target esp32c6 > build-c6.log 2>&1 \
    || { tail -30 build-c6.log; die "esp32c6 set-target failed (see build-c6.log)"; }
idf.py -B build.c6 -D SDKCONFIG=sdkconfig.c6 build >> build-c6.log 2>&1 \
    || { tail -30 build-c6.log; die "esp32c6 build failed (see build-c6.log)"; }
log "esp32c6 build OK: $(ls -lh build.c6/*.bin | awk '{print $9, "("$5")"}')"

$run_qemu || { log "Done. Pass --qemu to also run the esp32c3 build in QEMU."; exit 0; }

# --- Build for ESP32-C3 and run in QEMU ------------------------------------------
qemu_bin="$(command -v qemu-system-riscv32 || true)"
if [ -z "$qemu_bin" ]; then
    qemu_bin="$(find "${IDF_TOOLS_PATH:-$HOME/.espressif}/tools/qemu-riscv32" -name qemu-system-riscv32 -type f 2>/dev/null | head -1)"
fi
[ -n "$qemu_bin" ] || die "qemu-system-riscv32 not found; run 'idf_tools.py install qemu-riscv32'"
log "Using QEMU: $qemu_bin"

log "Building for esp32c3 (QEMU)"
idf.py -B build.c3 -D SDKCONFIG=sdkconfig.c3 set-target esp32c3 > build-c3.log 2>&1 \
    || { tail -30 build-c3.log; die "esp32c3 set-target failed (see build-c3.log)"; }
idf.py -B build.c3 -D SDKCONFIG=sdkconfig.c3 build >> build-c3.log 2>&1 \
    || { tail -30 build-c3.log; die "esp32c3 build failed (see build-c3.log)"; }

log "Merging flash image"
(cd build.c3 && esptool.py --chip esp32c3 merge_bin -o flash.bin --fill-flash-size 4MB @flash_args > /dev/null)

log "Booting in QEMU (up to 60s)"
qemu_out="$here/build.c3/qemu-out.txt"
"$qemu_bin" -M esp32c3 -drive file="$here/build.c3/flash.bin,if=mtd,format=raw" \
    -nographic -serial file:"$qemu_out" -monitor null > /dev/null 2>&1 &
qemu_pid=$!
trap 'kill $qemu_pid 2>/dev/null || true' EXIT

result=1
for _ in $(seq 1 60); do
    if grep -q 'host error 42' "$qemu_out" 2>/dev/null; then result=0; break; fi
    if grep -qE 'Guru Meditation|abort\(\) was called' "$qemu_out" 2>/dev/null; then break; fi
    kill -0 $qemu_pid 2>/dev/null || break
    sleep 1
done
kill $qemu_pid 2>/dev/null || true

echo "--- serial output ---"
sed -n '/Calling app_main/,$p' "$qemu_out" | head -20
echo "----------------------"
if [ $result -eq 0 ]; then
    grep -q '2 + 3 = 5' "$qemu_out" && grep -q '7 \* 3 = 21' "$qemu_out" \
        || die "smoke test FAILED: incomplete output (see $qemu_out)"
    log "SMOKE TEST PASSED: wasm + host functions executed on emulated ESP32"
else
    die "smoke test FAILED: expected '2 + 3 = 5' in serial output (see $qemu_out)"
fi
