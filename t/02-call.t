#!perl -w
use strict;
use Data::Dumper;
use Test::More;

plan tests => 15;
use lib ('/vagrant/grpc-perl/blib/lib/');
use lib ('/vagrant/grpc-perl/blib/arch/');

#cancel
#setCredentials

use_ok("Grpc::XS::Call");
use_ok("Grpc::XS::Channel");
use_ok("Grpc::XS::Timeval");
use_ok("Grpc::Constants");

my $channel= new Grpc::XS::Channel("channel");
my $deadline = Grpc::XS::Timeval::infFuture();
my $c = new Grpc::XS::Call($channel,"helloWorld",$deadline);
isa_ok( $c, 'Grpc::XS::Call' );
can_ok( $c, 'startBatch' );
can_ok( $c, 'getPeer' );
can_ok( $c, 'cancel' );
can_ok( $c, 'setCredentials' );
undef $c;

my $server = new Grpc::XS::Server();
my $port = $server->addHttp2Port('0.0.0.0:0');

$channel = new Grpc::XS::Channel('localhost:'.$port);
my $call = new Grpc::XS::Call($channel,
                              '/foo',
                              Grpc::XS::Timeval::infFuture());

my $result;

#check if hash works as input
my %batch = (
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
);
$result = $call->startBatch(%batch);
ok($result->{send_metadata},"hash as input for startBatch");

## testAddEmptyMetadata
$result = $call->startBatch(
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
my $peer = $call->getPeer();
ok(defined($result),"testGetPeer");
