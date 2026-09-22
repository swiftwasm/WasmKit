#!/bin/bash
#
# A CI script to install wabt for testing WAT library
#

set -eu -o pipefail
source "$(dirname $0)/Sources/os-check.sh"

# Every job uses this release: the encoder tests compare with wast2json, whose
# defaults and flags change between releases.
WABT_VERSION=1.0.42

install_build_tools() {
  if which make curl cmake ninja python3 xz > /dev/null; then
    return
  fi
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install cmake ninja xz
  else
    apt update && apt install -y curl build-essential cmake ninja-build python3 xz-utils
  fi
}

install_tools() {
  if [[ "$(wat2wasm --version 2> /dev/null)" != "$WABT_VERSION" ]]; then
    install_build_tools
    local build_dir=$(mktemp -d /tmp/WasmKit-wabt.XXXXXX)
    mkdir -p $build_dir
    curl -L https://github.com/WebAssembly/wabt/releases/download/$WABT_VERSION/wabt-$WABT_VERSION.tar.xz | tar xJ --strip-components=1 -C $build_dir
    cmake -B $build_dir/build -GNinja -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local $build_dir
    cmake --build $build_dir/build
    # The Linux jobs run as root in a container. On the macOS runners only some
    # directories under /usr/local are writable, so check the prefix itself.
    if [ -w /usr/local ]; then
      cmake --install $build_dir/build
    else
      sudo cmake --install $build_dir/build
    fi
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
