Grpc::XS::Call
new(const char *class, ... )
  PREINIT:
    CallCTX* ctx = (CallCTX *)malloc( sizeof(CallCTX) );
  CODE:
    // Params:
    //    * channel  - channel object
    //    * method   - string
    //    * deadline - timeval object
    //    * host override - string (optional)
/*
    ctx->wrapped_grpc_call = grpc_channel_create_call(
            channel,NULL, GRPC_PROPAGATE_DEFAULTS, completion_queue, method,
            host_override, deadline, NULL););
            */
    RETVAL = ctx;
  OUTPUT: RETVAL

SV *
startBatch()
  CODE:
  OUTPUT:

SV *
getPeer()
  CODE:
  OUTPUT:

SV *
cancel()
  CODE:
  OUTPUT:

SV *
setCredentials()
  CODE:
  OUTPUT:

void
DESTROY(Grpc::XS::Call self)
  CODE:
    grpc_call_destroy(self->wrapped_grpc_call);
    free(self->wrapped_grpc_call);
    Safefree(self);
