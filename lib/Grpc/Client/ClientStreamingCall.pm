package Grpc::Client::ClientStreamingCall;
use strict;
use warnings;

use base qw(Grpc::Client::AbstractCall);

use Grpc::Constants;

use constant true  => 1;
use constant false => 0;

## @param array $metadata Metadata to send with the call, if applicable

sub start {
	my $self = shift;
	my $metadata = shift || {};

	$self->{_call}->startBatch(
        Grpc::Constants::GRPC_OP_SEND_INITIAL_METADATA() => $metadata,
	);
}

## Write a single message to the server. This cannot be called after
## writesDone is called.
##
## @param ByteBuffer $data    The data to write
## @param array      $options an array of options, possible keys:
##                            'flags' => a number

sub write {
	my $self  = shift;
	my $data    = shift;
	my $options = shift||{};

	my $message = { 'message' => $self->serializeRequest($data) };
	if (defined($options->{'flags'})) {
		$message->{'flags'} = $options->{'flags'};
	}
	$self->{_call}->startBatch(
	      Grpc::Constants::GRPC_OP_SEND_MESSAGE() => $message,
	);
}

## Wait for the server to respond with data and a status.
##
## @return (response data, status)

sub wait {
	my $self  = shift;

	my $event = $self->{_call}->startBatch(
            Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => true,
            Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA() => true,
            Grpc::Constants::GRPC_OP_RECV_MESSAGE() => true,
            Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => true,
	);

  if (!defined($self->{_metadata})) {
		$self->{_metadata} = $event->{metadata};
  }

    return wantarray
    ? ($self->deserializeResponse($event->{message}), $event->{status})
    : $self->deserializeResponse($event->{message});
}

1;
