.PHONY: all clean package tests

all:
	/bin/true

clean:
	/bin/true

package:
	cd ubuntu && make

tests:
	cd tests && make tests
