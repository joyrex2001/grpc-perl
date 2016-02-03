package Grpc::Stub::ServerStreamingCall;
use strict;
use warnings;

use base qw(Grpc::Stub::AbstractCall);

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
            OP_SEND_INITIAL_METADATA => $metadata,
            OP_RECV_INITIAL_METADATA => true,
            OP_SEND_MESSAGE => $message,
            OP_SEND_CLOSE_FROM_CLIENT => true,
    });

   	$self->{_metadata} = $event->{metadata};
}

## @return An iterator of response values

sub responses {
	my $self = shift;

	my $response = $self->{_call}->startBatch({
            OP_RECV_MESSAGE => true,
	})->{message};
    while (defined($response)) {
		## yield $self->deserializeResponse($response); ## TODO: PORT
		$response = $self->{_call}->startBatch({
                OP_RECV_MESSAGE => true,
        })->{message};
    }
 }

## Wait for the server to send the status, and return it.
##
## @return object The status object, with integer $code, string $details,
##                and array $metadata members

sub getStatus {
	my $self = shift;
	my $status_event = $self->{_call}->startBatch({
            OP_RECV_STATUS_ON_CLIENT => true,
	});

	return $status_event->{status};
}
1;
