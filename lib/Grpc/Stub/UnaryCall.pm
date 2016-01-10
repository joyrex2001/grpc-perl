package Grpc::Stub::UnaryCall;
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

## Wait for the server to respond with data and a status.
##
## @return [response data, status]

sub wait {
	my $self  = shift;

	my $event = $self->{_call}->startBatch({
            OP_RECV_MESSAGE => true,
            OP_RECV_STATUS_ON_CLIENT => true,
   	});

	return $self->deserializeResponse($event->{message},$event->{status});
}

1;
