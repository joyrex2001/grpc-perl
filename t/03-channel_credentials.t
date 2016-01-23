#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 2;

use_ok("Grpc::XS::ChannelCredentials");

my $c;

#createDefault
# $c = Grpc::XS::ChannelCredentials::createDefault();
# isa_ok( $c, 'Grpc::XS::ChannelCredentials' );

#createSsl

#createComposite
#createInsecure
$c = Grpc::XS::ChannelCredentials::createInsecure();
ok( !defined($c), 'Grpc::XS::ChannelCredentials undef' );
