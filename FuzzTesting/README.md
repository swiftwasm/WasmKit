# Fuzz Testing

This subdirectory contains some [libFuzzer](https://www.llvm.org/docs/LibFuzzer.html) fuzzing targets for WasmKit.

> [!WARNING]
> libFuzzer does not work with the latest Swift runtime library on macOS for some reason. Run the fuzzing targets on Linux for now.

## Requirements

- [Open Source Swift Toolchain](https://swift.org/install) - Xcode toolchain does not contain fuzzing supoort, so you need to install the open source toolchain.
- [wasm-tools](https://github.com/bytecodealliance/wasm-tools) - Required to generate random seed corpora


## Running the Fuzzing Targets

1. Generate seed corpora for the fuzzing targets:
    ```sh
    ./fuzz.py seed
    ```
2. Run the fuzzing targets, where `<target>` is one of the fuzzing targets available in `./Sources` directory:
    ```sh
    ./fuzz.py run <target>
    ```
3. Once the fuzzer finds a crash, it will generate a test case in the `FailCases/<target>` directory.


## Reproducing Crashes

To reproduce a crash found by the fuzzer

1. Build the fuzzer executable:
    ```sh
    ./fuzz.py build <target>
    ```
2. Run the fuzzer executable with the test case:
    ```sh
    ./.build/debug/<target> <testcase>
    ```
