NAME := WasmKit

.PHONY: docs
docs:
	swift package generate-documentation --target WasmKit

### Spectest (Core WebAssembly Specification Test Suite)

TESTSUITE_DIR = Vendor/testsuite

.PHONY: spectest
spectest:
	swift run --sanitize address Spectest $(TESTSUITE_DIR) $(TESTSUITE_DIR)/proposals/memory64


### WASI Test Suite

.PHONY: wasitest
wasitest:
	./IntegrationTests/WASI/run-tests.py

### Utilities

.PHONY: generate
generate:
	swift ./Utilities/generate_inst_visitor.swift
	swift ./Utilities/generate_inst_dispatch.swift
