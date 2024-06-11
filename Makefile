NAME := WasmKit

MODULES = $(notdir $(wildcard Sources/*))

.PHONY: all
all: build

.PHONY: build
build:
	@swift build

.PHONY: test
test:
	@swift test

.PHONY: docs
docs:
	swift package generate-documentation --target WasmKit

### Spectest (Core WebAssembly Specification Test Suite)

TESTSUITE_DIR = Vendor/testsuite
SPECTEST_ROOT = ./spectest
WAST_FILES = $(wildcard $(TESTSUITE_DIR)/*.wast) $(wildcard $(TESTSUITE_DIR)/proposals/memory64/*.wast)
JSON_FILES = $(WAST_FILES:$(TESTSUITE_DIR)/%.wast=$(SPECTEST_ROOT)/%.json)

.PHONY: spec
spec: $(JSON_FILES) $(SPECTEST_ROOT)/host.wasm

$(SPECTEST_ROOT)/host.wasm: ./Examples/wasm/host.wat
	wat2wasm ./Examples/wasm/host.wat -o $(SPECTEST_ROOT)/host.wasm

$(TESTSUITE_DIR)/%.wast: $(TESTSUITE_DIR)
$(SPECTEST_ROOT)/%.json: $(TESTSUITE_DIR)/%.wast
	@mkdir -p $(@D)
	wast2json $^ -o $@

.PHONY: spectest
spectest: spec
	swift run Spectest $(SPECTEST_ROOT)


### WASI Test Suite

.PHONY: wasitest
wasitest:
	./IntegrationTests/WASI/run-tests.sh

### Utilities

.PHONY: generate
generate:
	swift ./Utilities/generate_inst_visitor.swift
	swift ./Utilities/generate_inst_dispatch.swift

GIT_STATUS = $(shell git status --porcelain)
ensure_clean:
	@[ -z "$(GIT_STATUS)" ] \
    && echo Working directory is clean \
	|| (printf "Uncommitted changes: \n $(GIT_STATUS)\n" && exit 1)

FORCE:
