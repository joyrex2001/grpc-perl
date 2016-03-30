helloworld:
	mkdir helloworld
	cp -r t helloworld
	protoxs --cpp_out=helloworld --out=helloworld helloworld.proto
	cd helloworld ; perl Makefile.PL ; make ; make test

clean:
	rm -rf helloworld
