TARGET_SUFFIXES+=pdf
INTERMEDIATE_SUFFIXES+=dvi log aux d fls bbl blg nav out snm toc
SOURCES_d+=tex
SOURCES_pdf+=dvi $(SOURCES_dvi)
SOURCES_fls+=tex
SOURCES_dvi+=tex
SOURCES_log+=tex
SOURCES_aux+=tex
SOURCES_bbl+=tex
SOURCES_blg+=tex
SOURCES_nav+=tex
SOURCES_out+=tex
SOURCES_snm+=tex
SOURCES_toc+=tex

DVIPDFM_BIN=dvipdfmx
TEX_MAPFILE=cid-x.map

ifeq (,$(wildcard $(CURDIR)/$(TEX_MAPFILE)))
%.pdf:	%.dvi $(SYSDIR)
	$(DVIPDFM_BIN) -o $@ $(basename $<) 2>&1
else
%.pdf:	%.dvi $(TEX_MAPFILE) $(SYSDIR)
	$(DVIPDFM_BIN) -f $(TEX_MAPFILE) -o $@ $(basename $<) 2>&1
endif
	cd $(dir $<); qpdf --linearize $(notdir $@) linearized_$(notdir $@)
	rm -f $@
	cd $(dir $<); mv linearized_$(notdir $@) $(notdir $@)

TEX_BIN?=platex
TEX_FLAGS?=--shell-escape -interaction=batchmode -halt-on-error
PBIBTEX_BIN?=pbibtex

.SECONDARY:	%.dvi
ifeq (,$(wildcard $(CURDIR)/reference.bib))
%.dvi:	%.tex $(SYSDIR)
else
%.dvi:	%.tex reference.bib $(SYSDIR)
endif
	rm -f $@
	@echo $(TEX_BIN) $(TEX_FLAGS) $<
	@cd $(dir $<); if ! $(TEX_BIN) $(TEX_FLAGS) $(notdir $<) 1>/dev/null; then\
		cat $(notdir $(basename $<)).log | grep -e '^!' -A 10 1>&2 ;\
		false ;\
	fi
ifneq (,$(wildcard $(CURDIR)/reference.bib))
	cd $(dir $<); $(PBIBTEX_BIN) $(notdir $(basename $<))
	cd $(dir $<); $(TEX_BIN) $(TEX_FLAGS) $(notdir $<)  &>/dev/null
endif
	@cd $(dir $<); for i in `seq 1 3`; do\
		if grep -qF 'Rerun to get cross-references right.' $(notdir $(basename $<)).log; then\
			echo $(TEX_BIN) $(TEX_FLAGS) $< ;\
			$(TEX_BIN) $(TEX_FLAGS) $(notdir $<) &>/dev/null; \
		else exit 0;\
		fi;\
	done

.INTERMEDIATE:	%.fls
%.fls:	%.tex $(SYSDIR)
	$(TEX_BIN) -interaction=nonstopmode --shell-escape -recorder $<

.SECONDARY:	%.d
%.d:	%.tex
	$(SYSDIR)/bin/gend "$<" "dvi" > $@
	
-include $(foreach d,$(DIRS),$(patsubst %.tex,%.d,$(wildcard $(d)/*.tex)))
