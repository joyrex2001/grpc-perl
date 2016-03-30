#!perl -w
use strict;
use Data::Dumper;

use Test::More;

use ProtobufXS::helloworld;
use ProtobufXS::helloworld::Service::Greeter;

use Grpc::XS::ChannelCredentials;

plan tests => 1;

my $credentials = Grpc::XS::ChannelCredentials::createInsecure();
my $greeter = new ProtobufXS::helloworld::Service::Greeter('localhost:50051',
		credentials => $credentials );

my $request = new ProtobufXS::helloworld::HelloRequest();
$request->set_name("grpc-perl");
my $call = $greeter->SayHello( argument => $request );
my $response = $call->wait();
print STDERR Dumper($response);
if ($response) {
	print STDERR Dumper($response->to_hashref());
}
ok($response,"didn't receive a response from server");
