# WasmKit on ESP32 (Embedded Swift + ESP-IDF)

Runs a WebAssembly module on an ESP32-C6 (RISC-V). The project compiles the
WasmKit interpreter with Embedded Swift under ESP-IDF. The demo calls a wasm
function, lets the guest call back into a Swift host function, and round-trips
a host-thrown error with its identity.

Each SwiftPM module becomes an ESP-IDF component (`wasmtypes` → `wasmparser` →
`wasmkit`, plus the C shims in `cwasmkit`), compiled through
[`espressif/idf_swift`](https://components.espressif.com/components/espressif/idf_swift).
`main/Main.swift` parses a bundled `add.wasm`, instantiates it, and calls the
exported `add` function.

## Requirements

- ESP-IDF v5.5+ with tools installed for `esp32c6` (`./install.sh esp32c6`)
- A Swift development snapshot toolchain that ships the Embedded
  `riscv32-none-none-eabi` standard library
- For the QEMU test: Espressif's QEMU (`idf_tools.py install qemu-riscv32`)

## Building and testing

```sh
./smoke-test.sh          # build for esp32c6
./smoke-test.sh --qemu   # also boot an esp32c3 build in QEMU and check output
```

The script locates ESP-IDF (`$IDF_PATH` or `~/esp/esp-idf*`) and a Swift
toolchain (`$SWIFT_TOOLCHAIN` or the newest snapshot in
`~/Library/Developer/Toolchains`). It also patches the local ESP-IDF
linker-script template once to keep `.got`/`.got.plt` in flash: Embedded Swift
emits a GOT-indirect reference to the Unicode data table symbols, and stock
ESP-IDF discards those sections.

To flash real hardware after a build:

```sh
idf.py -B build.c6 -D SDKCONFIG=sdkconfig.c6 -p /dev/cu.usbmodem* flash monitor
```

## Notes

- The default 512 KiB WasmKit value stack does not fit in on-chip SRAM, so
  `Main.swift` sets `EngineConfiguration.stackSize` to 64 KiB.
- Each component is compiled with `-Xfrontend -function-sections`. `swiftc`
  otherwise emits a single `.text` section per module, and ESP-IDF's
  `--gc-sections` can only strip whole sections -- so without the flag nothing
  the firmware does not call can be dropped. Objects grow by roughly a quarter
  before linking; the linker reclaims it.
- WASI is available on this target. Link only the parts you use:

  ```swift
  var imports = Imports()
  try bridge.link(to: &imports, store: store, capabilities: [.stdio, .clocks, .random])
  ```

  Unnamed capabilities stay unreferenced and are stripped. Functions the guest
  imports but no linked capability provides are registered as `ENOSYS` stubs,
  so the module still instantiates -- pass `stubUnlinked: false` to opt out.
- The QEMU run uses the ESP32-C3 machine because Espressif's QEMU has no
  ESP32-C6 model; both chips are RV32IMC-class cores running the same code
  paths.
