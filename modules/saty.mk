TARGET_SUFFIXES+=pdf d osaty
SOURCES_pdf+=saty
SOURCES_osaty+=saty
SOURCES_d+=osaty $(SOURCES_osaty)

%.pdf:	%.osaty
	satysfi "$<" -o "$@"
	
.SECONDARY:	%.osaty
%.osaty:	%.saty
	cd "$(dir $<)"; cat "$<" | $(SYSDIR)/bin/unwrap "$(TMPDIR)" > "$@"

.SECONDARY:	%.d
%.d:	%.osaty $(patsubst %.saty,%.out.saty,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
	$(SYSDIR)/bin/gend "$<" "$(patsubst %.out.saty,%.pdf,$<)" > $@
-include $(patsubst %.saty,%.d,$(wildcard ./*.saty) $(wildcard ./**/*.saty))
