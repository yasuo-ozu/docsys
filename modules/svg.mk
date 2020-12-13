TARGET_SUFFIXES+=png pdf
SOURCES_png+=svg
SOURCES_pdf+=svg

%.png:	%.svg
	inkscape --export-type=png $< -o $$
	
%.pdf:	%.svg
	inkscape --export-type=pdf $< -o $@

