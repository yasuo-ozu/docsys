
# Configuration
DOCSYS=.docsys
OPEN?=
FINAL_TARGETS=pdf
VIEWER_pdf=evince

-include $(CURDIR)/include.mk

.PHONY:	default
ifdef OPEN
default:	open
else
default:	toplevels
endif

# Make config
VPATH=$(SYSDIR)
SHELL=/bin/bash			# Shell to run Makefile rules
.DELETE_ON_ERROR: ;		# Delete .SECONDARY or .INTERMEDIATE files when error
$(MAKEFILE_LIST): ;		# Suppress regenerating Makefile
.SUFFIXES: ;			# Disable implicit rules

SYSDIR:=$(abspath $(if $(filter $(DOCSYS),$(notdir $(CURDIR))),.,$(DOCSYS)))
DIRS:=$(shell find . -type d | sed -e '/^\.\/\.[^\/]\+/d')
MAKEFILE=Makefile
uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))


# Load modules
TARGET_SUFFIXES=
INTERMEDIATE_SUFFIXES=
-include $(wildcard $(SYSDIR)/modules/*.mk)
TARGET_SUFFIXES2:=$(TARGET_SUFFIXES)
override TARGET_SUFFIXES:=$(call uniq,$(TARGET_SUFFIXES2))
INTERMEDIATE_SUFFIXES2:=$(INTERMEDIATE_SUFFIXES)
override INTERMEDIATE_SUFFIXES:=$(call uniq,$(INTERMEDIATE_SUFFIXES2))

TARGETS:=$(call uniq,$(foreach sf,$(TARGET_SUFFIXES),$(foreach suff,$(SOURCES_$(sf)),$(patsubst %.$(suff),%.$(sf),$(foreach dir,$(DIRS),$(wildcard $(dir)/*.$(suff)))))))
INTERMEDIATES:=$(call uniq,$(foreach sf,$(INTERMEDIATE_SUFFIXES),$(foreach suff,$(SOURCES_$(sf)),$(patsubst %.$(suff),%.$(sf),$(foreach dir,$(DIRS),$(wildcard $(dir)/*.$(suff)))))))
UNREFED_TARGETS:=$(foreach f,$(TARGETS),$(if $(wildcard $(basename $(f)).ref),,$(f)))
ROOT_UNREFED_TARGETS=$(foreach file,$(UNREFED_TARGETS),$(if $(patsubst ./,,$(dir $(file))),,$(file)))
TOPLEVEL_TARGETS2:=$(foreach f2,$(FINAL_TARGETS),$(filter %.$(f2),$(ROOT_UNREFED_TARGETS)))
TOPLEVEL_TARGETS:=$(foreach f,$(TOPLEVEL_TARGETS2),$(if $(REFS_$($(shell echo $(basename $(f)) | sed -e 's/\//_DS_/g' | sed -e 's/\./_DOT_/g'))),,$(f)))

ifdef OPEN
# Convert source suffix to target suffix
OPEN2:=$(OPEN)
override OPEN=$(firstword $(foreach sf,$(TARGET_SUFFIXES),$(foreach suff,$(SOURCES_$(sf)),$(patsubst %.$(suff),%.$(sf),$(filter %.$(suff),$(OPEN2))))) $(OPEN2))
OPENSFX=$(patsubst $(basename $(OPEN)).%,%,$(OPEN))

.PHONY:	open
open:	$(OPEN)
ifndef OPEN
	$(error Invalid OPEN variable)
else
	$(VIEWER_$(patsubst $(basename $(OPEN)).%,%,$(OPEN))) $^
endif
endif

.PHONY: info
.SILENT: info
info:
	+echo "SYSDIR = $(SYSDIR)"
	+echo "DIRS = $(DIRS)"
ifdef OPEN
	+echo "OPEN = $(OPEN)"
	+echo "VIEWER_$(OPENSFX) = $(VIEWER_$(OPENSFX))"
endif
	+echo "MAKEFILE = $(MAKEFILE)"
	+echo "TARGETS = $(TARGETS)"
	+echo "UNREFED_TARGETS = $(UNREFED_TARGETS)"
	+echo "TOPLEVEL_TARGETS = $(TOPLEVEL_TARGETS)"
	+echo "TARGET_SUFFIXES = $(TARGET_SUFFIXES)"
	+echo "INTERMEDIATE_SUFFIXES = $(INTERMEDIATE_SUFFIXES)"
	+echo -ne " $(foreach sf,$(call uniq,$(TARGET_SUFFIXES) $(INTERMEDIATE_SUFFIXES)),SOURCES_$(sf) = $(SOURCES_$(sf))\\n)"
	
.PHONY: toplevels
toplevels:	$(TOPLEVEL_TARGETS)
	
.PHONY:	all
all:	$(TARGETS)
	
# HELP

.SILENT:	help
.PHONY:	help
help:
	+echo "$(MAKE) install"
	+echo "$(MAKE) help"
	+echo "$(MAKE) info"
	+echo "$(MAKE) clean"
	+echo "$(MAKE) distclean"
	+echo "$(MAKE) open"
	+echo "$(MAKE) all"
	+echo "$(MAKE) toplevels"

.PHONY:	install
install:
ifneq ($(DOCSYS),$(notdir $(CURDIR)))
	$(error Please 'git clone' or 'git submodule add' this repository in '$(DOCSYS)' directory under your project.)
else
	ln -snf "$(DOCSYS)/$(MAKEFILE)" $(CURDIR)/../$(MAKEFILE)
ifeq (,$(wildcard $(CURDIR)/../.gitignore))
	diff $(CURDIR)/../.gitignore $(SYSDIR)/.gitignore | sed -ne '/^> /p' | cut -b 3- >> $(CURDIR)/../.gitignore
else
	cp $(SYSDIR)/.gitignore $(CURDIR)/../.gitignore
endif
endif

REMOVABLE_FILES:=$(INTERMEDIATES) $(TARGETS)

.PHONY:	clean
clean:
	rm -rf $(filter-out $(TOPLEVEL_TARGETS),$(REMOVABLE_FILES))
	@echo $(filter-out .,$(foreach d,$(DIRS),$(if $(wildcard $(d)/$(MAKEFILE)),$(d)))) | xargs -I{} $(MAKE) -C {} clean

.PHONY:	distclean
distclean:	clean
	rm -rf $(TOPLEVEL_TARGETS)

