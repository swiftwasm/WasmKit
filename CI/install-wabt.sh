#!/bin/bash
#
# A CI script to run "make spectest" with wabt installed.
#

set -eu -o pipefail
source "$(dirname $0)/Sources/os-check.sh"

install_tools() {
  if ! which make curl cmake ninja python3 xz > /dev/null; then
    apt update && apt install -y curl build-essential cmake ninja-build python3 xz-utils
  fi

  if ! which wat2wasm > /dev/null; then
    local build_dir=$(mktemp -d /tmp/WasmKit-wabt.XXXXXX)
    mkdir -p $build_dir
    curl -L https://github.com/WebAssembly/wabt/releases/download/1.0.33/wabt-1.0.33.tar.xz | tar xJ --strip-components=1 -C $build_dir
    cmake -B $build_dir/build -GNinja -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local $build_dir
    cmake --build $build_dir/build --target install
  fi

  echo "Use wat2wasm $(wat2wasm --version): $(which wat2wasm)"
  echo "Use wasm2wat $(wasm2wat --version): $(which wasm2wat)"
}

# Currently wabt is unavailable in amazonlinux2
if is_amazonlinux2; then
  echo "Skip wabt installation on amazonlinux2"
  exit 0
fi

set -e

install_tools
