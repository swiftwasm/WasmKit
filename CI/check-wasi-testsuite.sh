#!/bin/bash
#
# A CI script to run wasi-testsuite
#

set -eu -o pipefail
source "$(dirname $0)/Sources/os-check.sh"

install_tools() {
  if is_amazonlinux2; then
    amazon-linux-extras install -y python3.8
    ln -s /usr/bin/python3.8 /usr/bin/python3
  elif is_debian_family; then
    apt-get update
    apt-get install -y python3-pip
  else
    echo "Unknown OS"
    exit 1
  fi
}

install_tools

SOURCE_DIR="$(cd $(dirname $0)/.. && pwd)"
(
  cd $SOURCE_DIR && \
  ./Vendor/checkout-dependency wasi-testsuite && \
  python3 -m pip install -r ./Vendor/wasi-testsuite/test-runner/requirements.txt && \
  exec ./IntegrationTests/WASI/run-tests.sh
)
