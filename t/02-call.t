#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 8;

use_ok("Grpc::XS::Call");
use_ok("Grpc::XS::Channel");
use_ok("Grpc::XS::Timeval");

my $channel= new Grpc::XS::Channel("channel");
my $deadline = Grpc::XS::Timeval::infFuture();
my $c = new Grpc::XS::Call($channel,"helloWorld",$deadline);
## test constructor

isa_ok( $c, 'Grpc::XS::Call' );
can_ok( $c, 'startBatch' );
can_ok( $c, 'getPeer' );
can_ok( $c, 'cancel' );
can_ok( $c, 'setCredentials' );

#startBatch
#getPeer
#cancel
#setCredentials
