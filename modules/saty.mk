TARGET_SUFFIXES+=pdf d osaty
SOURCES_pdf+=saty
SOURCES_d+=saty


OPAM_ROOT=$(GLOBAL_TEMPDIR)/opam
SATYSFI_ROOT=$(GLOBAL_TEMPDIR)/satysfi-dist
SATYRISTES_PATH=./Satyristes
SATYSFI_OUTPUT_TEMPFILE=$(GLOBAL_TEMPDIR)/saty_output

define INSTALL_DEPS
	@[[ -e "$(OPAM_ROOT)" ]] || $(MAKE) $(OPAM_ROOT)
	@eval $$(opam env) && \
	[[ -e "$(SATYRISTES_PATH)" ]] && cat "$(SATYRISTES_PATH)" | sed -e 's/^\(.*\);;.*$$/\1/' | paste -s | sed -e 's/^.*(\s*dependencies\s*(\([^)]\+\)).*$$/\1/' | sed -e 's/\s/\n/g' | sed -e '/^\s*$$/d' | \
	xargs -I{} env OPAMROOT="$(OPAM_ROOT)" opam install -y "satysfi-{}" 2>&1
	@mkdir -p "$(SATYSFI_ROOT)"
	@eval $$(opam env) && \
	OPAMROOT="$(OPAM_ROOT)" satyrographos install --output "$(SATYSFI_ROOT)/dist" 2>&1
endef

$(SATYSFI_ROOT):	$(SATYRISTES_PATH) $(OPAM_ROOT)
	@echo "Installing dependencies..."
	@$(call INSTALL_DEPS)

$(OPAM_ROOT):	
	@[[ ! -e "$@" ]] && \
	echo "Install OPAM environment in $(OPAM_ROOT)..." && \
	mkdir -p "$@" && \
	OPAMROOT="$@" opam init -n && \
	OPAMROOT="$@" opam repository add --all-switches satyrographos-repo https://github.com/na4zagin3/satyrographos-repo.git && \
	OPAMROOT="$@" opam repository add --all-switches satysfi-external https://github.com/gfngfn/satysfi-external-repo.git 2>&1

%.pdf:	%.saty $(SATYSFI_ROOT)
	@eval $$(opam env) && \
	satysfi -C "$(SATYSFI_ROOT)" -o $@ $< | tee "$(SATYSFI_OUTPUT_TEMPFILE)" ; :
	@if grep -q -e '^! \[' "$(SATYSFI_OUTPUT_TEMPFILE)" ; then \
		cat "$(SATYSFI_OUTPUT_TEMPFILE)" | sed -ne '/^! \[/,$$p' 1>&2 ; \
		rm -f "$(SATYSFI_OUTPUT_TEMPFILE)"; \
		exit 1; \
	else \
		rm -f "$(SATYSFI_OUTPUT_TEMPFILE)"; \
	fi
	# SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos satysfi -- -C "$(SATYSFI_ROOT)" -o $@ $<
	
.SECONDARY:	%.d
%.d:	%.saty $(SATYSFI_ROOT)
	eval $$(opam env) && \
	SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps -r -p --depfile $@ --mode pdf -o "$(basename $@)" $< 2>&1 ; :
	
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
