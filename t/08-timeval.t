#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 20;

use_ok("Grpc::XS::Timeval");
use_ok("Grpc::Constants");

#similar
#getClockType
#sleepUntil

my $new = new Grpc::XS::Timeval();
isa_ok( $new, 'Grpc::XS::Timeval' );
ok( $new->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

my $zero = Grpc::XS::Timeval::zero();
isa_ok( $zero, 'Grpc::XS::Timeval' );
ok( $zero->getTvSec()==0,"tvsec = 0");
ok( $zero->getTvNsec()==0,"tvnsec = 0");
ok( $zero->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

my $inf = Grpc::XS::Timeval::infFuture();
isa_ok( $inf, 'Grpc::XS::Timeval' );
ok( $inf->getClockType()==Grpc::Constants::GPR_CLOCK_REALTIME(),"ClockType = GPR_CLOCK_REALTIME");

$zero = Grpc::XS::Timeval::zero();
ok(Grpc::XS::Timeval::compare($zero, $zero)==0,"testCompareSame");

$zero = Grpc::XS::Timeval::zero();
my $past = Grpc::XS::Timeval::infPast();
ok(Grpc::XS::Timeval::compare($past, $zero)<0,"testPastIsLessThanZero 1");
ok(Grpc::XS::Timeval::compare($zero, $past)>0,"testPastIsLessThanZero 2");

$zero = Grpc::XS::Timeval::zero();
my $future = Grpc::XS::Timeval::infFuture();
ok(Grpc::XS::Timeval::compare($zero, $future)<0,"testFutureIsLessThanZero 1");
ok(Grpc::XS::Timeval::compare($future, $zero)>0,"testFutureIsLessThanZero 2");

$zero = Grpc::XS::Timeval::zero();
$future = Grpc::XS::Timeval::infFuture();
my $now = Grpc::XS::Timeval::now();
ok(Grpc::XS::Timeval::compare($zero,$now)<0,"testNowIsBetweenZeroAndFuture 1");
ok(Grpc::XS::Timeval::compare($now,$future)<0,"testNowIsBetweenZeroAndFuture 2");

$now = Grpc::XS::Timeval::now();
my $delta = new Grpc::XS::Timeval(1000);
my $deadline = $now->add($delta);
ok(Grpc::XS::Timeval::compare($deadline, $now)>0,"testNowAndAdd");

$now = Grpc::XS::Timeval::now();
$delta = new Grpc::XS::Timeval(1000);
$deadline = $now->substract($delta);
ok(Grpc::XS::Timeval::compare($deadline, $now)<0,"testNowAndAdd");

$now = Grpc::XS::Timeval::now();
$delta = new Grpc::XS::Timeval(1000);
$deadline = $now->add($delta);
my $back_to_now = $deadline->substract($delta);
ok(Grpc::XS::Timeval::compare($back_to_now, $now)==0,"testAddAndSubtract");
