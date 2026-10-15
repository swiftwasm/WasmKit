# Fuzz Testing

This subdirectory contains some [libFuzzer](https://www.llvm.org/docs/LibFuzzer.html) fuzzing targets for WasmKit.

> [!WARNING]
> libFuzzer does not work with the latest Swift runtime library on macOS for some reason. Run the fuzzing targets on Linux for now.

## Requirements

- [Open Source Swift Toolchain](https://swift.org/install) - Xcode toolchain does not contain fuzzing support, so you need to install the open source toolchain.
- [wasm-tools](https://github.com/bytecodealliance/wasm-tools) - Required to generate random seed corpora
- The `wasm-c-api` vendored dependency - `FuzzDifferential` links against it, so check it out first:
    ```sh
    ../Vendor/checkout-dependency wasm-c-api
    ```

## libFuzzer-based Fuzzing Targets

### Running the Fuzzing Targets

1. Generate seed corpora for the fuzzing targets:
    ```sh
    ./fuzz.py seed
    ```
2. Run the fuzzing targets, where `<target>` is one of the fuzzing targets available in `./Sources` directory:
    ```sh
    ./fuzz.py run <target>
    ```
3. Once the fuzzer finds a crash, it will generate a test case in the `FailCases/<target>` directory.


### Reproducing Crashes

To reproduce a crash found by the fuzzer

1. Build the fuzzer executable:
    ```sh
    ./fuzz.py build <target>
    ```
2. Run the fuzzer executable with the test case:
    ```sh
    ./.build/debug/<target> <testcase>
    ```

## Resumable Call Fuzzing

`FuzzResumable` generates modules whose control flow crosses every place a `ResumableCall` can
suspend, then runs each export twice: once with a plain call, and once as a resumable call that is
suspended by tiny fuel slices and epoch deadlines and resumed until it finishes. Both runs must
agree on results, traps, memory, globals, tables and the fuel each call consumed. It needs no seed
corpus:

```sh
./fuzz.py build FuzzResumable --release
mkdir -p corpus && ./.build/release/FuzzResumable corpus -fork=8 -timeout=20
```

`FuzzResumableDriver` runs the same oracle without libFuzzer, so it also works on macOS. With
`--race`, another thread ticks the epoch while the guests run; build it with
`-Xswiftc -sanitize=thread` to check that for data races.

```sh
swift build -c release --product FuzzResumableDriver
./.build/release/FuzzResumableDriver --count 100000
./.build/release/FuzzResumableDriver --race
./.build/release/FuzzResumableDriver --replay FailCases/FuzzResumableDriver/finding-<seed>-<n> --trace
```

## Differential Testing

Generate a Wasm module with termination ensured by `wasm-tools smith` and check if WasmKit and another reference engine (e.g. Wasmtime) agree on the same result and the same memory state.

1. Build the differential testing tool:
    ```sh
    # Check out the `wasm.h` header that the `WasmCAPI` target wraps
    ../Vendor/checkout-dependency wasm-c-api
    # Download and extract the Wasmtime C API library
    mkdir -p .build/libwasmtime && \
      curl -L https://github.com/bytecodealliance/wasmtime/releases/download/v23.0.2/wasmtime-v23.0.2-x86_64-linux-c-api.tar.xz -o - | \
      tar xJ --strip-component=1 -C ./.build/libwasmtime
    # Build the differential testing tool with libwasmtime
    swift build -Xlinker -L./.build/libwasmtime/lib -Xlinker -l:libwasmtime.a --product FuzzDifferential
    ```
    You can use any other reference engine implementing the [Wasm C API](https://github.com/WebAssembly/wasm-c-api) by replacing the `libwasmtime` library.

2. Run the differential testing tool:
    ```sh
    ./differential.py
    ```
