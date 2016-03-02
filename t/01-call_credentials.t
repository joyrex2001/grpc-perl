#!perl -w
use strict;
use Data::Dumper;
use Test::More;

use File::Basename;
use File::Spec;
my $path = File::Basename::dirname( File::Spec->rel2abs(__FILE__) );

plan tests => 28;

use_ok("Grpc::XS::CallCredentials");

## ----------------------------------------------------------------------------

use_ok("Grpc::XS::Server");
use_ok("Grpc::XS::ChannelCredentials");
use_ok("Grpc::XS::ServerCredentials");
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
my $call_credentials = Grpc::XS::CallCredentials::createFromPlugin(
        \&callbackFunc);
$credentials = Grpc::XS::ChannelCredentials::createComposite(
        $credentials,
        $call_credentials
        );
my $server_credentials = Grpc::XS::ServerCredentials::createSsl(
      # pem_root_certs  => undef,
        pem_private_key => file_get_contents($path.'/data/server1.key'),
        pem_cert_chain  => file_get_contents($path.'/data/server1.pem'));

my $server = new Grpc::XS::Server();
my $port = $server->addSecureHttp2Port('0.0.0.0:0',$server_credentials);
$server->start();

my $host_override = 'foo.test.google.fr';
my $channel = new Grpc::XS::Channel(
      'localhost:'.$port,
      'grpc.ssl_target_name_override' => $host_override,
      'grpc.default_authority' => $host_override,
      'credentials' => $credentials,
  );

#####################################################
## callback
#####################################################

sub callbackFunc {
  my $context = shift;
  ok($context->{service_url} =~ /google/,"call back func failed service_url");
  ok($context->{method_name} =~ /dummy/,"call back func failed method_name");
  return { 'k1' => [ 'v1' ], 'k2' => [ 'v2','v3' ] };
}

#####################################################
## testCreateFromPlugin()
#####################################################

my $deadline = Grpc::XS::Timeval::infFuture();
my $call = new Grpc::XS::Call($channel,
                              '/abc/dummy_method',
                              $deadline,
                              $host_override);

my $event = $call->startBatch(
        Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
        Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
    );
ok($event->{send_metadata},"startBatch failed return send_metadata");
ok($event->{send_close},"startBatch failed return send_close");

#####################################################

$event = $server->requestCall();
my $metadata = $event->{metadata};
ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok($event->{metadata}->{k1},"event->metadata->k1 does not exist");
ok($event->{metadata}->{k2},"event->metadata->k2 does not exist");
ok(ref($event->{metadata}->{k1})=~/ARRAY/,"event->metadata->k1 is not an array");
ok(ref($event->{metadata}->{k2})=~/ARRAY/,"event->metadata->k2 is not an array");
ok($event->{metadata}->{k1}->[0] eq 'v1',"event->metadata->k1 has wrong value");
ok($event->{metadata}->{k2}->[0] eq 'v2',"event->metadata->k1 has wrong value");
ok($event->{method} eq '/abc/dummy_method',"event->method has wrong value");

#####################################################

#print STDERR "event=".Dumper($event);

my $status_text = 'xyz';
my $server_call = $event->{call};
$event = $server_call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
        'metadata' => {},
        'code'     => Grpc::Constants::GRPC_STATUS_OK(),
        'details'  => $status_text,
    },
    Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
);
# print STDERR "event=".Dumper($event);

ok($event->{send_metadata},"send_metadata is not true");
ok($event->{send_status},"send_status is not true");
ok(!$event->{cancelled},"cancelled is not false");

#####################################################

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);
# print STDERR "event=".Dumper($event);

ok(ref($event->{metadata})=~/HASH/,"event->metadata is not a hash");
ok(!(keys %{$event->{metadata}}),"event->metadata is not an empty hash");

my $status = $event->{status};
ok(ref($status->{metadata})=~/HASH/,"status->metadata is not a hash");
ok(!(keys %{$status->{metadata}}),"status->metadata is not an empty hash");
ok(exists($status->{code}),"status->code does not exist");
ok($status->{code} == Grpc::Constants::GRPC_STATUS_OK(),"status->code not STATUS_OK");
ok(exists($status->{details}),"status->details does not exist");
ok($status->{details} eq $status_text,"status->details does not contain ".$status_text);
