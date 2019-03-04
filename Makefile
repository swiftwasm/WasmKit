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
project: generate $(NAME).xcodeproj

$(NAME).xcodeproj: Package.swift FORCE
	@swift package generate-xcodeproj \
    --enable-code-coverage

.PHONY: build
build:
	@swift build

.PHONY: test
test:
	@swift test

.PHONY: format
format:
	$(SWIFTFORMAT) Sources Tests --exclude **/Generated

.PHONY: clean
clean:
	@swift package clean
	@$(RM) -r ./$(NAME).xcodeproj

.PHONY: generate
generate: $(GENERATED_DIRS)

Sources/%/Generated: FORCE
	$(SOURCERY) \
    --sources $(dir $@) \
    --templates $(TEMPLATES) \
    --output $@

FORCE:
