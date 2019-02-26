#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "util.h"

#include <string.h>

#include <grpc/grpc.h>
#include <grpc/byte_buffer_reader.h>
#if !defined(GRPC_VERSION_1_1)
#include <grpc/support/slice.h>
#else
#include <grpc/slice.h>
#endif
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
    gpr_slice_unref(next);
  }
  *out_string = string;
  *out_length = length;
}

void grpc_perl_init_completion_queue() {
#if defined(GRPC_VERSION_1_4)
  grpc_completion_queue_attributes attr;

  attr.version = 1;
  attr.cq_completion_type = GRPC_CQ_PLUCK;
  attr.cq_polling_type = GRPC_CQ_DEFAULT_POLLING;

  completion_queue = grpc_completion_queue_create(grpc_completion_queue_factory_lookup(&attr), &attr, NULL);
#else
  completion_queue = grpc_completion_queue_create(NULL);
#endif
}

void grpc_perl_shutdown_completion_queue() {
  grpc_completion_queue_shutdown(completion_queue);
#if defined(GRPC_VERSION_1_4)
  while (grpc_completion_queue_pluck(completion_queue, NULL,
                                     gpr_inf_future(GPR_CLOCK_REALTIME),
                                     NULL).type != GRPC_QUEUE_SHUTDOWN);
#else
  while (grpc_completion_queue_next(completion_queue,
                                    gpr_inf_future(GPR_CLOCK_REALTIME),
                                    NULL).type != GRPC_QUEUE_SHUTDOWN);
#endif
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
        args->args[args_index].type = GRPC_ARG_INTEGER;
        args->args[args_index].value.integer = SvIV(value);
        args->args[args_index].value.string = NULL;
      } else {
        args->args[args_index].type = GRPC_ARG_STRING;
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
  SV *inner_value;
#if defined(GRPC_VERSION_1_2)
  SV *key;
  HE *temp_fetch;
#else
  SV **temp_fetch;
#endif
  for (i = 0; i < count; i++) {
    elem = &elements[i];
#if defined(GRPC_VERSION_1_2)
    key = sv_2mortal(grpc_slice_to_sv(elem->key));
    temp_fetch = hv_fetch_ent(hash, key, 0, 0);
    inner_value = temp_fetch ? HeVAL(temp_fetch) : NULL;
#else
    temp_fetch = hv_fetch(hash, elem->key, strlen(elem->key), 0);
    inner_value = temp_fetch ? *temp_fetch : NULL;
#endif
    if (inner_value) {
      if(!SvROK(inner_value)) {
        croak("Metadata hash somehow contains wrong types.");
        return NULL;
      }
      av_push( (AV*)SvRV(inner_value), grpc_slice_or_buffer_length_to_sv(elem->value) );
    } else {
      AV* av = newAV();
      av_push( av, grpc_slice_or_buffer_length_to_sv(elem->value) );
#if defined(GRPC_VERSION_1_2)
      hv_store_ent(hash,key,newRV_inc((SV*)av),0);
#else
      hv_store(hash,elem->key,strlen(elem->key),newRV_inc((SV*)av),0);
#endif
    }
  }

  return hash;
}

/* Populates a grpc_metadata_array with the data in a perl hash object.
   Returns TRUE on success and FALSE on failure */
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
    return TRUE;
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
#if defined(GRPC_VERSION_1_2)
        metadata->metadata[metadata->count].key = grpc_slice_from_copied_string(key);
        metadata->metadata[metadata->count].value =
            grpc_slice_from_sv(*inner_value);
#else
        metadata->metadata[metadata->count].key = key;
        metadata->metadata[metadata->count].value =
            strdup(SvPV(*inner_value,metadata->metadata[metadata->count].value_length));
#endif
        metadata->count += 1;
      } else {
        croak("args values must be int or string");
        return FALSE;
      }
    }
  }

  return TRUE;
}

/* Callback function for plugin creds API */
void plugin_get_metadata(void *ptr, grpc_auth_metadata_context context,
                         grpc_credentials_plugin_metadata_cb cb,
                         void *user_data) {
  SV* callback = (SV*)ptr;

  dSP;
  ENTER;

  HV* hash = newHV();
  hv_stores(hash,"service_url", newSVpv(context.service_url,0));
  hv_stores(hash,"method_name", newSVpv(context.method_name,0));

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
  SvREFCNT_dec(state);
}

#if defined(GRPC_VERSION_1_2)
SV *grpc_slice_to_sv(grpc_slice slice) {
  char *slice_str = grpc_slice_to_c_string(slice);
  SV *sv = newSVpv(slice_str, GRPC_SLICE_LENGTH(slice));
  gpr_free(slice_str);
  return sv;
}

grpc_slice grpc_slice_from_sv(SV *sv) {
  STRLEN length;
  const char *buffer = SvPV(sv, length);
  return grpc_slice_from_copied_buffer(buffer, length);
}
#endif
