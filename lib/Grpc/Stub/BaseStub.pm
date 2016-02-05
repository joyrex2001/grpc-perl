package Grpc::Stub::BaseStub;
use strict;
use warnings;

## Base class for generated client stubs. Stub methods are expected to call
## _simpleRequest or _streamRequest and return the result.

use Grpc::XS;
use Grpc::XS::Channel;
use Grpc::XS::Timeval;

use Grpc::Constants;

use Grpc::Stub::UnaryCall;
use Grpc::Stub::ClientStreamingCall;
use Grpc::Stub::ServerStreamingCall;
use Grpc::Stub::BidiStreamingCall;

use constant true  => 1;
use constant false => 0;

## params:
##    - 'hostname': string
##    - 'update_metadata': (optional) a callback function which takes in a
##                         metadata array, and returns an updated metadata array
##    - 'grpc.primary_user_agent': (optional) a user-agent string

sub new {
	my $proto = shift;
	my %param = @_;
	my $hostname           = $param{hostname};  ## TODO: options vs params!
	my $update_metadata    = $param{update_metadata};
	my $primary_user_agent = $param{primary_user_agent};
	my $credentials        = $param{credentials};

	if (defined($primary_user_agent)) {
		$primary_user_agent .= " ";
	} else {
		$primary_user_agent = "";
	}
	$primary_user_agent = "grpc-perl/".($Grpc::XS::VERSION);

	if (!defined($credentials)) {
           die("The 'credentials' key is now ".
               "required. Please see one of the ".
  			   "ChannelCredentials::create methods");
	}

	my $channel = new Grpc::XS::Channel(%param); ## TODO: XS!

	my $self = {
		'_hostname'           => $hostname,
		'_channel'            => undef,
		'_update_metadata'    => $update_metadata,	## a callback function
		'_primary_user_agent' => $primary_user_agent,
		'_credentials'        => $credentials,
		'_channel'            => $channel,
	};
	bless $self,$proto;

	return $self;
}

## return string The URI of the endpoint.

sub getTarget {
	my $self = shift;
	return $self->{_channel}->getTarget();
}

## $try_to_connect bool
## return int The grpc connectivity state

sub getConnectivityState {
	my $self = shift;
	my $try_to_connect = shift||false;
	return $self->{_channel}->getConnectivityState($try_to_connect);
}

## $timeout in microseconds
## return bool true if channel is ready
## dies if channel is in FATAL_ERROR state

sub waitForReady {
	my $self = shift;
	my $timeout = shift;

    my $new_state = $self->getConnectivityState(true);
    if ($self->_checkConnectivityState($new_state)) {
    	return true;
	}

  my $now = Grpc::XS::Timeval::now();
 	my $delta = new Grpc::XS::Timeval($timeout);
  my $deadline = Grpc::XS::Timevall::add($now,$delta);

  while ($self->{_channel}->watchConnectivityState($new_state, $deadline)) {
		## state has changed before deadline
		$new_state = $self->getConnectivityState();
	  if ($self->_checkConnectivityState($new_state)) {
			return true;
	  }
	}

  ## deadline has passed
  $new_state = $self->getConnectivityState();

	return $self->_checkConnectivityState($new_state);
}

sub _checkConnectivityState {
	my $self = shift;
	my $new_state = shift;

	if ($new_state == GRPC_CHANNEL_READY()){
    	return true;
	}
	if ($new_state == GRPC_CHANNEL_FATAL_FAILURE()){
    	die('Failed to connect to server');
	}

	return false;
}

## Close the communication channel associated with this stub.

sub close {
	my $self = shift;
	$self->{_channel}->close();
}

## constructs the auth uri for the jwt.

sub _get_jwt_aud_uri {
	my $self = shift;
	my $method = shift;

	my $service_name;
  if ($method =~ m|^(.*)/[^/]+$|) {
		$service_name = $1;
  } else {
		die("InvalidArgumentException: ".
				"service name must have a slash");
	}

  return 'https://'.$self->{_hostname}.$service_name;
}

sub _validate_and_normalize_metadata {
	my $self = shift;
	my $metadata = shift || {};

  my $metadata_copy = {};
  foreach my $key (keys %{$metadata}) {
		if ($key !~ /^[A-Za-z\d_-]+$/) {
                die("InvalidArgumentException: ".
                    "Metadata keys must be nonempty strings containing only ".
                    "alphanumeric characters, hyphens and underscores");
		}
		$metadata_copy->{lc($key)} = $metadata->{$key};
  }

	return $metadata_copy;
}

## This class is intended to be subclassed by generated code, so
## all functions begin with "_" to avoid name collisions. */

## Call a remote method that takes a single argument and has a
## single output.
##
## @param string $method The name of the method to call
## @param $argument The argument to the method
## @param callable $deserialize A function that deserializes the response
## @param array    $metadata    A metadata map to send to the server
##
## @return SimpleSurfaceActiveCall The active call object

sub _simpleRequest {
	my $self  = shift;
	my %param = @_;
	my $method = $param{method};
	my $argument = $param{argument};
	my $deserialize = $param{deserialize};
	my $metadata = $param{metadata} || {};
	my $options = $param{options} || {};

  my $call = new Grpc::Stub::UnaryCall(
															$self->{_channel},  ## TODO: XS
                            	$method,
                          		$deserialize,
                        			$options);
	my $jwt_aud_uri = $self->_get_jwt_aud_uri($method);

	if (defined($self->{_update_metadata})) {
		$metadata = $self->{_update_metadata}($metadata,$jwt_aud_uri);  ## TODO: PORT
  }
  $metadata = $self->_validate_and_normalize_metadata($metadata);
  $call->start($argument, $metadata, $options);

  return $call;
}

## Call a remote method that takes a stream of arguments and has a single
## output.
##
## @param string $method The name of the method to call
## @param $arguments An array or Traversable of arguments to stream to the
##        server
## @param callable $deserialize A function that deserializes the response
## @param array    $metadata    A metadata map to send to the server
##
## @return ClientStreamingSurfaceActiveCall The active call object

sub _clientStreamRequest {
	my $self = shift;
	my %param = @_;
	my $method = $param{method};
	my $deserialize = $param{deserialize};
	my $metadata = $param{metadata} || {};
	my $options = $param{options} || {};

	my $call = new Grpc::Stub::ClientStreamingCall(
																			$self->{_channel},  ## TODO: XS
                                      $method,
                                      $deserialize,
                                      $options );
  my $jwt_aud_uri = $self->_get_jwt_aud_uri($method);

	if (defined($self->{_update_metadata})) {
		$metadata = $self->{_update_metadata}($metadata,$jwt_aud_uri);  ## TODO: PORT
  }
  $metadata = $self->_validate_and_normalize_metadata($metadata);
  $call->start($metadata, $options);

  return $call;
}

## Call a remote method that takes a single argument and returns a stream of
## responses.
##
## @param string $method The name of the method to call
## @param $argument The argument to the method
## @param callable $deserialize A function that deserializes the responses
## @param array    $metadata    A metadata map to send to the server
##
## @return ServerStreamingSurfaceActiveCall The active call object

sub _serverStreamRequest {
	my $self  = shift;
	my %param = @_;
	my $method = $param{method};
	my $argument = $param{argument};
	my $deserialize = $param{deserialize};
	my $metadata = $param{metadata} || {};
	my $options = $param{options} || {};

  my $call = new Grpc::Stub::ServerStreamingCall(
																			$self->{_channel},  ## TODO: XS
                                      $method,
                                      $deserialize,
                                      $options);
	my $jwt_aud_uri = $self->_get_jwt_aud_uri($method);

	if (defined($self->{_update_metadata})) {
		$metadata = $self->{_update_metadata}($metadata,$jwt_aud_uri);  ## TODO: PORT
  }
  $metadata = $self->_validate_and_normalize_metadata($metadata);
  $call->start($argument, $metadata, $options);

  return $call;
}

## Call a remote method with messages streaming in both directions.
##
## @param string   $method      The name of the method to call
## @param callable $deserialize A function that deserializes the responses
## @param array    $metadata    A metadata map to send to the server
##
## @return BidiStreamingSurfaceActiveCall The active call object

sub _bidiRequest {
	my $self = shift;
	my %param = @_;
	my $method = $param{method};
	my $deserialize = $param{deserialize};
	my $metadata = $param{metadata} || {};
	my $options = $param{options} || {};

	my $call = new Grpc::Stub::BidiStreamingCall(
																		$self->{_channel},  ## TODO: XS
                                  	$method,
                                    $deserialize,
                                    $options );
  my $jwt_aud_uri = $self->_get_jwt_aud_uri($method);

	if (defined($self->{_update_metadata})) {
    $metadata = $self->{_update_metadata}($metadata,$jwt_aud_uri);  ## TODO: PORT
  }
  $metadata = $self->_validate_and_normalize_metadata($metadata);
  $call->start($metadata, $options);

  return $call;
}

1;
