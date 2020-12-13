TARGET_SUFFIXES+=pdf d osaty
SOURCES_pdf+=saty
SOURCES_d+=saty

%.pdf:	%.osaty
	SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos satysfi -- -o $@ $<
	
.SECONDARY:	%.d
%.d:	%.saty
	SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps -r -p --depfile $@ --mode pdf -o "$(basename $@)" $<
	
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
