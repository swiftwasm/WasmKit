# Fuzz Testing

This subdirectory contains some [libFuzzer](https://www.llvm.org/docs/LibFuzzer.html) fuzzing targets for WasmKit.

> [!WARNING]
> libFuzzer does not work with the latest Swift runtime library on macOS for some reason. Run the fuzzing targets on Linux for now.

## Requirements

- [Open Source Swift Toolchain](https://swift.org/install) - Xcode toolchain does not contain fuzzing supoort, so you need to install the open source toolchain.
- [wasm-tools](https://github.com/bytecodealliance/wasm-tools) - Required to generate random seed corpora

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

## Differential Testing

Generate a Wasm module with termination ensured by `wasm-tools smith` and check if WasmKit and another reference engine (e.g. Wasmtime) agree on the same result and the same memory state.

1. Build the differential testing tool:
    ```sh
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
