.PHONY: all clean package tests

all:
	/bin/true

clean:
	/bin/true

package:
	cd pkg && make

tests:
	cd tests && make tests
