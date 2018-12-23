.PHONY: all
all: project build

NAME := WAKit

.PHONY: project
project: $(NAME).xcodeproj

$(NAME).xcodeproj: Package.swift FORCE
	@swift package generate-xcodeproj --enable-code-coverage

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

FORCE:
