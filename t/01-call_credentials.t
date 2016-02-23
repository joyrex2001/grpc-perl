#!perl -w
use strict;
use Data::Dumper;
use Test::More;

use File::Basename;
use File::Spec;
my $path = File::Basename::dirname( File::Spec->rel2abs(__FILE__) );

plan tests => 5;

use_ok("Grpc::XS::CallCredentials");

use lib ('/vagrant/grpc-perl/blib/lib/');
use lib ('/vagrant/grpc-perl/blib/arch/');

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
  print STDERR "\n\n".Dumper($context)."\n";
##  $this->assertTrue(is_string($context->service_url));
##  $this->assertTrue(is_string($context->method_name));
  return { 'k1' => 'v1', 'k2' => 'v2'};
}

#####################################################
## testCreateFromPlugin()
#####################################################

my $deadline = Grpc::XS::Timeval::infFuture();
my $status_text = 'xyz';
my $call = new Grpc::XS::Call($channel,
                              '/abc/dummy_method',
                              $deadline,
                              $host_override);

my $event = $call->startBatch(
        Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
        Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => 1,
    );
print STDERR "event=".Dumper($event);
#    $this->assertTrue($event->send_metadata);
#    $this->assertTrue($event->send_close);

$event = $server->requestCall();

#    $this->assertTrue(is_array($event->metadata));
my $metadata = $event->metadata;
#    $this->assertTrue(array_key_exists('k1', $metadata));
#    $this->assertTrue(array_key_exists('k2', $metadata));
#    $this->assertSame($metadata['k1'], ['v1']);
#    $this->assertSame($metadata['k2'], ['v2']);

#    $this->assertSame('/abc/dummy_method', $event->method);
my $server_call = $event->call;

$event = $server_call->startBatch(
    Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => {},
    Grpc::Constants::GRPC_OP_SEND_STATUS_FROM_SERVER() => {
        'metadata' => {},
        'code' => Grpc::Constants::GRPC_STATUS_OK(),
        'details' => $status_text,
    },
    Grpc::Constants::GRPC_OP_RECV_CLOSE_ON_SERVER() => 1,
);

#    $this->assertTrue($event->send_metadata);
#    $this->assertTrue($event->send_status);
#    $this->assertFalse($event->cancelled);

$event = $call->startBatch(
    Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => 1,
    Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => 1,
);

#    $this->assertSame([], $event->metadata);
my $status = $event->status;
#    $this->assertSame([], $status->metadata);
#    $this->assertSame(Grpc\STATUS_OK, $status->code);
#    $this->assertSame($status_text, $status->details);
print STDERR "\n\nDONE!\n\n";
