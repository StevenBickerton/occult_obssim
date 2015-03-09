#
#

INSTALL = /usr/bin/install
BINDIR  = $(HOME)/usr/bin

PL = $(wildcard bin/*.pl)
SH = $(wildcard bin/*.sh)


.PHONY: clean bundle

install:
	$(INSTALL) -C -v $(PL) $(BINDIR)
	$(INSTALL) -C -v $(SH) $(BINDIR)

bundle:
	@ simBundle.sh

clean:
	$(RM) -r [OBAFGKM][0-9]V 
	$(RM) *rate_????_?.??? *starRates_????_?.??? starDB.dat mk.dat
