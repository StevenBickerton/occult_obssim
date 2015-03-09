#
#

INSTALL = /usr/bin/install
BINDIR  = $(HOME)/usr/bin
LIBDIR  = $(HOME)/usr/libperl/OccSim

PL = $(wildcard bin/*.pl)
SH = $(wildcard bin/*.sh)
PM = $(wildcard libperl/OccSim/*.pm)

.PHONY: clean bundle

install:
	$(INSTALL) -C -v $(PL) $(BINDIR)
	$(INSTALL) -C -v $(SH) $(BINDIR)
	$(INSTALL) -d $(LIBDIR)
	$(INSTALL) -C -v $(PM) $(LIBDIR)

bundle:
	@ simBundle.sh

clean:
	$(RM) -r [OBAFGKM][0-9]V 
	$(RM) *rate_????_?.??? *starRates_????_?.??? starDB.dat mk.dat
