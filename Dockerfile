FROM docker.io/grpc/cxx:1.12.0

ADD . /opt/grpc-perl

WORKDIR /opt/grpc-perl

RUN perl -MCPAN -e 'install Devel::CheckLib' \
 && perl -MCPAN -e 'install Google::ProtocolBuffers::Dynamic' \
 && perl Makefile.PL \
 && make test \
 && make install
