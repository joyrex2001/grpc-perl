#!perl -w
use strict;
use Data::Dumper;

use Test::More;

use ProtobufXS::routeguide;
use ProtobufXS::routeguide::Service::RouteGuide;

plan tests => 10;

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

###############
## routeChat ##
###############

# Run the routeChat demo. Send some chat messages, and print any chat
# messages that are sent from the server.

my $client = new ProtobufXS::routeguide::Service::RouteGuide('localhost:10000',
																															credentials => undef );

my $call = $client->RouteChat();
my @notes = (
	{
		longitude => 1,
		latitude  => 1,
		message   => 'first message'
	},
	{
		longitude => 1,
		latitude  => 2,
		message   => 'second message'
	},
	{
		longitude => 1,
		latitude  => 1,
		message   => 'third message'
	},
	{
		longitude => 1,
		latitude  => 1,
		message   => 'fourth message'
	},
);

foreach my $n (@notes) {
	my $point = new ProtobufXS::routeguide::Point();
	$point->set_latitude($n->{latitude});
	$point->set_longitude($n->{longitude});

	my $route_note = new ProtobufXS::routeguide::RouteNote();
	$route_note->set_location($point);
	$route_note->set_message($n->{message});
	# send a bunch of messages to the server
	$call->write($route_note);
}
$call->writesDone();

## read from the server until there's no more (with a maximum of 10)
my $count = 10;
while (my $route_note_reply = $call->read()) {
	ok($route_note_reply,"did not receive reply");
	print STDERR Dumper($route_note_reply->to_hashref());
	$count--; last if (!$count);
}
