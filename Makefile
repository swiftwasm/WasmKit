NAME := WAKit

MINT = swift run --package-path Vendor/Mint mint
SWIFTFORMAT = $(MINT) run swiftformat swiftformat
SOURCERY = $(MINT) run sourcery sourcery

MODULES = $(notdir $(wildcard Sources/*))
TEMPLATES = $(wildcard Templates/*.stencil)
GENERATED_DIRS = $(foreach MODULE, $(MODULES), Sources/$(MODULE)/Generated)

.PHONY: all
all: bootstrap project build

.PHONY: bootstrap
bootstrap:
	$(MINT) bootstrap

.PHONY: project
project: update generate $(NAME).xcodeproj

$(NAME).xcodeproj: Package.swift FORCE
	@swift package generate-xcodeproj \
    --enable-code-coverage

.PHONY: build
build:
	@swift build

.PHONY: test
test: linuxmain
	@swift test

.PHONY: format
format:
	$(SWIFTFORMAT) Sources Tests --exclude **/Generated

.PHONY: clean
clean:
	@swift package clean
	@$(RM) -r ./$(NAME).xcodeproj

.PHONY: update
update:
	@swift package update

.PHONY: generate
generate: $(GENERATED_DIRS)

Sources/%/Generated: FORCE
	$(SOURCERY) \
    --sources $(dir $@) \
    --templates $(TEMPLATES) \
    --output $@

linuxmain: FORCE
	@swift test --generate-linuxmain

GIT_STATUS = $(shell git status --porcelain)
ensure_clean:
	@[ -z "$(GIT_STATUS)" ] \
    && echo Working directory is clean \
	|| printf "Uncommitted changes: \n $(GIT_STATUS)\n"; exit 1;

FORCE:
