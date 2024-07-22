#!/bin/bash

# NOTE: SystemExtras is not included in the list of targets because it follows
#       swift-system style conventions, which is different from swift-format.
swift package --allow-writing-to-package-directory format-source-code \
  --target CLI --target WASI --target WasmKit --target WIT \
  --target WITTool --target WITOverlayGenerator \
  --target WITExtractor --target WITExtractorTests \
  --target WasmKitTests --target WITTests --target WASITests

swift run swift-format format --in-place Package.swift
