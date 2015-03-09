#
#

INSTALL = /usr/bin/install
BINDIR  = $(HOME)/usr/bin
LIBDIR  = $(HOME)/usr/libperl/OccSim

BINPL = $(wildcard bin/*.pl)
BINSH = $(wildcard bin/*.sh)
LIBPM = $(wildcard libperl/OccSim/*.pm)
PL    = $(patsubst bin/%, %, $(wildcard bin/*.pl))
SH    = $(patsubst bin/%, %, $(wildcard bin/*.sh))


.PHONY: clean bundle

install:
	$(INSTALL) -C -v $(BINPL) $(BINDIR)
	$(INSTALL) -C -v $(BINSH) $(BINDIR)
	$(INSTALL) -d $(LIBDIR)
	$(INSTALL) -C -v $(LIBPM) $(LIBDIR)

uninstall:
	cd $(BINDIR); $(RM) $(PL); cd -
	cd $(BINDIR); $(RM) $(SH); cd -
	$(RM) -r $(LIBDIR)

bundle:
	@ simBundle.sh

clean:
	$(RM) -r [OBAFGKM][0-9]V 
	$(RM) *rate_????_?.??? *starRates_????_?.??? starDB.dat mk.dat
