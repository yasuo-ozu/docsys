TARGET_SUFFIXES+=pdf d osaty
SOURCES_pdf+=saty
SOURCES_d+=saty

%.pdf:	%.saty
	eval $(opam env)
	env SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos satysfi -- -o $@ $<
	
.SECONDARY:	%.d
%.d:	%.saty
	eval $(opam env)
	env SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps -r -p --depfile $@ --mode pdf -o "$(basename $@)" $<
	
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
