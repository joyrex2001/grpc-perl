package Grpc::XS;
use strict;
use warnings;
use XSLoader;

our $VERSION = '0.1';

XSLoader::load(__PACKAGE__, $VERSION );

END { destroy(); }

1;
