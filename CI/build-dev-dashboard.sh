#!/usr/bin/env bash

set -euo pipefail

show_test_executable_path() {
  local base_path=".build/debug/WasmKitPackageTests.xctest"
  if [ -f "$base_path" ]; then
    echo "$base_path"
  else
    echo "$base_path/Contents/MacOS/WasmKitPackageTests"
  fi
}

build_coverage_html() {
  llvm-cov show --format=html "$(show_test_executable_path)" --instr-profile .build/debug/codecov/default.profdata -o "$1" --sources $(find Sources -type f)
}

mkdir -p ./.build/html
build_coverage_html ./.build/html/coverage

echo "Coverage report has been generated in ./.build/html/coverage"
