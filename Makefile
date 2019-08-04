.PHONY:	all clean
	
DOCSYS=.docsys
TMPDIR=.unwrap-temp
SYSDIR=$(abspath $(if $(filter $(DOCSYS),$(notdir $(CURDIR))),.,$(DOCSYS)))
CLEANING_FILE=$(TMPDIR) *.d *.out.saty *.pdf *.log *.aux *.dvi *.fls *.bbl *.blg *.nav *.out *.toc *.snm

SHELL=/bin/bash
VPATH=$(SYSDIR)
.DELETE_ON_ERROR: ;
	
all:	$(patsubst %.saty,%.pdf,$(wildcard ./*.saty) $(wildcard ./**/*.saty)) $(patsubst %.tex,%.pdf,$(wildcard ./*.tex) $(wildcard ./**/*.tex))
	
# HELP

.SILENT:	help
.PHONY:	help clean
help:
	+echo "$(MAKE) (help|install|clean)"

install:
	@if [ -z "$(if $(filter .docsys,$(notdir $(CURDIR))),y,)" ] ; then \
		echo "Please 'git clone' or 'git submodule add' this repository in '$(DOCSYS)' directory under your project." ;\
		exit 1 ;\
	fi ;
	ln -snf ".docsys/Makefile" ../Makefile
	@if [ -f ../.gitignore ]; then \
		diff ../.gitignore ./.gitignore | sed -ne '/^> /p' | cut -b 3- >> ../.gitignore ; \
		echo "diff ../.gitignore ./.gitignore | sed -ne '/^> /p' | cut -b 3- >> ../.gitignore" ; \
	else \
		cp ./.gitignore ../.gitignore ;\
		echo "cp ./.gitignore ../.gitignore" ;\
	fi

clean:
	rm -rf $(patsubst %.txt,%.eps,$(wildcard *.txt))
	rm -rf $(patsubst %.txt,%.png,$(wildcard *.txt))
	rm -rf $(patsubst %.svg,%.png,$(wildcard *.svg))
	rm -rf $(patsubst %.svg,%.pdf,$(wildcard *.svg))
	rm -rf $(patsubst %.maxima,%.txt,$(wildcard *.maxima))
	rm -rf $(patsubst %.tex,%.pdf,$(wildcard *.pdf))
	rm -rf $(addprefix ./**/,$(CLEANING_FILE)) $(CLEANING_FILE)

# SATySFi

%.pdf:	%.out.saty
	satysfi "$<" -o "$@"
	
.SECONDARY:	%.out.saty
%.out.saty:	%.saty
	cd "$(dir $<)"; cat "$<" | $(SYSDIR)/bin/unwrap "$(TMPDIR)" > "$@"
	
# LaTeX

%.pdf:	%.dvi Makefile
	dvipdfmx $(basename $<) 2>&1
	qpdf --linearize $@ linearized_$@
	rm -f $@
	mv linearized_$@ $@
reference.bib:
	if [ ! -f "$@" ]; then touch "$@" ; fi

.SECONDARY:	%.dvi
%.dvi:	%.tex %.d reference.bib Makefile
	@if ! platex --shell-escape -interaction=batchmode -halt-on-error $< 1>/dev/null ; then\
		cat $(basename $<).log | grep -e "^!" -A 10 1>&2 ;\
		false ;\
	fi
	if [ -s "reference.bib" ]; then pbibtex $(basename $<) ; fi
	if [ -s "reference.bib" ]; then platex --shell-escape -interaction=batchmode -halt-on-error $<  &>/dev/null; fi
	for i in `seq 1 3`; do\
		if grep -F 'Rerun to get cross-references right.' $(basename $<).log; then\
			platex --shell-escape -interaction=batchmode -halt-on-error $< &>/dev/null; else exit 0;\
		fi;\
	done

.INTERMEDIATE:	%.fls
%.fls:	%.tex Makefile
	platex -interaction=nonstopmode --shell-escape -recorder $<

# .d file

.SECONDARY:	%.d
%.d:	%.out.saty $(patsubst %.saty,%.out.saty,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
	$(SYSDIR)/bin/gend "$<" "$(patsubst %.out.saty,%.pdf,$<)" > $@
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
	
%.d:	%.tex $(wildcard ./*.tex) $(wildcard ./**/*.tex)
	$(SYSDIR)/bin/gend "$<" "$(patsubst %.tex,%.pdf,$<)" > $@
-include $(patsubst %.tex,%.d,$(wildcard ./*.tex) $(wildcard ./**/*.tex))
	
# image
%.png:	%.svg
	convert -units PixelsPerInch -density 72x72 $< $@
#svg/%.eps:	svg/%.svg
#	convert -units PixelsPerInch -density 72x72 $< $@
%.pdf:	%.svg
	#convert -units PixelsPerInch -density 72x72 $< $@
	#convert $< $@
	inkscape -f $< -A $@

# Plot
%.png:	%.txt
	if [ `wc -l $< | cut -d " " -f 1` -ge 50 ]; then \
	/bin/echo 'set terminal pngcairo dashed size 800,600;\
	 set xlabel '`cat $<|head -n 1|cut -c 2- |cut -f 1`';\
	 set ylabel '`cat $<|head -n 1|cut -c 2- |cut -f 2`';unset key;\
	 plot "$<" using 1:2 w l lc black;\
	 set out "$@";replot'|gnuplot > /dev/null\
	 ; else \
	/bin/echo 'set terminal pngcairo dashed size 800,600;\
	 set xlabel '`cat $<|head -n 1|cut -c 2- |cut -f 1`';\
	 set ylabel '`cat $<|head -n 1|cut -c 2- |cut -f 2`';unset key;\
	 plot "$<" using 1:2 w p pt 7 lc rgbcolor "#FFFFFF" ps 2;\
	 replot "$<" using 1:2 w p pt 6 lc black ps 2;\
	 replot "$<" using 1:2 w p pt 7 lc black ps 0.5;\
	 set out "$@";replot'|gnuplot > /dev/null\
	 ; fi
%.eps:	%.txt
	@/bin/echo 'set terminal postscript eps enhanced color size 800,600;\
	 set xlabel '`cat $<|head -n 1|cut -c 2- |cut -f 1`';\
	 set ylabel '`cat $<|head -n 1|cut -c 2- |cut -f 2`';unset key;\
	 plot "$<" using 1:2 w p pt 7 lc rgbcolor "#FFFFFF" ps 2;\
	 replot "$<" using 1:2 w p pt 6 lc black ps 2;\
	 replot "$<" using 1:2 w p pt 7 lc black ps 0.5;\
	 set out "$@";replot'|gnuplot > /dev/null

%.txt:	%.maxima
	rm -f $@
	maxima -b $<

