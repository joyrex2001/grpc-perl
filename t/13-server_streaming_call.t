#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 1;

use_ok("Grpc::Stub::ServerStreamingCall");
