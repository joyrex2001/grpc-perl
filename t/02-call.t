#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 13;

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

use_ok("Grpc::Constants");

my $server = new Grpc::XS::Server();
my $port = $server->addHttp2Port('0.0.0.0:0');

$channel = new Grpc::XS::Channel('localhost:'.$port);
my $call = new Grpc::XS::Call($channel,
                              '/foo',
                              Grpc::XS::Timeval::infFuture());

## testAddEmptyMetadata
my $result = $call->startBatch(
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {} );
ok($result->{send_metadata},"testAddEmptyMetadata");

## testAddSingleMetadata
$result = $call->startBatch(
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => { 'key' => ['value'] },
);
ok($result->{send_metadata},"testAddSingleMetadata");

## testAddMultiValueMetadata
$result = $call->startBatch(
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => { 'key' => ['value1', 'value2'] },
);
ok($result->{send_metadata},"testAddMultiValueMetadata");

## testAddSingleAndMultiValueMetadata
$result = $call->startBatch(
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {
                                          'key1' => ['value1'],
                                          'key2' => ['value2', 'value3'] },
);
ok($result->{send_metadata},"testAddSingleAndMultiValueMetadata");

## testGetPeer
#    $this->assertTrue(is_string($this->call->getPeer()));


#check if hash works as input
#my %batch = (
#  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
#);
#my $result = $call->startBatch(%batch);
