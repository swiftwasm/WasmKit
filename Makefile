.PHONY: all
all: project

NAME := $(shell basename `pwd`)

.PHONY: project
project: $(NAME).xcodeproj

$(NAME).xcodeproj: Package.swift
	@swift package generate-xcodeproj --enable-code-coverage
	@./Scripts/run_swiftformat.rb $(NAME).xcodeproj
	@./Scripts/run_swiftlint.rb $(NAME).xcodeproj

.PHONY: clean
clean:
	swift package clean
	rm -rf $(NAME).xcodeproj
