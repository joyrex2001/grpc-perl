package Grpc::Stub::AbstractCall;
use strict;
use warnings;

## Create a new Call wrapper object.
##
## @param Channel  $channel     The channel to communicate on
## @param string   $method      The method to call on the
##                              remote server
## @param callback $deserialize A callback function to deserialize
##                              the response
## @param array    $options     Call options (optional)

sub new {
	my $proto = shift;
	my %param = @_;
	my $channel     = $param{hostname}; ## TODO: options vs params!
	my $method      = $param{method};
	my $deserialize = $param{deserialize};
	my $timeout     = $param{timeout};
	my $call_credentials_callback = $param{call_credentials_callback};

	my $deadline;
	if (defined($timeout) && $timeout =~ /^\d+$/) {
		    my $now = Timeval::now(); ## TODO: port
            my $delta = new Timeval($timeout);
            $deadline = $now->add($delta);
    } else {
            $deadline = Timeval::infFuture();
	}

	my $call = new Call($channel, $method, $deadline);

	my $call_credentials;
	if (defined($call_credentials_callback)) {
		$call_credentials = CallCredentials::createFromPlugin(
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
	my $self = shift;
	my $value = shift;

    if (!defined($value)) {
        return undef;
    }

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
