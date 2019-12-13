TARGET_SUFFIXES+=png pdf
SOURCES_png+=svg
SOURCES_pdf+=svg

%.png:	%.svg
	convert -units PixelsPerInch -density 72x72 $< $@
#svg/%.eps:	svg/%.svg
#	convert -units PixelsPerInch -density 72x72 $< $@
%.pdf:	%.svg
	#convert -units PixelsPerInch -density 72x72 $< $@
	#convert $< $@
	inkscape -f $< -A $@

