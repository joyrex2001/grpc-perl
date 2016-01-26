#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 5;

use_ok("Grpc::XS::Channel");

#new
my $channel;
eval { $channel = new Grpc::XS::Channel(); }; my $error = $@;
ok($error && !$channel,"invalid constructor");

$channel = new Grpc::XS::Channel("channel");
isa_ok( $channel, 'Grpc::XS::Channel' );

$channel = new Grpc::XS::Channel("channel", a => "abc", b => "cde" );
isa_ok( $channel, 'Grpc::XS::Channel' );

$channel = new Grpc::XS::Channel("channel", a => 1, b => 2 );
isa_ok( $channel, 'Grpc::XS::Channel' );

#getTarget
#getConnectivityState
#watchConnectivityState
#close
