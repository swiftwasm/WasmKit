.PHONY: test
test:
	swift test

.PHONY: project
project: Swasm.xcodeproj

SWIFT_SRC_LIST = $(shell find . -name '*.swift')
Swasm.xcodeproj: $(SWIFT_SRC_LIST)
	swift package generate-xcodeproj --enable-code-coverage
	scripts/add_lint_phase.rb

.PHONY: coverage
coverage: project
	xcodebuild -scheme Swasm-Package clean test -enableCodeCoverage YES

.PHONY: clean
clean:
	swift package clean
	rm -r Swasm.xcodeproj
