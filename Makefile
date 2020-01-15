
# Configuration
DOCSYS=.docsys
OPEN?=
FINAL_TARGETS=pdf
VIEWER_pdf=evince FILE  &>/dev/null &

-include $(CURDIR)/include.mk

.PHONY:	default
ifdef OPEN
default:	open
else
default:	toplevels
endif

# Make config
MAKEFILE=$(notdir $(firstword $(MAKEFILE_LIST)))
VPATH=$(SYSDIR)
SHELL=/bin/bash			# Shell to run Makefile rules
.DELETE_ON_ERROR: ;		# Delete .SECONDARY or .INTERMEDIATE files when error
$(MAKEFILE): ;			# Suppress regenerating Makefile
.SUFFIXES: ;			# Disable implicit rules

SYSDIR:=$(abspath $(if $(wildcard $(DOCSYS)),$(DOCSYS),$(if $(shell [ -h $(firstword $(MAKEFILE_LIST)) ] && echo t),$(dir $(dir $(firstword $(MAKEFILE_LIST)))/$(shell readlink $(firstword $(MAKEFILE)))),$(dir $(firstword $(MAKEFILE_LIST))))))
DIRS_BASE:=$(shell find . -type d | sed -e '/^\.\/\.[^\/]\+/d')
DIR_WITH_MAKEFILE:=$(foreach d,$(wildcard ./*),$(if $(wildcard $(d)/$(MAKEFILE)),$(d)))
DIRS:=$(foreach d,$(DIRS_BASE),$(filter-out $(foreach e,$(DIR_WITH_MAKEFILE),$(e) $(e)/%),$(d)))
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
	$(subst FILE,$^,$(VIEWER_$(patsubst $(basename $(OPEN)).%,%,$(OPEN))))
endif
endif

.PHONY: info
.SILENT: info
info:
	+echo "SYSDIR = $(SYSDIR)"
	+echo "DIRS = $(DIRS)"
	+echo "DIR_WITH_MAKEFILE = $(DIR_WITH_MAKEFILE)"
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

# Use Makefile in subdirs
$(addsuffix /%,$(DIR_WITH_MAKEFILE)):
	@$(MAKE) -C $(firstword $(subst /, ,$@)) $(shell echo $@ | sed -e 's/^[^\/]\+\///')
$(addsuffix /clean,$(DIR_WITH_MAKEFILE)):
	@$(MAKE) -C $(firstword $(subst /, ,$@)) -n clean && $(MAKE) -C $(firstword $(subst /, ,$@)) clean
$(addsuffix /distclean,$(DIR_WITH_MAKEFILE)):
	@$(MAKE) -C $(firstword $(subst /, ,$@)) -n distclean && $(MAKE) -C $(firstword $(subst /, ,$@)) distclean

# Script rules
SCRIPT_SUFFIXES=py sh run
SCRIPT_COMMAND_py=PYTHONPATH=$(SYSDIR)/lib python 
SCRIPT_COMMAND_sh=bash
SCRIPT_COMMAND_run=env
SCRIPTS=$(foreach d,$(DIRS),$(wildcard $(addprefix $(d)/*.,$(SCRIPT_SUFFIXES))))

$(addsuffix _generated.d,$(SCRIPTS)):	$(foreach s,$(SCRIPTS),$(if $(filter $(basename $(s))%,$@),$(s)))
	@echo '$(basename $(subst _generated.d,,$@))%:	$(subst _generated.d,,$@)' > "$@"
	@echo '	$(SCRIPT_COMMAND_$(patsubst .%,%,$(suffix $(subst _generated.d,,$@)))) $$< $$@ | tee $$@.out' >> "$@"
	@echo '	@[ ! -f "$$@" ] && mv "$$@.out" "$$@"' >> "$@"
	@echo '	@rm -rf $$@.out' >> "$@"

-include $(addsuffix _generated.d,$(SCRIPTS))
REMOVABLE_FILES:=$(REMOVABLE_FILES) $(addsuffix _generated.d,$(SCRIPTS))

# clean

.PHONY:	$(addsuffix /clean,$(DIR_WITH_MAKEFILE))
.PHONY:	clean
clean:	$(addsuffix /clean,$(DIR_WITH_MAKEFILE))
	rm -rf $(filter-out $(TOPLEVEL_TARGETS),$(REMOVABLE_FILES))
	@echo $(filter-out .,$(foreach d,$(DIRS),$(if $(wildcard $(d)/$(MAKEFILE)),$(d)))) | xargs -I{} $(MAKE) -C {} clean
	@echo info: To delete all generated files, run $(MAKE) distclean

.PHONY:	$(addsuffix /distclean,$(DIR_WITH_MAKEFILE))
.PHONY:	distclean
distclean:	clean $(addsuffix /distclean,$(DIR_WITH_MAKEFILE))
	rm -rf $(TOPLEVEL_TARGETS)
