#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 2;

use_ok("Grpc::XS::Timeval");
ok(Grpc::XS::Timeval::add_numbers_perl(1,2)==3,'1+2!=3?');
