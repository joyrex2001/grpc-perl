Grpc::XS::Call
new(const char *class, ... )
  PREINIT:
    CallCTX* ctx = (CallCTX *)malloc( sizeof(CallCTX) );
    ctx->wrapped = NULL;
  CODE:
    if ( ( items - 1 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    // Params:
    //    * channel       - channel object
    //    * method        - string
    //    * deadline      - timeval object
    //    * host_override - string (optional)

    HV *hash = newHV();
    int i;
    if (items>1) {
      for (i = 1; i < items; i += 2 ) {
          SV *key   = ST(i);
          SV *value = newSVsv( ST( i + 1 ) );
          hv_store_ent( hash, key, value, 0 );
      }
    }

    //ctx->wrapped = grpc_channel_create_call(
    //        channel,NULL, GRPC_PROPAGATE_DEFAULTS, completion_queue, method,
    //        host_override, deadline, NULL););
    //
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
    free(self->wrapped);
    Safefree(self);
