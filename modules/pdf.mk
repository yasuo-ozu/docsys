TARGET_SUFFIXES+=pdf dvi log aux d fls
SOURCES_d+=tex
SOURCES_pdf+=dvi $(SOURCES_dvi)
SOURCES_fls+=tex
SOURCES_dvi+=tex
SOURCES_log+=tex
SOURCES_aux+=tex

%.pdf:	%.dvi $(SYSDIR)
	dvipdfmx $(basename $<) 2>&1
	qpdf --linearize $@ linearized_$@
	rm -f $@
	mv linearized_$@ $@
	
ifeq (,$(wildcard $(dir $<)/reference.bib))
reference.bib:
	touch $@
endif

TEX_BIN?=platex
TEX_FLAGS?=--shell-escape -interaction=batchmode -halt-on-error
PBIBTEX_BIN?=pbibtex

.SECONDARY:	%.dvi
%.dvi:	%.tex $(DEPS_$(notdir %)) %.d reference.bib $(SYSDIR)
	@echo $(TEX_BIN) $(TEX_FLAGS) $<
	@$(TEX_BIN) $(TEX_FLAGS) $< 1>/dev/null; if [ ! -f $(basename $<).dvi ]; then\
		cat $(basename $<).log | grep -e "^!" -A 10 1>&2 ;\
		false ;\
	fi
ifeq (,$(shell [ -s $(dir $<)/reference.bib ] || echo n))
	cd $(dir $<); $(PBIBTEX_BIN) $(notdir $(basename $<))
	$(TEX_BIN) $(TEX_FLAGS) $<  &>/dev/null
endif
	@for i in `seq 1 3`; do\
		if grep -qF 'Rerun to get cross-references right.' $(basename $<).log; then\
			echo $(TEX_BIN) $(TEX_FLAGS) $<\
			$(TEX_BIN) $(TEX_FLAGS) $< &>/dev/null; else exit 0;\
		fi;\
	done

.INTERMEDIATE:	%.fls
%.fls:	%.tex $(SYSDIR)
	$(TEX_BIN) -interaction=nonstopmode --shell-escape -recorder $<

.SECONDARY:	%.d
%.d:	%.tex $(wildcard ./*.tex) $(wildcard ./**/*.tex)
	$(SYSDIR)/bin/gend "$<" "$(patsubst %.tex,%.pdf,$<)" > $@
	
# bbl blg nav out toc snm vrb

-include $(patsubst %.tex,%.d,$(wildcard ./*.tex) $(wildcard ./**/*.tex))
