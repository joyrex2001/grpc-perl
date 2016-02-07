#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 16;

use_ok('Grpc::Client::AbstractCall');
use_ok('Grpc::Client::BaseStub');
use_ok('Grpc::Client::BidiStreamingCall');
use_ok('Grpc::Client::ClientStreamingCall');
use_ok('Grpc::Client::ServerStreamingCall');
use_ok('Grpc::Client::UnaryCall');
use_ok('Grpc::Constants');
use_ok('Grpc::XS');
use_ok('Grpc::XS::Call');
use_ok('Grpc::XS::CallCredentials');
use_ok('Grpc::XS::Channel');
use_ok('Grpc::XS::ChannelCredentials');
use_ok('Grpc::XS::Constants');
use_ok('Grpc::XS::Server');
use_ok('Grpc::XS::ServerCredentials');
use_ok('Grpc::XS::Timeval');
