#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 16;

use_ok('Grpc::AbstractCall');
use_ok('Grpc::BaseStub');
use_ok('Grpc::BidiStreamingCall');
use_ok('Grpc::ClientStreamingCall');
use_ok('Grpc::Constants');
use_ok('Grpc::ServerStreamingCall');
use_ok('Grpc::UnaryCall');
use_ok('Grpc::XS');
use_ok('Grpc::XS::Call');
use_ok('Grpc::XS::CallCredentials');
use_ok('Grpc::XS::Channel');
use_ok('Grpc::XS::ChannelCredentials');
use_ok('Grpc::XS::Constants');
use_ok('Grpc::XS::Server');
use_ok('Grpc::XS::ServerCredentials');
use_ok('Grpc::XS::Timeval');
