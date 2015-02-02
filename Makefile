#
#

.PHONY: clean bundle

bundle:
	test -d bundle || mkdir bundle
	mv [OBAFGKM][0-9]V bundle/
	mv rate_* starRates_* starDB.dat mk.dat bundle/
	mv fov* bundle/

clean:
	$(RM) -r [OBAFGKM][0-9]V 
	$(RM) rate_????_?.??? starRates_????_?.??? starDB.dat mk.dat
	$(RM) fov*
