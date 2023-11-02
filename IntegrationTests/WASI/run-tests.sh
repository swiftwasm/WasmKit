#!/bin/bash

SOURCE_DIR="$(cd $(dirname $0)/../.. && pwd)"
DEFAULT_RUNTIME_EXE="$(swift build --show-bin-path)/wasmkit-cli"

# If custom TEST_RUNTIME_EXE is not set and DEFAULT_RUNTIME_EXE does not exist, build it
if [ -z "$TEST_RUNTIME_EXE" ] && [ ! -f "$DEFAULT_RUNTIME_EXE" ]; then
  swift build --product wasmkit-cli
fi

env TEST_RUNTIME_EXE="${TEST_RUNTIME_EXE:-$DEFAULT_RUNTIME_EXE}" \
  python3 ./Vendor/wasi-testsuite/test-runner/wasi_test_runner.py  \
    --test-suite ./Vendor/wasi-testsuite/tests/assemblyscript/testsuite/ Vendor/wasi-testsuite/tests/c/testsuite/ Vendor/wasi-testsuite/tests/rust/testsuite/ \
    --runtime-adapter IntegrationTests/WASI/adapter.py \
    --exclude-filter ./IntegrationTests/WASI/skip.json $@
