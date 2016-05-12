#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 2;

use_ok("Grpc::Client::BaseStub");
use_ok("Grpc::XS::ChannelCredentials");

my $credentials = Grpc::XS::ChannelCredentials::createInsecure();
print STDERR Dumper($credentials);

my $stub = new Grpc::Client::BaseStub(
                'localhost:50051',
                credentials => $credentials,
                timeout => 1000000 );
print STDERR Dumper($stub);

my $unmarshall = sub { return $_; };
my $result = $stub->_simpleRequest(
                   method      => "/test/timeout",
                   deserialize => $unmarshall,
                   argument    => "testcall",
                   metadata    => undef,
                   options     => undef );
print STDERR Dumper($result);
