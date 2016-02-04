Grpc::XS::Call
new(const char *class,  Grpc::XS::Channel channel,  \
    const char* method, Grpc::XS::Timeval deadline, ... )
  PREINIT:
    CallCTX* ctx = (CallCTX *)malloc( sizeof(CallCTX) );
    ctx->wrapped = NULL;
  CODE:

    // Params:
    //    * channel       - channel object
    //    * method        - string
    //    * deadline      - timeval object
    //    * host_override - string (optional)

    if ( items > 4 ) {
      croak("Too many variables for constructor Grpc::XS::Call");
    }

    const char* host_override = NULL;
    if ( items == 4) {
      host_override = SvPV_nolen(ST(3));
    }

    ctx->wrapped = grpc_channel_create_call(
              channel->wrapped,NULL, GRPC_PROPAGATE_DEFAULTS, completion_queue,
              method, host_override, deadline->wrapped, NULL);

    RETVAL = ctx;
  OUTPUT: RETVAL

HV *
startBatch(const char *class, ...)
  CODE:
    if ( items > 1 && ( items - 1 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    /**
     * Start a batch of RPC actions.
     * @param array batch Array of actions to take
     * @return object Object with results of all actions
    */

    HV *result = newHV();

    char *status_details = NULL;

    grpc_op ops[8];
    size_t op_num = 0;

    grpc_metadata_array metadata;
    grpc_metadata_array trailing_metadata;
    grpc_metadata_array recv_metadata;
    grpc_metadata_array recv_trailing_metadata;

    grpc_metadata_array_init(&metadata);
    grpc_metadata_array_init(&trailing_metadata);
    grpc_metadata_array_init(&recv_metadata);
    grpc_metadata_array_init(&recv_trailing_metadata);

    int i;
    HV *hash = newHV();
    if (items>1) {
      for (i = 1; i < items; i += 2 ) {
        SV *key = ST(i);
        SV *value = newSVsv(ST(i+1));

        if (!SvOK(key)) {
          warn("Expected an int for message flags");
          goto cleanup;
        }

        switch(SvIV(key)) {
          case GRPC_OP_SEND_INITIAL_METADATA:
            if (SvTYPE(value)!=SVt_PVHV) {
              warn("Expected a hash for GRPC_OP_SEND_INITIAL_METADATA");
              goto cleanup;
            }
            if (!create_metadata_array(SvSTASH(value), &metadata)) {
              warn("Bad metadata value given");
              goto cleanup;
            }
            ops[op_num].data.send_initial_metadata.count =
                 metadata.count;
            ops[op_num].data.send_initial_metadata.metadata =
                 metadata.metadata;
            break;
          case GRPC_OP_SEND_MESSAGE:
            // check if value is hash
            if (SvTYPE(value)!=SVt_PVHV) {
              warn("Expected a hash for send message");
              goto cleanup;
            }
            // ops[op_num].flags = hash->{flags} & GRPC_WRITE_USED_MASK;// int
            SV **flags;
            if (hv_exists(SvSTASH(value), "flags", 5)) {
              flags = hv_fetch(SvSTASH(value), "flags", 5, 0);
            } else {
              warn("Missing message flags");
              goto cleanup;
            }
            if (!SvIOK(*flags)) {
              warn("Expected an int for message flags");
              goto cleanup;
            }
            ops[op_num].flags = SvIV(*flags) & GRPC_WRITE_USED_MASK;
            // ops[op_num].data.send_message = hash->{message}; // string
            SV **message;
            if (hv_exists(SvSTASH(value), "message", 7)) {
              message = hv_fetch(SvSTASH(value), "message", 7, 0);
            } else {
              warn("Missing send message");
              goto cleanup;
            }
            if (!SvOK(*flags)) {
              warn("Expected an string for send message");
              goto cleanup;
            }
            STRLEN len;
            char *msg = SvPV(*message,len);
            ops[op_num].data.send_message = string_to_byte_buffer(msg,len);
            break;
          case GRPC_OP_SEND_CLOSE_FROM_CLIENT:
            break;


        }

      }
    }

  cleanup:
    grpc_metadata_array_destroy(&metadata);
    grpc_metadata_array_destroy(&trailing_metadata);
    grpc_metadata_array_destroy(&recv_metadata);
    grpc_metadata_array_destroy(&recv_trailing_metadata);
    if (status_details != NULL) {
      gpr_free(status_details);
    }

    RETVAL = result;
  OUTPUT: RETVAL

const char*
getPeer(Grpc::XS::Call self)
  CODE:
    RETVAL = grpc_call_get_peer(self->wrapped);
  OUTPUT: RETVAL

void
cancel(Grpc::XS::Call self)
  CODE:
    grpc_call_cancel(self->wrapped, NULL);
  OUTPUT:

int
setCredentials(Grpc::XS::Call self, Grpc::XS::CallCredentials creds)
  CODE:
    int error = GRPC_CALL_ERROR;
    error = grpc_call_set_credentials(self->wrapped, creds->wrapped);
    RETVAL = error;
  OUTPUT: RETVAL

void
DESTROY(Grpc::XS::Call self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_call_destroy(self->wrapped);
    }
    Safefree(self);
