TARGET_SUFFIXES+=pdf d osaty
SOURCES_pdf+=saty
SOURCES_d+=saty


OPAM_ROOT=$(GLOBAL_TEMPDIR)/opam
SATYSFI_ROOT=$(GLOBAL_TEMPDIR)/satysfi-dist
SATYRISTES_PATH=./Satyristes

define INSTALL_DEPS
	[[ -e "$(OPAM_ROOT)" ]] || $(MAKE) $(OPAM_ROOT)
	eval $$(opam env) && \
	[[ -e "$(SATYRISTES_PATH)" ]] && cat "$(SATYRISTES_PATH)" | sed -e 's/^\(.*\);;.*$$/\1/' | paste -s | sed -e 's/^.*(\s*dependencies\s*(\([^)]\+\)).*$$/\1/' | sed -e 's/\s/\n/g' | sed -e '/^\s*$$/d' | \
	xargs -I{} env OPAMROOT="$(OPAM_ROOT)" opam install -y "satysfi-{}"
	eval $$(opam env) && \
	mkdir -p "$(SATYSFI_ROOT)"
	OPAMROOT="$(OPAM_ROOT)" satyrographos install --output "$(SATYSFI_ROOT)/dist"
endef

$(OPAM_ROOT):
	mkdir -p "$@"
	OPAMROOT="$@" opam init -n
	OPAMROOT="$@" opam repository add --all-switches satyrographos-repo https://github.com/na4zagin3/satyrographos-repo.git
	OPAMROOT="$@" opam repository add --all-switches satysfi-external https://github.com/gfngfn/satysfi-external-repo.git

%.pdf:	%.saty
	$(call INSTALL_DEPS)
	eval $$(opam env) && \
	SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos satysfi -- -C "$(SATYSFI_ROOT)" -o $@ $<
	
.SECONDARY:	%.d
%.d:	%.saty
	$(call INSTALL_DEPS)
	eval $$(opam env) && \
	SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps -r -p --depfile $@ --mode pdf -o "$(basename $@)" $<
	
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
