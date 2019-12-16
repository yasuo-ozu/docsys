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

%.pdf:	%.dvi $(SYSDIR)
	cd $(dir $<); dvipdfmx $(notdir $(basename $<)) 2>&1
	cd $(dir $<); qpdf --linearize $(notdir $@) linearized_$(notdir $@)
	rm -f $@
	cd $(dir $<); mv linearized_$(notdir $@) $(notdir $@)
	
ifeq (,$(wildcard $(dir $<)/reference.bib))
reference.bib:
	touch $@
endif

TEX_BIN?=platex
TEX_FLAGS?=--shell-escape -interaction=batchmode -halt-on-error
PBIBTEX_BIN?=pbibtex

.SECONDARY:	%.dvi
%.dvi:	%.tex reference.bib $(SYSDIR)
	@echo $(TEX_BIN) $(TEX_FLAGS) $<
	@cd $(dir $<); $(TEX_BIN) $(TEX_FLAGS) $(notdir $<) 1>/dev/null; if [ ! -f $(notdir $(basename $<)).dvi ]; then\
		cat $(notdir $(basename $<)).log | grep -e "^!" -A 10 1>&2 ;\
		false ;\
	fi
ifeq (,$(shell [ -s $(CURDIR)/reference.bib ] || echo n))
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
	$(SYSDIR)/bin/gend "$<" > $@
	
-include $(foreach d,$(DIRS),$(patsubst %.tex,%.d,$(wildcard $(d)/*.tex)))
