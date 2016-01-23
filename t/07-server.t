#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 1;

use_ok("Grpc::XS::Server");

#new
#requestCall
#addSecureHttp2Port
#start
