.PHONY: test
test:
	swift test

.PHONY: project
project: Swasm.xcodeproj

SWIFT_SOURCES_LIST = $(shell find Sources -name '*.swift')
SWIFT_TESTS_LIST = $(shell find Tests -name '*.swift')
Swasm.xcodeproj: Package.swift $(SWIFT_SOURCES_LIST) $(SWIFT_TESTS_LIST)
	swift package generate-xcodeproj --enable-code-coverage
	scripts/add_lint_phase.rb

.PHONY: coverage
coverage: project
	xcodebuild -scheme Swasm-Package clean test -enableCodeCoverage YES

.PHONY: clean
clean:
	swift package clean
	rm -r Swasm.xcodeproj
