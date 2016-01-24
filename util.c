#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "util.h"

#include <string.h>

#include <grpc/grpc.h>
#include <grpc/byte_buffer_reader.h>
#include <grpc/support/slice.h>

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

int is_integer(SV* str) {
  STRLEN len;
  const char *s;
  s = SvPV_const(str, len);
  int i=0;
  for (i=0;i<len;i++) {
    if (*s < '0' || *s > '9') {
      return 0;
    }
    s++;
  }
  return 1;
}

void perl_grpc_read_args_array(HV *hash, grpc_channel_args *args) {
  // handle hashes
  if (SvTYPE(hash)!=SVt_PVHV) {
    croak("expected hash for args");
  }

  char* key;
  I32 keylen;
  SV* value;

  // count items in hash
  args->num_args = 0;
  hv_iterinit(hash);
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    args->num_args = args->num_args+1;
  }

  args->args = calloc(args->num_args, sizeof(grpc_arg));

  hv_iterinit(hash);
  int args_index = 0;
  while((value = hv_iternextsv(hash,&key,&keylen))!=NULL) {
    if (SvOK(value)) {
      args->args[args_index].key = key;
      if (is_integer(value)) {
        args->args[args_index].value.integer = SvIV(value);
      } else {
        args->args[args_index].value.string = SvPV_nolen(value);
      }
    } else {
      croak("args values must be int or string");
    }
    args_index++;
  }
}
