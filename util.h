#ifndef GRPC_PERL_UTIL_H
#define GRPC_PERL_UTIL_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <grpc/grpc.h>



grpc_byte_buffer *string_to_byte_buffer(char *string, size_t length);

void byte_buffer_to_string(grpc_byte_buffer *buffer, char **out_string,
                           size_t *out_length);

/* The global completion queue for all operations */
grpc_completion_queue *completion_queue;

/* Initializes the completion queue */
void grpc_perl_init_completion_queue();

/* Shut down the completion queue */
void grpc_perl_shutdown_completion_queue();

void perl_grpc_read_args_array(HV *hash, grpc_channel_args *args);
HV* grpc_parse_metadata_array(grpc_metadata_array *metadata_array);
bool create_metadata_array(HV *hash, grpc_metadata_array *metadata);

#endif
