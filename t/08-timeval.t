#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 11;

use_ok("Grpc::XS::Timeval");
use_ok("Grpc::Constants");

my $new = new Grpc::XS::Timeval();
isa_ok( $new, 'Grpc::XS::Timeval' );
ok( $new->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

#similar
#compare
#substract
#add
#sleepUntil
#now

my $zero = Grpc::XS::Timeval::zero();
isa_ok( $zero, 'Grpc::XS::Timeval' );
ok( $zero->getTvSec()==0,"tvsec = 0");
ok( $zero->getTvNsec()==0,"tvnsec = 0");
ok( $zero->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

my $inf = Grpc::XS::Timeval::infFuture();
isa_ok( $zero, 'Grpc::XS::Timeval' );
#ok( $zero->getTvSec()==9223372036854775807,"tvsec = 0");
ok( $zero->getTvNsec()==0,"tvnsec = 0");
ok( $zero->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

#infPast
#getTvNsec
#getTvSec
#getClockType
