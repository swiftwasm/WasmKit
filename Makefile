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

WAST_ROOT = Vendor/testsuite
SPECTEST_ROOT = ./spectest
WAST_FILES = $(wildcard $(WAST_ROOT)/*.wast) $(wildcard $(WAST_ROOT)/proposals/memory64/*.wast)
JSON_FILES = $(WAST_FILES:$(WAST_ROOT)/%.wast=$(SPECTEST_ROOT)/%.json)

.PHONY: spec
spec: $(JSON_FILES) $(SPECTEST_ROOT)/host.wasm

$(SPECTEST_ROOT)/host.wasm: ./Examples/wasm/host.wat
	wat2wasm ./Examples/wasm/host.wat -o $(SPECTEST_ROOT)/host.wasm

$(SPECTEST_ROOT)/%.json: $(WAST_ROOT)/%.wast
	@mkdir -p $(@D)
	wast2json $^ -o $@

.PHONY: spectest
spectest: spec
	swift run Spectest $(SPECTEST_ROOT)

.PHONY: clean
clean:
	@swift package clean

.PHONY: update
update:
	@swift package update

.PHONY: generate
generate: $(GENERATED_DIRS)

GIT_STATUS = $(shell git status --porcelain)
ensure_clean:
	@[ -z "$(GIT_STATUS)" ] \
    && echo Working directory is clean \
	|| (printf "Uncommitted changes: \n $(GIT_STATUS)\n" && exit 1)

FORCE:
