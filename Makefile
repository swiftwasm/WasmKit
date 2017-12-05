.PHONY: all
all: project

# Parser

PARSER_SOURCES = ./Sources/Swasm/ANTLR
GRAMMER_FILE = $(PARSER_SOURCES)/WAST.g4
TOKENS_FILE = $(PARSER_SOURCES)/WAST.tokens

.PHONY: parser
parser: $(TOKENS_FILE)

ANTLR4 = java -Xmx500M -cp "/usr/local/lib/antlr4-4.7.1-SNAPSHOT-complete.jar:$$CLASSPATH" org.antlr.v4.Tool

$(TOKENS_FILE): $(GRAMMER_FILE)
	$(ANTLR4) -Dlanguage=Swift -visitor -no-listener $(GRAMMER_FILE)
	@touch $@

# Xcode Project

.PHONY: project
project: Swasm.xcodeproj

SWIFT_SOURCES_LIST = $(shell find Sources -name '*.swift')
SWIFT_TESTS_LIST = $(shell find Tests -name '*.swift')

Swasm.xcodeproj: parser Package.swift $(SWIFT_SOURCES_LIST) $(SWIFT_TESTS_LIST)
	swift package generate-xcodeproj --enable-code-coverage
	scripts/add_lint_phase.rb
	@touch $@

# Test

.PHONY: test
test:
	swift test

.PHONY: coverage
coverage: project
	xcodebuild -scheme Swasm-Package clean test -enableCodeCoverage YES

# Clean

.PHONY: clean
clean: clean_project clean_parser
	swift package clean

.PHONY: clean_project
clean_project:
	rm -r Swasm.xcodeproj

.PHONY: clean_parser
clean_parser:
	find $(PARSER_SOURCES) -type f -not -name '*.g4' -exec rm {} \;
