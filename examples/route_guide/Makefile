route_guide:
	mkdir route_guide 
	cp -r t route_guide 
	protoxs --cpp_out=route_guide --out=route_guide route_guide.proto
	cd route_guide; perl Makefile.PL ; make ; make test

clean:
	rm -rf route_guide 
