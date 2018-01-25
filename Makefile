.PHONY: all
all: project

NAME := $(shell basename `pwd`)

.PHONY: project
project: $(NAME).xcodeproj

$(NAME).xcodeproj:
	@swift package generate-xcodeproj
	@./Scripts/run_swiftformat.rb $(NAME).xcodeproj
	@./Scripts/run_swiftlint.rb $(NAME).xcodeproj

.PHONY: clean
clean:
	swift package clean
	rm -rf $(NAME).xcodeproj
