#!/usr/bin/env bash

build_coverage_html() {
  llvm-cov show --format=html .build/debug/WasmKitPackageTests.xctest/Contents/MacOS/WasmKitPackageTests --instr-profile .build/debug/codecov/default.profdata -o "$1" --sources $(find Sources/ -type f)
}

mkdir -p ./.build/html
build_coverage_html ./.build/html/coverage
