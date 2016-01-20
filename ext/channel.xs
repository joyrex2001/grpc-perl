Grpc::XS::Channel
new(const char *class, ... )
  PREINIT:
    ChannelCTX* ctx = (ChannelCTX *)malloc( sizeof(ChannelCTX) );
  CODE:
    // string (channel)
    // hash->{credentials} - credentials object
    RETVAL = ctx;
  OUTPUT: RETVAL

SV *
getTarget()
  CODE:
  OUTPUT:

SV *
getConnectivityState()
  CODE:
  OUTPUT:

SV *
watchConnectivityState()
  CODE:
  OUTPUT:

SV *
close()
  CODE:
  OUTPUT:

void
DESTROY(Grpc::XS::Channel self)
  CODE:
    free(self->wrapped_grpc_channel);
    Safefree(self);
