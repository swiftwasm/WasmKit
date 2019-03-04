MODULES = $(notdir $(wildcard Sources/*))
TEMPLATES = $(wildcard Templates/*.stencil)

.PHONY: all
all: project build

NAME := WAKit

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
	@swiftformat .

.PHONY: clean
clean:
	@swift package clean
	@$(RM) -r ./$(NAME).xcodeproj

GENERATED_SOURCES  = $(TEMPLATES:Templates/%.stencil=Sources/WAKit/Generated/%.swift)
.PHONY: generate
generate:
	@sourcery \
    --sources Sources/WAKit \
    --templates  $(TEMPLATES)\
    --output $(dir $(GENERATED_SOURCES))

FORCE:
