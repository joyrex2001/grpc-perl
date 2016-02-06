package Grpc::Stub::ClientStreamingCall;
use strict;
use warnings;

use base qw(Grpc::Stub::AbstractCall);

use Grpc::Constants;

use constant true  => 1;
use constant false => 0;

## @param array $metadata Metadata to send with the call, if applicable

sub start {
	my $self = shift;
	my $metadata = shift || {};

	$self->{_call}->startBatch({
        GRPC_OP_SEND_INITIAL_METADATA() => $metadata,
	});
}

## Write a single message to the server. This cannot be called after
## writesDone is called.
##
## @param ByteBuffer $data    The data to write
## @param array      $options an array of options, possible keys:
##                            'flags' => a number

sub write {
	my $self  = shift;
	my %param = @_;
	my $data    = $param{data};
	my $options = $param{options}||{};

	my $message = { 'message' => $data->serialize() };
	if (defined($options->{'flags'})) {
		$message->{'flags'} = $options->{'flags'};
	}
	$self->{_call}->startBatch({
	      GRPC_OP_SEND_MESSAGE() => $message,
	});
}

## Wait for the server to respond with data and a status.
##
## @return [response data, status]

sub wait {
	my $self  = shift;

	my $event = $self->{_call}->startBatch({
            GRPC_OP_SEND_CLOSE_FROM_CLIENT() => true,
            GRPC_OP_RECV_INITIAL_METADATA() => true,
            GRPC_OP_RECV_MESSAGE() => true,
            GRPC_OP_RECV_STATUS_ON_CLIENT() => true,
	});

  if (!defined($self->{_metadata})) {
		$self->{_metadata} = $event->{metadata};
  }

	return $self->deserializeResponse($event->{message},$event->{status});
}

1;
