#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 6;

use_ok("Grpc::XS::Call");

my $c = new Grpc::XS::Call();
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
