#!perl -w
use strict;
use Data::Dumper;

use Test::More;
use File::Basename;
use File::Spec;

use ProtobufXS::routeguide;
use ProtobufXS::routeguide::Service::RouteGuide;

plan tests => 2;

my $path = File::Basename::dirname( File::Spec->rel2abs(__FILE__) );

sub readRouteDbFile
{
	my @db;
	# route.txt => longitude,latitude,name
	open(F,"<".$path."/route.txt");
	while(my $l =<F>) {
		$l =~ s/\s$//g;
		my ($long,$lat,$name) = split(/\t/,$l);
		push @db, {
			longitude => $long,
			latitude => $lat,
			name => $name,
		};
	}
	close(F);
	return @db;
}

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

#################
## recordRoute ##
#################

# Run the recordRoute demo. Sends several randomly chosen points from the
# pre-generated feature database with a variable delay in between. Prints
# the statistics when they are sent from the server.

my $client = new ProtobufXS::routeguide::Service::RouteGuide('localhost:10000',
																															credentials => undef );

## start the client streaming call
my $call = $client->RecordRoute();
my @db = readRouteDbFile();
my $num_points_in_db = scalar(@db);
my $num_points = 10;
for (my $i = 0; $i < $num_points; $i++) {
	my $point = new ProtobufXS::routeguide::Point();
	my $index = rand($num_points_in_db);
	my $lat = $db[$index]->{latitude};
	my $long = $db[$index]->{longitude};
	$point->set_latitude($lat);
	$point->set_longitude($long);
	my $feature_name = $db[$index]->{name};
  #print sprintf("Visiting point %f, %f,\n  with feature name: %s\n",
  #              $lat / 10000000, $long / 10000000,
  #              $feature_name ? $feature_name : '<empty>');
	sleep(rand(2));
 	$call->write($point);
}

my $route_summary = $call->wait();
print STDERR Dumper($route_summary->to_hashref());

ok($route_summary,"no valid route summary returned");
ok($route_summary && $route_summary->to_hashref()->{point_count} == $num_points,
		"did not record all points sent to server");
