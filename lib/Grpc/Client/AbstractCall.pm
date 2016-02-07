package Grpc::Client::AbstractCall;
use strict;
use warnings;

use Grpc::XS::Call;
use Grpc::XS::CallCredentials;
use Grpc::XS::Timeval;

## Create a new Call wrapper object.
##
## @param Channel  $channel     The channel object to communicate on
## @param string   $method      The method to call on the
##                              remote server
## @param callback $deserialize A callback function to deserialize
##                              the response
## @param array    $options     Call options (optional)

sub new {
	my $proto = shift;
	my $channel     = shift;
	my $method      = shift;
	my $deserialize = shift;
	my %options     = @_;
	my $timeout     = $options{timeout};
	my $call_credentials_callback = $options{call_credentials_callback};

	my $deadline;
	if (defined($timeout) && $timeout =~ /^\d+$/) {
	  my $now = Grpc::XS::Timeval::now();
	  my $delta = new Grpc::XS::Timeval($timeout);
	  $deadline = Grpc::XS::Timeval::add($now,$delta);
	} else {
	  $deadline = Grpc::XS::Timeval::infFuture();
	}

	my $call = new Grpc::XS::Call($channel, $method, $deadline);

	my $call_credentials;
	if (defined($call_credentials_callback)) {
		$call_credentials = Grpc::XS::CallCredentials::createFromPlugin(
										$call_credentials_callback);
		$call->setCredentials($call_credentials);
	}

	my $self = {
		'_call'        => $call,
		'_deserialize' => $deserialize,
		'_metadata'    => undef,
	};
	bless $self,$proto;

	return $self;
}

## @return The metadata sent by the server.

sub getMetadata {
	my $self = shift;
	return $self->{_metadata};
}

## @return string The URI of the endpoint.

sub getPeer {
	my $self = shift;
	return $self->{_call}->getPeer();
}

## Cancels the call.

sub cancel {
	my $self = shift;
	return $self->{_call}->cancel();
}

## Deserialize a response value to an object.
##
## @param string $value The binary value to deserialize
##
## @return The deserialized value

sub deserializeResponse {
	my $self  = shift;
	my $value = shift;

	return undef if (!defined($value));
	return $value if (!$self->{_deserialize});
  return $self->{_deserialize}($value);
}

## Set the CallCredentials for the underlying Call.
##
## @param CallCredentials $call_credentials The CallCredentials
##                                          object

sub setCallCredentials {
	my $self = shift;
	my $call_credentials = shift;
	$self->{_call}->setCredentials($call_credentials);
}

1;
