#!perl -w
use strict;
use Data::Dumper;

use Test::More;

use ProtobufXS::routeguide;
use ProtobufXS::routeguide::Service::RouteGuide;

plan tests => 2;


sub printFeature
{
	my $feature = shift;

	my $name = $feature->{name};
  if (!$name) {
    $name = "no feature";
  } else {
    $name = "feature called $name";
  }
 	print sprintf("Found %s \n  at %f, %f\n", $name,
                ($feature->{location}->{latitude}||0) / 10000000,
                ($feature->{location}->{longitude}||0) / 10000000);
}

################
## getFeature ##
################

# Run the getFeature demo. Calls getFeature with a point known to have a
# feature and a point known not to have a feature.

my $client = new ProtobufXS::routeguide::Service::RouteGuide('localhost:10000',
																															credentials => undef );

my @points = (
	{
		latitude  => 409146138,
		longitude => -746188906,
	},
	{
		latitude  => 0,
		longitude => 0,
	},
);

foreach my $p (@points) {
	my $point = new ProtobufXS::routeguide::Point($p);
	my $call = $client->GetFeature( argument => $point );
	my $response = $call->wait();
	print STDERR Dumper($response);
	if ($response) {
		print STDERR Dumper($response->to_hashref());
	}
	ok($response,"didn't receive a response from server");
	#printFeature($response->to_hashref());
}
