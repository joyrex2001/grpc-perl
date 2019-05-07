#ifndef GRPC_PERL_UTIL_H
#define GRPC_PERL_UTIL_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <grpc/grpc.h>
#include <grpc/grpc_security.h>
#if defined(GRPC_VERSION_1_1)
#include <grpc/slice.h>
#endif

grpc_byte_buffer *string_to_byte_buffer(char *string, size_t length);

void byte_buffer_to_string(grpc_byte_buffer *buffer, char **out_string,
                           size_t *out_length);

void grpc_perl_init();
void grpc_perl_destroy();

/* The global completion queue for all operations */
extern grpc_completion_queue *completion_queue;

/* Initializes the completion queue */
void grpc_perl_init_completion_queue();

/* Shut down the completion queue */
void grpc_perl_shutdown_completion_queue();

void perl_grpc_read_args_array(HV *hash, grpc_channel_args *args);
HV* grpc_parse_metadata_array(grpc_metadata_array *metadata_array);
bool create_metadata_array(HV *hash, grpc_metadata_array *metadata);

#if defined(GRPC_VERSION_1_7)
int plugin_get_metadata(void *ptr, grpc_auth_metadata_context context,
                        grpc_credentials_plugin_metadata_cb cb,
                        void *user_data,
                        grpc_metadata creds_md[GRPC_METADATA_CREDENTIALS_PLUGIN_SYNC_MAX],
                        size_t *num_creds_md, grpc_status_code *status,
                        const char **error_details);
#else
void plugin_get_metadata(void *ptr, grpc_auth_metadata_context context,
                         grpc_credentials_plugin_metadata_cb cb,
                         void *user_data);
#endif

void plugin_destroy_state(void *ptr);

#if defined(GRPC_VERSION_1_2)
SV *grpc_slice_to_sv(grpc_slice slice);
grpc_slice grpc_slice_from_sv(SV *sv);
#endif

#if defined(GRPC_VERSION_1_2)
#define grpc_slice_or_string_to_sv(slice) grpc_slice_to_sv((slice))
#define grpc_slice_or_buffer_length_to_sv(slice) grpc_slice_to_sv((slice))
#else
#define grpc_slice_or_string_to_sv(string) newSVpvn((string), strlen(string))
#define grpc_slice_or_buffer_length_to_sv(buffer) newSVpvn((buffer), (buffer##_length))
#endif

#endif
