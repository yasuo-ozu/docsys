TARGET_SUFFIXES+=txt
SOURCES_txt+=maxima

%.txt:	%.maxima
	rm -f $@
	maxima -b $<


