#!perl -w
use strict;
use Data::Dumper;
use Test::More;
use Devel::Peek;

use File::Basename;
use File::Spec;
my $path = File::Basename::dirname( File::Spec->rel2abs(__FILE__) );

plan tests => 82;

## ----------------------------------------------------------------------------

delete @ENV{grep /https?_proxy/i, keys %ENV};

use_ok("Grpc::XS::Server");
use_ok("Grpc::XS::Channel");
use_ok("Grpc::XS::Call");
use_ok("Grpc::XS::Timeval");
use_ok("Grpc::Constants");

#####################################################
## setup
#####################################################

my $server = new Grpc::XS::Server();
my $port = $server->addHttp2Port('0.0.0.0:0');
my $channel = new Grpc::XS::Channel('localhost:'.$port);
$server->start();

#####################################################
## testSimpleRequestBody
#####################################################

my $deadline = Grpc::XS::Timeval::infFuture();
my $status_text = 'xyz';
my $call = new Grpc::XS::Call($channel,
                         'dummy_method',
                         $deadline);

my $event = $call->startBatch(
  Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
  Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
);

ok($event->{send_metadata},"startBatch failed return send_metadata");
ok($event->{send_close},"startBatch failed return send_close");

$event = $server->requestCall();
ok($event->{method} eq 'dummy_method',"event->method has wrong value");
my $server_call = $event->{call};

$event = $server_call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
        'metadata' => {},
        'code' => Grpc::Constants::GRPC_STATUS_OK(),
        'details' => $status_text,
    },
    Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
);

ok($event->{send_metadata},"send_metadata is not true");
ok($event->{send_status},"send_status is not true");
ok(!$event->{cancelled},"cancelled is not false");

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);

my $status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

#undef $call;
#undef $server_call;

#####################################################
## testMessageWriteFlags
#####################################################

$deadline = Grpc::XS::Timeval::infFuture();
my $req_text = 'message_write_flags_test';
$status_text = 'xyz';
$call = new Grpc::XS::Call($channel,
                           'dummy_method',
                           $deadline);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text,
                             'flags' => Grpc::Constants::GRPC_WRITE_NO_COMPRESS(), },
    Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
);

ok($event->{send_metadata},"startBatch failed return send_metadata");
ok($event->{send_close},"startBatch failed return send_close");

$event = $server->requestCall();
ok($event->{method} eq 'dummy_method',"event->method has wrong value");
$server_call = $event->{call};

$event = $server_call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
        'metadata' => {},
        'code' => Grpc::Constants::GRPC_STATUS_OK(),
        'details' => $status_text,
    },
);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);

$status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

#unset($call);
#unset($server_call);

#####################################################
## testClientServerFullRequestResponse
#####################################################

$deadline = Grpc::XS::Timeval::infFuture();
$req_text = 'client_server_full_request_response';
my $reply_text = 'reply:client_server_full_request_response';
$status_text = 'status:client_server_full_response_text';

$call = new Grpc::XS::Call($channel,
                           'dummy_method',
                           $deadline);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
    Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
);

ok($event->{send_metadata},"send_metadata is not true");
ok($event->{send_close},"send_close is not true");
ok($event->{send_message},"send_message is not true");

$event = $server->requestCall();
ok($event->{method} eq 'dummy_method',"event->method has wrong value");
$server_call = $event->{call};

$event = $server_call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $reply_text },
    Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
        'metadata' => {},
        'code' => Grpc::Constants::GRPC_STATUS_OK(),
        'details' => $status_text,
    },
    Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
    Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
);

ok($event->{send_metadata},"send_metadata is not true");
ok($event->{send_status},"send_status is not true");
ok($event->{send_message},"send_message is not true");
ok(!$event->{cancelled},"cancelled is not false");
ok($event->{message} eq $req_text,"status->message does not contain ".$req_text);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);

ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok(!(keys %{$event->{metadata}}),"event->metadata is not an empty hash");
ok($event->{message} eq $reply_text,"event->message does not contain ".$reply_text);

$status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

#####################################################
## @expectedException InvalidArgumentException
## testInvalidClientMessageArray
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                           'dummy_method',
                           $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => 'invalid',
  );
};
ok($@,"failed to trigger exception/testInvalidClientMessageArray");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidClientMessageString
#####################################################

## in perl 0 will be handled as a string as well

#eval {
#  $deadline = Grpc::XS::Timeval::infFuture();
#  $req_text = 'client_server_full_request_response';
#  $reply_text = 'reply:client_server_full_request_response';
#  $status_text = 'status:client_server_full_response_text';
#
#  $call = new Grpc::XS::Call($channel,
#                        'dummy_method',
#                        $deadline);
#
#  $event = $call->startBatch(
#      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
#      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
#      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => 0 },
#  );
#};
#ok($@,"failed to trigger exception/testInvalidClientMessageString");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidClientMessageFlags
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() =>  {'message' => 'abc',
                                                   'flags' => 'invalid'},
  );
};
ok($@,"failed to trigger exception/testInvalidClientMessageFlags");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidServerStatusMetadata
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
  );

  ok($event->{send_metadata},"send_metadata is not true");
  ok($event->{send_close},"send_close is not true");
  ok($event->{send_message},"send_message is not true");

  $event = $server->requestCall();
  ok($event->{method} eq 'dummy_method',"event->method has wrong value");
  $server_call = $event->{call};

  $event = $server_call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $reply_text },
      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
          'metadata' => 'invalid',
          'code' => Grpc::Constants::GRPC_STATUS_OK(),
          'details' => $status_text,
      },
      Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
      Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
  );
};
ok($@,"failed to trigger exception/testInvalidServerStatusMetadata");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidServerStatusCode
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
  );

  ok($event->{send_metadata},"send_metadata is not true");
  ok($event->{send_close},"send_close is not true");
  ok($event->{send_message},"send_message is not true");

  $event = $server->requestCall();
  ok($event->{method} eq 'dummy_method',"event->method has wrong value");
  $server_call = $event->{call};

  $event = $server_call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
          'metadata' => [],
          'code' => 'invalid',
          'details' => $status_text,
      },
      Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
      Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
  );
};
ok($@,"failed to trigger exception/testInvalidServerStatusCode");

#####################################################
## @expectedException InvalidArgumentException
## testMissingServerStatusCode
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
  );

  ok($event->{send_metadata},"send_metadata is not true");
  ok($event->{send_close},"send_close is not true");
  ok($event->{send_message},"send_message is not true");

  $event = $server->requestCall();
  ok($event->{method} eq 'dummy_method',"event->method has wrong value");
  $server_call = $event->{call};

  $event = $server_call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $reply_text },
      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
          'metadata' => {},
          'details' => $status_text,
      },
      Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
      Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
  );
};
ok($@,"failed to trigger exception/testMissingServerStatusCode");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidServerStatusDetails
#####################################################

## in perl 0 will be handled as a string as well

#eval {
#  $deadline = Grpc::XS::Timeval::infFuture();
#  $req_text = 'client_server_full_request_response';
#  $reply_text = 'reply:client_server_full_request_response';
#  $status_text = 'status:client_server_full_response_text';
#
#  $call = new Grpc::XS::Call($channel,
#                        'dummy_method',
#                        $deadline);
#
#  $event = $call->startBatch(
#      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
#      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
#      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
#  );
#
#  ok($event->{send_metadata},"send_metadata is not true");
#  ok($event->{send_close},"send_close is not true");
#  ok($event->{send_message},"send_message is not true");
#
#  $event = $server->requestCall();
#  ok($event->{method} eq 'dummy_method',"event->method has wrong value");
#  $server_call = $event->{call};
#
#  $event = $server_call->startBatch(
#      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
#      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $reply_text },
#      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
#          'metadata' => {},
#          'code' => Grpc::Constants::GRPC_STATUS_OK(),
#          'details' => 0,
#      },
#      Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
#      Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
#  );
#};
#ok($@,"failed to trigger exception/testInvalidServerStatusDetails");

#####################################################
## @expectedException InvalidArgumentException
## testMissingServerStatusDetails
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
  );

  ok($event->{send_metadata},"send_metadata is not true");
  ok($event->{send_close},"send_close is not true");
  ok($event->{send_message},"send_message is not true");

  $event = $server->requestCall();
  ok($event->{method} eq 'dummy_method',"event->method has wrong value");
  $server_call = $event->{call};

  $event = $server_call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $reply_text },
      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
          'metadata' => {},
          'code' => Grpc::Constants::GRPC_STATUS_OK(),
      },
      Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
      Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
  );
};
ok($@,"failed to trigger exception/testMissingServerStatusDetails");

#####################################################
## @expectedException InvalidArgumentException
## testInvalidStartBatchKey
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      9999999 => {},
  );
};
ok($@,"failed to trigger exception/testInvalidStartBatchKey");

#####################################################
## @expectedException LogicException
## testInvalidStartBatch
#####################################################

eval {
  $deadline = Grpc::XS::Timeval::infFuture();
  $req_text = 'client_server_full_request_response';
  $reply_text = 'reply:client_server_full_request_response';
  $status_text = 'status:client_server_full_response_text';

  $call = new Grpc::XS::Call($channel,
                        'dummy_method',
                        $deadline);

  $event = $call->startBatch(
      Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
      Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
      Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
          'metadata' => {},
          'code' => Grpc::Constants::GRPC_STATUS_OK(),
          'details' => 'abc',
      },
  );
};
ok($@,"failed to trigger exception/testInvalidStartBatch");

#####################################################
## testGetTarget()
#####################################################

ok($channel->getTarget() ne "","getTarget returns value");

#####################################################
## testGetConnectivityState()
#####################################################

$channel = new Grpc::XS::Channel('localhost:'.$port);
ok($channel->getConnectivityState() == Grpc::Constants::GRPC_CHANNEL_IDLE(),
                                                    "connection is not idle");

#####################################################
## testWatchConnectivityStateFailed()
#####################################################

$channel = new Grpc::XS::Channel('localhost:'.$port);
my $idle_state = $channel->getConnectivityState();
ok($idle_state == Grpc::Constants::GRPC_CHANNEL_IDLE(),
                                                    "connection is not idle");

my $now = Grpc::XS::Timeval::now();
my $delta = new Grpc::XS::Timeval(500000); ## should timeout
$deadline = $now->add($delta);

ok(!$channel->watchConnectivityState($idle_state, $deadline),
                                    "should timeout watchConnectivityState");

#####################################################
## testWatchConnectivityStateSuccess()
#####################################################

$channel = new Grpc::XS::Channel('localhost:'.$port);
$idle_state = $channel->getConnectivityState(1);
ok($idle_state == Grpc::Constants::GRPC_CHANNEL_IDLE(),
                                                    "connection is not idle");

$now = Grpc::XS::Timeval::now();
$delta = new Grpc::XS::Timeval(3000000); ## should finish well before
$deadline = $now->add($delta);

ok($channel->watchConnectivityState($idle_state, $deadline),
                                  "should not timeout watchConnectivityState");

my $new_state = $channel->getConnectivityState();
ok($idle_state != $new_state, "idle_state should not equal new_state");

#####################################################
## testWatchConnectivityStateDoNothing()
#####################################################

$channel = new Grpc::XS::Channel('localhost:'.$port);
$idle_state = $channel->getConnectivityState();
ok($idle_state == Grpc::Constants::GRPC_CHANNEL_IDLE(),
                                                    "connection is not idle");

$now = Grpc::XS::Timeval::now();
$delta = new Grpc::XS::Timeval(100000);
$deadline = $now->add($delta);

ok(!$channel->watchConnectivityState($idle_state, $deadline),
                                    "should timeout watchConnectivityState");

$new_state = $channel->getConnectivityState();
ok($new_state == Grpc::Constants::GRPC_CHANNEL_IDLE(),
                                                    "connection is not idle");

#####################################################
## @expectedException InvalidArgumentException
## testGetConnectivityStateInvalidParam()
#####################################################

eval {
  $channel = new Grpc::XS::Channel('localhost:'.$port);
  $channel->getConnectivityState(new Grpc::XS::Timeval());
};
ok($@,"failed to trigger exception/testGetConnectivityStateInvalidParam");

#####################################################
## @expectedException InvalidArgumentException
## testWatchConnectivityStateInvalidParam()
#####################################################

eval {
  $channel = new Grpc::XS::Channel('localhost:'.$port);
  $channel->watchConnectivityState(0, 1000);
};
ok($@,"failed to trigger exception/testWatchConnectivityStateInvalidParam");

#####################################################
## testClose()
#####################################################

$channel = new Grpc::XS::Channel('localhost:'.$port);
ok(!defined($channel->close()),"channel should not return value");

#####################################################
## testChannelConstructorInvalidParam()
## @expectedException InvalidArgumentException
#####################################################

eval {
  $channel = new Grpc::XS::Channel('localhost:'.$port, undef);
};
ok($@,"failed to trigger exception/InvalidArgumentException");
