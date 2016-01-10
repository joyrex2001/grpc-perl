#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 8;

use_ok('Grpc::Stub::AbstractCall');
use_ok('Grpc::Stub::BaseStub');
use_ok('Grpc::Stub::BidiStreamingCall');
use_ok('Grpc::Stub::ClientStreamingCall');
use_ok('Grpc::Stub::ServerStreamingCall');
use_ok('Grpc::Stub::UnaryCall');
use_ok('Grpc::XS');
use_ok('Grpc::XS::Timeval');
