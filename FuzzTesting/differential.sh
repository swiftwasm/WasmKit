#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_program="$dir/.build/debug/FuzzDifferential"
fail_dir="$dir/FailCases/FuzzDifferential"

i=0
start_time=$(date +%s)
while true; do
    i=$((i+1))
    if [ $((i % 100)) -eq 0 ]; then
        echo "#$i (iter/s: $(echo "scale=2; $i/($(date +%s)-$start_time)" | bc -l))"
    fi
    head -c 100 /dev/urandom | wasm-tools smith --ensure-termination --bulk-memory-enabled=true --saturating-float-to-int-enabled=true --sign-extension-ops-enabled=true --min-funcs=1 -o t.wasm --min-memories=1  --max-imports=0 --export-everything=true --max-memories=1 --max-memory32-bytes=65536 --memory-max-size-required=true
    if ! timeout 60 "$target_program" t.wasm; then
        cp t.wasm "$fail_dir/diff-$i.wasm"
        echo "Found crash in iteration $i"
    fi
done
