TARGET_SUFFIXES+=png eps
SOURCES_png+=txt
SOURCES_eps+=txt

.SECONDARY: %.txt
%.txt:	%.maxima
	rm -f $@
	maxima -b $<

.SECONDARY: %.png
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

.SECONDARY: %.eps
%.eps:	%.txt
	@/bin/echo 'set terminal postscript eps enhanced color size 800,600;\
	 set xlabel '`cat $<|head -n 1|cut -c 2- |cut -f 1`';\
	 set ylabel '`cat $<|head -n 1|cut -c 2- |cut -f 2`';unset key;\
	 plot "$<" using 1:2 w p pt 7 lc rgbcolor "#FFFFFF" ps 2;\
	 replot "$<" using 1:2 w p pt 6 lc black ps 2;\
	 replot "$<" using 1:2 w p pt 7 lc black ps 0.5;\
	 set out "$@";replot'|gnuplot > /dev/null

