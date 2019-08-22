#!perl -w
use strict;
use Data::Dumper;
use Test::More;
use Devel::Peek;

use File::Basename;
use File::Spec;
my $path = File::Basename::dirname( File::Spec->rel2abs(__FILE__) );

plan tests => 46;

use_ok("Grpc::XS::CallCredentials");

## ----------------------------------------------------------------------------

delete @ENV{grep /https?_proxy/i, keys %ENV};

use_ok("Grpc::XS::Server");
use_ok("Grpc::XS::Channel");
use_ok("Grpc::XS::Call");
use_ok("Grpc::XS::Timeval");
use_ok("Grpc::Constants");

sub file_get_contents {
  my $file = shift;
  open(F,"<".$file);
  my $content = join("",<F>);
  close(F);
  return $content;
}

#####################################################
## setup
#####################################################

my $credentials = Grpc::XS::ChannelCredentials::createSsl(
        pem_root_certs => file_get_contents($path.'/data/ca.pem'));
my $server_credentials = Grpc::XS::ServerCredentials::createSsl(
        pem_root_certs  => undef,
        pem_private_key => file_get_contents($path.'/data/server1.key'),
        pem_cert_chain  => file_get_contents($path.'/data/server1.pem'));

my $server = new Grpc::XS::Server();
my $port = $server->addSecureHttp2Port('0.0.0.0:0',
                                              $server_credentials);
$server->start();
my $host_override = 'foo.test.google.fr';
my $channel = new Grpc::XS::Channel(
            'localhost:'.$port,
            'grpc.ssl_target_name_override' => $host_override,
            'grpc.default_authority' => $host_override,
            'credentials' => $credentials,
        );

#####################################################
## testSimpleRequestBody
#####################################################

my $deadline = Grpc::XS::Timeval::infFuture();
my $status_text = 'xyz';
my $call = new Grpc::XS::Call($channel,
                      'dummy_method',
                      $deadline,
                      $host_override);

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

ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok(!(keys %{$event->{metadata}}),"event->metadata is not an empty hash");

my $status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

#####################################################
## testMessageWriteFlags
#####################################################

$deadline = Grpc::XS::Timeval::infFuture();
my $req_text = 'message_write_flags_test';
$status_text = 'xyz';
$call = new Grpc::XS::Call($channel,
                      'dummy_method',
                      $deadline,
                      $host_override);

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

ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok(!(keys %{$event->{metadata}}),"event->metadata is not an empty hash");

$status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

#####################################################
## testClientServerFullRequestResponse
#####################################################

$deadline = Grpc::XS::Timeval::infFuture();
$req_text = 'client_server_full_request_response';
my $reply_text = 'reply:client_server_full_request_response';
$status_text = 'status:client_server_full_response_text';

$call = new Grpc::XS::Call($channel,
                      'dummy_method',
                      $deadline,
                      $host_override);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
    Grpc::Constants::GRPC_OP_SEND_MESSAGE() => { 'message' => $req_text },
);

#$this->assertTrue($event->send_metadata);
#$this->assertTrue($event->send_close);
#$this->assertTrue($event->send_message);

$event = $server->requestCall();
#$this->assertSame('dummy_method', $event->method);
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
ok($req_text eq $event->{message},"message does not equal $req_text");

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_MESSAGE() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);

ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok(!(keys %{$event->{metadata}}),"event->metadata is not an empty hash");
ok($reply_text eq $event->{message},"message does not equal $reply_text");

$status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);

# I was not able to trigger a plugin calls without ssl/composite credentials, so let's test it there
subtest "plugin credentials error handling" => sub {
    my $always_die = sub {
        die "HERE";
    };

    my $not_a_reference = sub {
        return "string";
    };

    my $not_a_hashref = sub {
        return [5, 7, 9];
    };

    my $nothing = sub {
        return;
    };

    my @tests = (
        [$always_die, "always_die", qr/HERE/],
        [$not_a_reference, "not_a_reference", qr/calback returned non-reference/],
        [$not_a_hashref, 'not_a_hashref', qr/callback returned invalid metadata/],
        [$nothing, 'nothing', qr/calback returned non-reference/],
    );

    for my $test (@tests) {
        my ($plugin, $name, $expect_like) = @$test;

        subtest $name => sub {
            my $call_creds = Grpc::XS::CallCredentials::createFromPlugin($plugin);

            my $credentials = Grpc::XS::ChannelCredentials::createComposite($credentials, $call_creds);
            my $channel = new Grpc::XS::Channel(
                'localhost:'.$port,
                'grpc.ssl_target_name_override' => $host_override,
                'grpc.default_authority' => $host_override,
                'credentials' => $credentials,
            );

            my $call = new Grpc::XS::Call(
                $channel,
                '/dummy_method',
                $deadline,
                $host_override
            );

            my $event = $call->startBatch(
                Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
                Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
                Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
            );

            my $details = $event->{status}{details};
            if ($details =~ $expect_like) {
                ok 1, "Status looks good"
            } else {
                # bail out immediately, or we can become stuck on the next iteration
                die "'$details' doesn't look like $expect_like";
            }
        };
    }
};
