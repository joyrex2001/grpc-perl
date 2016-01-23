#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 1;

use_ok("Grpc::XS::Channel");

#my $c = new Grpc::XS::Channel();

#new
#getTarget
#getConnectivityState
#watchConnectivityState
#close
