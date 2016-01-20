#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 1;

use_ok("Grpc::XS::Timeval");

my $zero = Grpc::XS::Timeval::zero();
print STDERR Dumper($zero);
print STDERR $zero->getTvSec()."\n";
print STDERR $zero->getTvNsec()."\n";
print STDERR $zero->getClockType()."\n";
my $inf = Grpc::XS::Timeval::infFuture();
print STDERR Dumper($inf);
print STDERR $inf->getTvSec()."\n";
print STDERR $inf->getTvNsec()."\n";
print STDERR $inf->getClockType()."\n";
#ok($zero->{tv_sec}==0 && $zero->{tv_nsec}==0 && $zero->{clock_type}==1,'timespec zero fails');
print STDERR Dumper(Grpc::XS::Timeval::zero())
