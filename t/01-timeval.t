#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 2;

use_ok("Grpc::XS::Timeval");

my $zero = Grpc::XS::Timeval::zero();
ok($zero->{tv_sec}==0 && $zero->{tv_nsec}==0 && $zero->{clock_type}==1,'timespec zero fails');
print STDERR Dumper(Grpc::XS::Timeval::zero())
