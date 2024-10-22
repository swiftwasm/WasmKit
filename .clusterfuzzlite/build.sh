#!/bin/bash -eu

cd FuzzTesting
./fuzz.py --verbose build --sanitizer="$SANITIZER" FuzzTranslator

find .build/debug/ -maxdepth 1 -type f -name "Fuzz*" -executable -exec cp {} "$OUT/" \;

