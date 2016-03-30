#Greeter example

This is the perl version of the standard 'greeter' (Hello World) example.

As the perl implementation does not support a server, it requires a running server implemented in another language (e.g. the go greeter server).

The example requires an updated version of the protoxs-perl compiler to be installed (https://github.com/joyrex2001/protobuf-perlxs).

Note that the protoxs-perl protocol buffer implementation only supports version 2 of the protocolbuffers, therefor the helloworld.proto has been adjusted accordingly.

To run the example, simply type 'make'. This will compile the proto file, and runs the test as specified in the t/ folder.
