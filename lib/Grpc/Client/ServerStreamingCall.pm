package Grpc::Client::ServerStreamingCall;
use strict;
use warnings;

use base qw(Grpc::Client::AbstractCall);

use Grpc::Constants;

use constant true  => 1;
use constant false => 0;

## Start the call.
##
## @param $data The data to send
## @param array $metadata Metadata to send with the call, if applicable
## @param array $options  an array of options, possible keys:
##                        'flags' => a number

sub start{
	my $self  = shift;
	my %param = @_;
	my $data    = $param{data};
	my $metadata= $param{metadata};
	my $options = $param{options}||{};

	my $message = { 'message' => $data->serialize() };
	if (defined($options->{'flags'})) {
		$message->{'flags'} = $options->{'flags'};
	}
	my $event = $self->{_call}->startBatch({
	        GRPC_OP_SEND_INITIAL_METADATA() => $metadata,
	        GRPC_OP_RECV_INITIAL_METADATA() => true,
	        GRPC_OP_SEND_MESSAGE() => $message,
	        GRPC_OP_SEND_CLOSE_FROM_CLIENT() => true,
	});

	$self->{_metadata} = $event->{metadata};
}

## @return An array of response values

sub responses {
	my $self = shift;

	my @responses;
	my $response = $self->{_call}->startBatch({
								GRPC_OP_RECV_MESSAGE() => true,
	})->{message};
	while (defined($response)) {
		push @responses,$self->deserializeResponse($response);
		$response = $self->{_call}->startBatch({
                GRPC_OP_RECV_MESSAGE() => true,
    })->{message};
  }
	return @responses;
}

## Wait for the server to send the status, and return it.
##
## @return object The status object, with integer $code, string $details,
##                and array $metadata members

sub getStatus {
	my $self = shift;
	my $status_event = $self->{_call}->startBatch({
            GRPC_OP_RECV_STATUS_ON_CLIENT() => true,
	});

	return $status_event->{status};
}
1;
