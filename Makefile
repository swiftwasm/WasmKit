NAME := WasmKit

.PHONY: docs
docs:
	swift package generate-documentation --target WasmKit

### WASI Test Suite

.PHONY: wasitest
wasitest:
	./IntegrationTests/WASI/run-tests.py

### Utilities

.PHONY: generate
generate:
	swift ./Utilities/generate_inst_visitor.swift
	swift ./Utilities/generate_inst_dispatch.swift
