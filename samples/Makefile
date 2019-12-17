SAMPLES=$(foreach d,$(wildcard ./*),$(if $(wildcard $(d)/*),$(d)))

.PHONY:	test
test:	$(patsubst %,%.build,$(SAMPLES))
	@echo "*** ALL TEST PASSED"
	$(MAKE) clean

.PHONY:	%.build
%.build:
	make -C $(basename $@) --makefile=../../Makefile

.PHONY:	clean
clean:	$(patsubst %,%.clean,$(SAMPLES))

.PHONY:	%.clean
%.clean:
	make -C $(basename $@) --makefile=../../Makefile distclean
