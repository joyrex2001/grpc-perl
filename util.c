#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "util.h"

#include <string.h>

#include <grpc/grpc.h>
#include <grpc/byte_buffer_reader.h>
#include <grpc/support/slice.h>
#include <grpc/support/alloc.h>

grpc_completion_queue *completion_queue;

grpc_byte_buffer *string_to_byte_buffer(char *string, size_t length) {
  gpr_slice slice = gpr_slice_from_copied_buffer(string, length);
  grpc_byte_buffer *buffer = grpc_raw_byte_buffer_create(&slice, 1);
  gpr_slice_unref(slice);
  return buffer;
}

void byte_buffer_to_string(grpc_byte_buffer *buffer, char **out_string,
                           size_t *out_length) {
  if (buffer == NULL) {
    *out_string = NULL;
    *out_length = 0;
    return;
  }
  size_t length = grpc_byte_buffer_length(buffer);
  char *string = calloc(length + 1, sizeof(char));
  size_t offset = 0;
  grpc_byte_buffer_reader reader;
  grpc_byte_buffer_reader_init(&reader, buffer);
  gpr_slice next;
  while (grpc_byte_buffer_reader_next(&reader, &next) != 0) {
    memcpy(string + offset, GPR_SLICE_START_PTR(next), GPR_SLICE_LENGTH(next));
    offset += GPR_SLICE_LENGTH(next);
  }
  *out_string = string;
  *out_length = length;
}

void grpc_perl_init_completion_queue() {
  completion_queue = grpc_completion_queue_create(NULL);
}

void grpc_perl_shutdown_completion_queue() {
  grpc_completion_queue_shutdown(completion_queue);
  while (grpc_completion_queue_next(completion_queue,
                                    gpr_inf_future(GPR_CLOCK_REALTIME),
                                    NULL).type != GRPC_QUEUE_SHUTDOWN);
  grpc_completion_queue_destroy(completion_queue);
}

void perl_grpc_read_args_array(HV *hash, grpc_channel_args *args) {
  // handle hashes
  if (SvTYPE(hash)!=SVt_PVHV) {
    croak("Expected hash for args");
  }

  char* key;
  I32 keylen;
  SV* value;

  // count items in hash
  args->num_args = 0;
  hv_iterinit(hash);
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    args->num_args += 1;
  }

  args->args = calloc(args->num_args, sizeof(grpc_arg));

  int args_index = 0;
  hv_iterinit(hash);
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    if (SvOK(value)) {
      args->args[args_index].key = key;
      if (SvIOK(value)) {
        args->args[args_index].value.integer = SvIV(value);
        args->args[args_index].value.string = NULL;
      } else {
        args->args[args_index].value.string = SvPV_nolen(value);
      }
    } else {
      croak("args values must be int or string");
    }
    args_index++;
  }
}

/* Creates and returns a perl hash object with the data in a
 * grpc_metadata_array. Returns NULL on failure */
HV* grpc_parse_metadata_array(grpc_metadata_array *metadata_array) {
  HV* hash = newHV();
  grpc_metadata *elements = metadata_array->metadata;
  grpc_metadata *elem;

  // hash->{key} = [val]
  int i;
  int count = metadata_array->count;
  for (i = 0; i < count; i++) {
    elem = &elements[i];
    if (hv_exists(hash, elem->key, strlen(elem->key))) {
      SV** inner_value;
      inner_value = hv_fetch(hash, elem->key, strlen(elem->key), 0);
      if(!SvROK(*inner_value)) {
        croak("Metadata hash somehow contains wrong types.");
        return NULL;
      }
      av_push( (AV*)SvRV(*inner_value), newSVpv(elem->value, elem->value_length) );
    } else {
      AV* av = newAV();
      av_push( av, newSVpv(elem->value, elem->value_length) );
      hv_store(hash,elem->key,strlen(elem->key),newRV_inc((SV*)av),0);
    }
  }

  return hash;
}

/* Populates a grpc_metadata_array with the data in a perl hash object.
   Returns true on success and false on failure */
bool create_metadata_array(HV *hash, grpc_metadata_array *metadata) {
  // handle hashes
  if (SvTYPE(hash)!=SVt_PVHV) {
    croak("Expected hash for args");
  }

  int i;
  char* key;
  I32 keylen;
  SV* value;

  grpc_metadata_array_init(metadata);

  // count items in hash
  metadata->capacity = 0;
  hv_iterinit(hash);
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    if (!SvROK(value)) {
      warn("expected array ref in metadata value %s, ignoring...",key);
      continue;
    }
    value = SvRV(value);
    if (SvTYPE(value)!=SVt_PVAV) {
      warn("expected array ref in metadata value %s, ignoring...",key);
      continue;
    }
    metadata->capacity += av_len((AV*)value)+1;
  }

  if(metadata->capacity > 0) {
    metadata->metadata = gpr_malloc(metadata->capacity * sizeof(grpc_metadata));
  } else {
    metadata->metadata = NULL;
    return true;
  }

  metadata->count = 0;
  hv_iterinit(hash);
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    if (!SvROK(value)) {
      //warn("expected array ref in metadata value %s, ignoring...",key);
      continue;
    }
    value = SvRV(value);
    if (SvTYPE(value)!=SVt_PVAV) {
      //warn("expected array ref in metadata value %s, ignoring...",key);
      continue;
    }
    for(i=0;i<av_len((AV*)value)+1;i++) {
      SV** inner_value = av_fetch((AV*)value,i,1);
      if (SvOK(*inner_value)) {
        metadata->metadata[metadata->count].key = key;
        metadata->metadata[metadata->count].value =
            strdup(SvPV(*inner_value,metadata->metadata[metadata->count].value_length));
        metadata->count += 1;
      } else {
        croak("args values must be int or string");
        return false;
      }
    }
  }

  return true;
}

/* Callback function for plugin creds API */
void plugin_get_metadata(void *ptr, grpc_auth_metadata_context context,
                         grpc_credentials_plugin_metadata_cb cb,
                         void *user_data) {
  SV* callback = (SV*)ptr;

  dSP;
  ENTER;

  HV* hash = newHV();
  hv_store(hash,"service_url",strlen("service_url"),
                            newSVpv(context.service_url,0),0);
  hv_store(hash,"method_name",strlen("method_name"),
                            newSVpv(context.method_name,0),0);

  SAVETMPS;
  PUSHMARK(sp);
  XPUSHs(sv_2mortal((SV*)newRV_noinc((SV*)hash)));
  PUTBACK;
  int count = perl_call_sv(callback, G_SCALAR|G_EVAL);
  SPAGAIN;

  if (count!=1) {
    croak("callback returned more than 1 value");
  }

  SV* retval = POPs;
  grpc_metadata_array metadata;
  if (!create_metadata_array((HV*)SvRV(retval), &metadata)) {
    croak("invalid metadata");
    grpc_metadata_array_destroy(&metadata);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  /* TODO: handle error */
  grpc_status_code code = GRPC_STATUS_OK;

  /* Pass control back to core */
  cb(user_data, metadata.metadata, metadata.count, code, NULL);
}

/* Cleanup function for plugin creds API */
void plugin_destroy_state(void *ptr) {
  SV *state = (SV *)ptr;
}
