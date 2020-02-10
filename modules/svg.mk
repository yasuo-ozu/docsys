TARGET_SUFFIXES+=png pdf
SOURCES_png+=svg
SOURCES_pdf+=svg

%.png:	%.svg
	#convert -units PixelsPerInch -density 72x72 $< $@
	inkscape -f $< -e $p
	
%.pdf:	%.svg
	inkscape -f $< -A $@

