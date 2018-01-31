.PHONY: all
all: generate project

NAME := $(shell basename `pwd`)

.PHONY: project
project: $(NAME).xcodeproj

$(NAME).xcodeproj: Package.swift
	@swift package generate-xcodeproj --enable-code-coverage
	@./Scripts/run_swiftformat.rb $(NAME).xcodeproj
	@./Scripts/run_swiftlint.rb $(NAME).xcodeproj

SOURCERY := $(shell command -v sourcery 2> /dev/null)
TARGETS := $(filter-out Generated, $(shell ls Sources))
GENERATED_DIRS := $(foreach TARGET, $(TARGETS), $(addprefix Sources/, $(addsuffix /Generated, $(TARGET))))
SOURCE_DIRS := $(foreach TARGET, $(TARGETS), $(addprefix Sources/, $(TARGET)))

.PHONY: generate
generate: $(GENERATED_DIRS)

Sources/%/Generated: Sources/% FORCE
ifndef SOURCERY
	$(error "sourcery not installed; run `brew install sourcery`")
endif
	@mkdir -p $@
	@$(SOURCERY) --sources $< --templates Templates --output $@ --quiet

.PHONY: clean
clean:
	@swift package clean
	@$(RM) -r ./$(NAME).xcodeproj
	@$(RM) -r $(GENERATED_DIRS)

FORCE:
