#!/bin/bash

set -euxo pipefail

echo "===== Checking disk space before cleanup ====="

df -h

echo "===== Cleaning up unused files to free disk space ====="

sudo rm -rf \
  /usr/share/dotnet \
  /opt/ghc \
  /opt/hostedtoolcache/CodeQL

docker image prune --all --force
docker builder prune -a

echo "===== Checking disk space after cleanup ====="
df -h
