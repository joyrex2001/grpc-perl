Grpc::XS::Server
new(const char *class, ... )
  PREINIT:
    ServerCTX* ctx = (ServerCTX *)malloc( sizeof(ServerCTX) );
  CODE:
    RETVAL = ctx;
  OUTPUT: RETVAL

SV *
requestCall()
  CODE:
  OUTPUT:

SV *
addHttp2Port()
  CODE:
  OUTPUT:

SV *
addSecureHttp2Port()
  CODE:
  OUTPUT:

SV *
start()
  CODE:
  OUTPUT:

void
DESTROY(Grpc::XS::Server self)
  CODE:
    Safefree(self);
