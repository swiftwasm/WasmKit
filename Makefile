NAME := WAKit

MODULES = $(notdir $(wildcard Sources/*))
TEMPLATES = $(wildcard Templates/*.stencil)

MINT = swift run --package-path Vendor/Mint mint
SWIFTFORMAT = $(MINT) run swiftformat swiftformat
SOURCERY = $(MINT) run sourcery sourcery

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
	$(SWIFTFORMAT) Sources Tests

.PHONY: clean
clean:
	@swift package clean
	@$(RM) -r ./$(NAME).xcodeproj

GENERATED_SOURCES  = $(TEMPLATES:Templates/%.stencil=Sources/WAKit/Generated/%.swift)
.PHONY: generate
generate:
	$(SOURCERY) \
    --sources Sources/WAKit \
    --templates  $(TEMPLATES)\
    --output $(dir $(GENERATED_SOURCES))

FORCE:
