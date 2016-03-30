package Grpc::Client::BidiStreamingCall;
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

## Reads the next value from the server.
##
## @return The next value from the server, or null if there is none

sub read {
	my $self = shift;

  my %batch = ( Grpc::Constants::GRPC_OP_RECV_MESSAGE() => true );
	if (!defined($self->{_metadata})) {
		$batch{Grpc::Constants::GRPC_OP_RECV_INITIAL_METADATA()} = true;
  }

  my $read_event = $self->{_call}->startBatch(%batch);
  if (!defined($self->{_metadata})) {
  	$self->{_metadata} = $read_event->{metadata};
  }

	return $self->deserializeResponse($read_event->{message});
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

	my $message = { 'message' => $data->pack() };
  if (defined($options->{'flags'})) {
    $message->{'flags'} = $options->{'flags'};
  }
  $self->{_call}->startBatch(
            Grpc::Constants::GRPC_OP_SEND_MESSAGE() => $message,
  );
}

## Indicate that no more writes will be sent.

sub writesDone {
	my $self = shift;
	$self->{_call}->startBatch(
            Grpc::Constants::GRPC_OP_SEND_CLOSE_FROM_CLIENT() => true,
	);
}

## Wait for the server to send the status, and return it.
##
## @return object The status object, with integer $code, string $details,
##                and array $metadata members

sub getStatus {
	my $self = shift;
	my $status_event = $self->{_call}->startBatch(
            Grpc::Constants::GRPC_OP_RECV_STATUS_ON_CLIENT() => true,
	);

	return $status_event->{status};
}

1;
