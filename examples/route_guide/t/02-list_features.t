#!perl -w
use strict;
use Data::Dumper;

use Test::More;

use ProtobufXS::routeguide;
use ProtobufXS::routeguide::Service::RouteGuide;

plan tests => 1;


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

##################
## listFeatures ##
##################

# Run the listFeatures demo. Calls listFeatures with a rectangle
# containing all of the features in the pre-generated
# database. Prints each response as it comes in.

my $client = new ProtobufXS::routeguide::Service::RouteGuide('localhost:10000',
																															credentials => undef );

my $lo_point = new ProtobufXS::routeguide::Point({
	latitude  => 400000000,
	longitude => -750000000,
});
my $hi_point = new ProtobufXS::routeguide::Point({
	latitude  => 420000000,
	longitude => -730000000,
});

my $rectangle = new ProtobufXS::routeguide::Rectangle({
	lo => $lo_point,
	hi => $hi_point,
});

my $call = $client->ListFeatures(argument => $rectangle);
## an iterator over the server streaming responses
my @features = $call->responses();
foreach my $feature (@features) {
	print STDERR Dumper($feature);
  #printFeature($feature);
}
ok(@features,"no features returned by server");
