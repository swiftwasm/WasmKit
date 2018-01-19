.PHONY: test
test:
	swift test

.PHONY: project
project:
	swift package generate-xcodeproj --enable-code-coverage
	scripts/run_swiftformat.rb
	scripts/run_swiftlint.rb

.PHONY: coverage
coverage: project
	xcodebuild -scheme Swasm-Package clean test -enableCodeCoverage YES

.PHONY: clean
clean:
	swift package clean
