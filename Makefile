NAME := WasmKit

.PHONY: docs
docs:
	swift package generate-documentation --target WasmKit

### Utilities

.PHONY: generate
generate:
	swift ./Utilities/generate_inst_visitor.swift
	swift ./Utilities/generate_inst_dispatch.swift
