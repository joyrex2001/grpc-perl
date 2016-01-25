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

SV *
startBatch()
  CODE:
  OUTPUT:

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
