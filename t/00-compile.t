#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 15;

use_ok('Grpc::Stub::AbstractCall');
use_ok('Grpc::Stub::BaseStub');
use_ok('Grpc::Stub::BidiStreamingCall');
use_ok('Grpc::Stub::ClientStreamingCall');
use_ok('Grpc::Stub::ServerStreamingCall');
use_ok('Grpc::Stub::UnaryCall');
use_ok('Grpc::XS');
use_ok('Grpc::XS::Call');
use_ok('Grpc::XS::CallCredentials');
use_ok('Grpc::XS::Channel');
use_ok('Grpc::XS::ChannelCredentials');
use_ok('Grpc::XS::Constants');
use_ok('Grpc::XS::Server');
use_ok('Grpc::XS::ServerCredentials');
use_ok('Grpc::XS::Timeval');
